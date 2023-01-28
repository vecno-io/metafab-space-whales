package actor

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"math/rand"
	"net/http"
	"os"
	"time"

	"github.com/heroiclabs/nakama-common/runtime"
	"github.com/vecno-io/metafab-space-whales/server/meta"
	"github.com/vecno-io/metafab-space-whales/server/sector"
)

/*
 * Due to the nature of actor tokens three steps are needed to register them.
 *  1) The actor id is reserved in the system and linked to the user account.
 *  2) The actor data is collected and used to create the token on-chain.
 *  3) The user claims the actor by minting it into the accounts wallet.
 */

type Stats struct {
	Agility  uint32 `json:"agility"`
	Strength uint32 `json:"strength"`
	Vitality uint32 `json:"vitality"`
}

type Skills struct {
	Combat      uint32 `json:"combat"`
	Industry    uint32 `json:"industry"`
	Exploration uint32 `json:"exploration"`
}

type Attribs struct {
	Back   string `json:"back"`
	Face   string `json:"face"`
	Shape  string `json:"shape"`
	Props  string `json:"props"`
	Color  string `json:"color"`
}

type MintRequest struct {
	Id string `json:"id"`
}

type CreateRequest struct {
	Id      string  `json:"id"`
	Name    string  `json:"name"`
	Stats   Stats   `json:"stats"`
	Skills  Skills  `json:"skills"`
	Attribs Attribs `json:"attribs"`
}

// Reserve a new actor id with an empty sector and links it to the users account.
func ReserveRpc(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	// Requires a valid metafab account, available mint slots for a new actor
	user_id, account, err := meta.GetAccountData(ctx, logger, nk)
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
		}).Error("failed to get acount data")
		return "{}", errors.New("failed to load account data")
	}
	player, err := meta.GetPlayerData(logger, account.MetafabId)
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": account.MetafabId,
		}).Error("failed to get player data")
		return "{}", errors.New("failed to load player data")
	}
	if player.ProtectedData.ActorMinted >= player.ProtectedData.ActorMints {
		return "{}", errors.New("player has no free game slots")
	}
	count, err := _cnt_reserved_actors_for(ctx, nk, user_id)
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": account.MetafabId,
		}).Error("count reserved actors")
		return "{}", errors.New("read reserved slots failed")
	}
	if count < 0 || uint16(count) >= player.ProtectedData.ActorMints {
		return "{}", errors.New("player has no reservation slots")
	}
	// Reserve new player ID for the account based on the players request
	// Note: At this point in time no refrence system is available and
	// all actors have their origin set to 001:XXX:000:000, paylaod is 
	// set too hold the requested origin and region for gen2 actors.
	// Where XXX is a random region type, gen2 defines region type.
	rng := rand.New(rand.NewSource(time.Now().UnixNano()))
	sec, err := sector.Reserve(ctx, logger, nk, account, uint8(rng.Int31n(255)), sector.Origin(0))
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": account.MetafabId,
		}).Error("reserve sector")
		return "{}", errors.New("reserve sector failed")
	}
	if sector.Id(0) == sec {
		logger.WithFields(map[string]interface{}{
			"msg": "invalid sector id",
			"user": user_id,
			"player": account.MetafabId,
		}).Error("reserve sector")
		return "{}", errors.New("reserve sector failed")
	}
	idx, ver, err := _read_actor_token_index(ctx, logger, nk, sec.Key())
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": account.MetafabId,
		}).Error("read token index")
		return "{}", errors.New("read token index failed")
	}
	// Update the id, then try to encode before saving the change
	idx.Value -= 1
	result, err := idx.MarshalJSON()
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": account.MetafabId,
		}).Error("marshal reserved id")
		return "{}", errors.New("marshal reserved id failed")
	}
	if err := _write_actor_token_index(ctx, logger, nk, idx, ver); err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": account.MetafabId,
		}).Error("write token index")
		return "{}", errors.New("write token index failed")
	}
	// Store the id reservation links onto the users account
	ver, err = _write_reserved_actor_for_id(ctx, logger, nk, user_id, idx.Key(), "*", account.MetafabId)
	if nil != err {
		return "{}", errors.New("failed to reserve actor link (id)")
	}
	// Update the player account to reflect the change
	player.ProtectedData.ActorMinted += 1
	if err := meta.SetPlayerData(logger, account.MetafabId, player); nil != err {
		_ = _delete_reserved_actor_for_id(ctx, logger, nk, idx.Key(), ver)
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": account.MetafabId,
		}).Error("failed to get player data")
		return "{}", errors.New("failed to load player data")
	}
	return string(result), nil
}

// Create creates a new actor token and sets the required data and structure.
func CreateRpc(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	// Requires a valid metafab account, available mint slots for a new actor
	user_id, account, err := meta.GetAccountData(ctx, logger, nk)
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
		}).Error("failed to get acount data")
		return "{}", errors.New("failed to load account data")
	}
	// Requires Metafab private keys and collection info
	game_secret := os.Getenv("METAFAB_GAME_SECRET_KEY")
	if len(game_secret) == 0 {
		logger.Error("bad server: invalid secret key")
		return "{}", runtime.NewError("bad server configuration", 500)
	}
	game_password := os.Getenv("METAFAB_GAME_PASS")
	if len(game_password) == 0 {
		logger.Error("bad server: invalid password key")
		return "{}", runtime.NewError("bad server configuration", 500)
	}
	actor_collection := os.Getenv("METAFAB_COLLECTION_ACTORS")
	if len(actor_collection) == 0 {
		logger.Error("bad server: invalid whales collection key")
		return "{}", runtime.NewError("bad server configuration", 500)
	}
	image_url_actor := os.Getenv("URL_IMAGE_ACTOR")
	if len(game_secret) == 0 {
		logger.Error("bad server: invalid secret key")
		return "{}", runtime.NewError("bad server configuration", 500)
	}
	extern_url_actor := os.Getenv("URL_EXTERN_ACTORS")
	if len(game_password) == 0 {
		logger.Error("bad server: invalid password key")
		return "{}", runtime.NewError("bad server configuration", 500)
	}
	var request CreateRequest 
	if err := json.Unmarshal([]byte(payload), &request); err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"code": 500,
			"user": user_id,
			"data": payload,
		}).Error("unmarshal create request")
		return "{}", runtime.NewError("invalid request", 500)
	}
	var id Id
	if err := id.FromKey(request.Id); err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"code": 500,
			"user": user_id,
			"data": payload,
		}).Error("decode create request id")
		return "{}", runtime.NewError("invalid request", 500)
	}
	// Validate the request id and check if this is the first create call
	pid, _, err := _read_reserved_actor_for_id(ctx, logger, nk, user_id, request.Id)
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"code": 401,
			"user": user_id,
			"data": payload,
		}).Error("unauthorized request")
		return "{}", runtime.NewError("unauthorized request", 401)
	}
	if pid != account.MetafabId {
		logger.WithFields(map[string]interface{}{
			"msg": "invalid actor id",
			"code": 401,
			"user": user_id,
			"data": payload,
		}).Error("unauthorized request")
		return "{}", runtime.NewError("unauthorized request", 401)
	}
	tag, ver, err := _read_actor_tag_index(ctx, logger, nk, request.Name)
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"code": 500,
			"user": user_id,
			"data": payload,
		}).Error("read actor tag")
		return "{}", runtime.NewError("internal error", 500)
	}
	tag.Value -= 1
	result, err := tag.MarshalJSON()
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": account.MetafabId,
		}).Error("marshal actor tag")
		return "{}", errors.New("marshal actor tag failed")
	}
	if err := _write_actor_tag_index(ctx, logger, nk, tag, ver); err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"tag": tag,
			"code": 500,
			"user": user_id,
			"data": payload,
		}).Error("write actor tag")
		return "{}", runtime.NewError("invalid name tag", 500)
	}
	// Create the actor item in to collection, also verifies that the actor has not been created before
	_, err = _create_actor_item(ctx, logger, nk, user_id, game_secret, game_password, actor_collection, id, &Meta{
		Id: id.Number(),
		Name: tag.Key(),
		Description: "An actor in this space.", 
		ImageUrl: fmt.Sprintf("%s/%s", image_url_actor, request.Id),
		ExternalUrl: fmt.Sprintf("%s/%s", extern_url_actor, request.Id),
		Data: Data{
			Stats: []Stat{{
					Type: "Agility",
					Value: request.Stats.Agility,
				},{
					Type: "Strength",
					Value: request.Stats.Strength,
				},{
					Type: "Vitality",
					Value: request.Stats.Vitality,
				}}, 
			Skills: []Skill{{
					Type: "Combat",
					Value: request.Skills.Combat,
				},{
					Type: "Industry",
					Value: request.Skills.Industry,
				},{
					Type: "Exploration",
					Value: request.Skills.Exploration,
				}},
		},
		Attributes: []Trait{{
				Type: "Base",
				Value: request.Attribs.Back,
			},{
				Type: "Face",
				Value: request.Attribs.Face,
			},{
				Type: "Shape",
				Value: request.Attribs.Shape,
			},{
				Type: "Props",
				Value: request.Attribs.Props,
			},{
				Type: "Color",
				Value: request.Attribs.Color,
			},{
				Type: "Origin",
				Value: id.Sector.Kind(),
			},{
				Type: "Generation",
				Value: id.Sector.Version(),
			},
		},
	})
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"data": payload,
		}).Error("create actor item")
		return "{}", runtime.NewError("create actor item failed", 500)
	}
	return string(result), nil
}

// Mint mints the token on to the users account and finalizes the actors registration.
func MintRpc(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	// Requires a valid metafab account, available mint slots for a new actor
	user_id, account, err := meta.GetAccountData(ctx, logger, nk)
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
		}).Error("failed to get acount data")
		return "{}", errors.New("failed to load account data")
	}
	// Requires Metafab private keys and collection info
	game_secret := os.Getenv("METAFAB_GAME_SECRET_KEY")
	if len(game_secret) == 0 {
		logger.Error("bad server: invalid secret key")
		return "{}", runtime.NewError("bad server configuration", 500)
	}
	game_password := os.Getenv("METAFAB_GAME_PASS")
	if len(game_password) == 0 {
		logger.Error("bad server: invalid password key")
		return "{}", runtime.NewError("bad server configuration", 500)
	}
	actor_collection := os.Getenv("METAFAB_COLLECTION_ACTORS")
	if len(actor_collection) == 0 {
		logger.Error("bad server: invalid whales collection key")
		return "{}", runtime.NewError("bad server configuration", 500)
	}
	// Read and setup required data
	var request MintRequest
	if err := json.Unmarshal([]byte(payload), &request); err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"code": 500,
			"user": user_id,
			"data": payload,
		}).Error("unmarshal mint request")
		return "{}", runtime.NewError("invalid request", 500)
	}
	var id Id
	if err := id.FromKey(request.Id); err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"code": 500,
			"user": user_id,
			"data": payload,
		}).Error("decode mint request id")
		return "{}", runtime.NewError("invalid request", 500)
	}
	// Verify that the actor id is not minted and created by the user
	chk, _, _, err := _read_actor_meta(ctx, logger, nk, user_id, request.Id);
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"code": 401,
			"user": user_id,
			"data": payload,
			}).Error("invalid id (error)")
		return "{}", runtime.NewError("invalid id", 401)
	}
	if chk == nil {
		logger.WithFields(map[string]interface{}{
			"code": 401,
			"user": user_id,
			"data": payload,
			}).Error("invalid id (check)")
		return "{}", runtime.NewError("invalid id", 401)
	}
	result, err := _mint_actor_item(ctx, logger, nk, user_id, game_secret, game_password, actor_collection, id, account)
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"data": payload,
		}).Error("mint actor item")
		return "{}", runtime.NewError("mint actor item failed", 500)
	}
	return result, nil
}


func _create_actor_item(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, user_id string, secret string, pass string, collection string, id Id, metadata *Meta) (string, error) {
	make_url := fmt.Sprintf("https://api.trymetafab.com/v1/collections/%s/items", collection)
	payload, err := json.Marshal(metadata)
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"actor": metadata.Id,
		}).Error("marshal actor data")
		return "{}", errors.New("marshal actor data failed")
	}
	// Verify that the actor has not been created
	cnt, err := _has_actor_meta(ctx, nk, metadata.Id)
	if cnt < 0 || err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"actor": id.Key(),
		}).Error("actor count")
		return "{}", errors.New("actor count failed")
	}
	if cnt > 0 {
		return "{}", errors.New("actor already created")
	}
	ver, err := _write_actor_meta(ctx, logger, nk, user_id, "*", id.Key(), metadata)
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"actor": id.Key(),
		}).Error("write actor metadata")
		return "{}", errors.New("save actor metadata failed")
	}
	// Create the new actor item and register it on-chain
	client := meta.CreateHttpClient()
	req, err := http.NewRequest("POST", make_url, bytes.NewReader(payload))
	if err != nil { 
		_ = _delete_actor_meta(ctx, logger, nk, user_id, metadata.Id, ver)
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"actor": id.Key(),
		}).Error("new http request")
		return "{}", errors.New("invalid create request")
	}
	req.Header.Add("accept", "application/json")
	req.Header.Add("content-type", "application/json")
	req.Header.Add("X-Password", pass)
	req.Header.Add("X-Authorization", secret)
	res, err := client.Do(req)
	if err != nil { 
		_ = _delete_actor_meta(ctx, logger, nk, user_id, metadata.Id, ver)
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"actor": id.Key(),
		}).Error("send http request")
		return "{}", errors.New("sending create request failed")
	}
	defer res.Body.Close()
	body, _ := io.ReadAll(res.Body)
	if res.StatusCode != 200 {
		_ = _delete_actor_meta(ctx, logger, nk, user_id, metadata.Id, ver)
		logger.WithFields(map[string]interface{}{
			"user": user_id,
			"body": body,
			"actor": id.Number(),
			"code": res.StatusCode,
			"status": res.Status,
		}).Error("create actor result")
		return "{}", errors.New("create transaction failed")
	}
	// Save the transaction info and finalize
	if _, err := meta.SaveTransaction(ctx, logger, nk, user_id, string(body)); err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"body": body,
			"user": user_id,
			"actor": id.Key(),
		}).Error("save create transaction")
		//Note: Creation on-chain happened, internal state error
		return string(body), errors.New("save create transaction failed")
	}
	return string(body), nil
}

func _mint_actor_item(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, user_id string, secret string, pass string, collection string, id Id, account *meta.AccountData) (string, error) {
	mint_url := fmt.Sprintf("https://api.trymetafab.com/v1/collections/%s/items/%s/mints", collection, id.Number())
	payload, err := json.Marshal(map[string]interface{}{
		"quantity": 1,
		"walletId": account.WalletId,
	})
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"actor": id.Key(),
			"player": account.MetafabId,
		}).Error("marshal mint data")
		return "{}", errors.New("marshal mint data failed")
	}
	// Verify that the actor has not been minted
	cnt, err := _has_minted_actor_for_id(ctx, nk, id.Key())
	if cnt < 0 || err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"actor": id.Key(),
		}).Error("actor mint count")
		return "{}", errors.New("actor mint count failed")
	}
	if cnt > 0 {
		return "{}", errors.New("actor already minted")
	}
	ver, err := _write_minted_actor_for_id(ctx, logger, nk, user_id, id.Key(), "*", account.MetafabId)
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"actor": id.Key(),
		}).Error("write actor mint id")
		return "{}", errors.New("save actor mint id failed")
	}
	// Mint the actor item into the players account
	client := meta.CreateHttpClient()
	req, err := http.NewRequest("POST", mint_url, bytes.NewReader(payload))
	if err != nil { 
		_ = _delete_minted_actor_for_id(ctx, logger, nk, id.Key(), ver)
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"actor": id.Key(),
		}).Error("new http request")
		return "{}", errors.New("invalid mint request")
	}
	req.Header.Add("accept", "application/json")
	req.Header.Add("content-type", "application/json")
	req.Header.Add("X-Password", pass)
	req.Header.Add("X-Authorization", secret)
	res, err := client.Do(req)
	if err != nil { 
		_ = _delete_minted_actor_for_id(ctx, logger, nk, id.Key(), ver)
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"actor": id.Key(),
		}).Error("send http request")
		return "{}", errors.New("sending mint request failed")
	}
	defer res.Body.Close()
	body, _ := io.ReadAll(res.Body)
	if res.StatusCode != 200 {
		_ = _delete_minted_actor_for_id(ctx, logger, nk, id.Key(), ver)
		logger.WithFields(map[string]interface{}{
			"user": user_id,
			"actor": id.Key(),
			"code": res.StatusCode,
			"status": res.Status,
		}).Error("mint actor result")
		return "{}", errors.New("mint transaction failed")
	}
	// Save the transaction info and finalize
	if _, err := meta.SaveTransaction(ctx, logger, nk, user_id, string(body)); err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"body": body,
			"user": user_id,
			"actor": id.Key(),
		}).Error("save minted transaction")
		//Note: Creation on-chain happened, internal state error
		return string(body), errors.New("save minted transaction failed")
	}
	return string(body), nil
}


func _has_minted_actor_for_id(ctx context.Context, nk runtime.NakamaModule, key string) (int, error) {
	records, err:= nk.StorageRead(ctx, []*runtime.StorageRead {{
		Collection: STORAGE_ACTOR_MINTED_ID,
		Key: key,
	}})
	if err != nil {
		return -1, errors.New("read storage minted actor id failed")
	}
	return len(records), nil
}

func _write_minted_actor_for_id(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, user_id string, key string, version string, account_id string) (string, error) {
	data, err := json.Marshal(meta.AccountId {
		Value: account_id,
	})
	if err != nil {
		logger.WithField("err", err).Error("json marshal account id")
		return "", errors.New("failed encode account id")
	}
	ack, err := nk.StorageWrite(ctx, []*runtime.StorageWrite {{
		Collection: STORAGE_ACTOR_MINTED_ID,
		UserID: user_id,
		Key: key,
		Value: string(data),
		Version: version,
		PermissionRead: 2,
		PermissionWrite: 0,
	}})
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": key,
			"data": data,
		}).Error("storage write minted actor id")
		return "", errors.New("storage write minted actor id failed")
	}
	if len(ack) != 1 {
		logger.WithFields(map[string]interface{}{
			"msg": "invalid ack",
			"len": len(ack),
			"key": key,
			"data": data,
		}).Error("ack storage write minted actor id")
		return "", errors.New("ack storage write minted actor id failed")
	}
	return ack[0].Version, nil
}

func _delete_minted_actor_for_id(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, key string, version string) error {
	err := nk.StorageDelete(ctx, []*runtime.StorageDelete {{
		Collection: STORAGE_ACTOR_MINTED_ID,
		Version: version,
		Key: key,
	}})
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": key,
		}).Error("delete minted actor id")
		return errors.New("delete minted actor id")
	}
	return nil
}


func _cnt_reserved_actors_for(ctx context.Context, nk runtime.NakamaModule, user_id string) (int, error) {
	records, _, err:= nk.StorageList(ctx, user_id, STORAGE_ACTOR_RESERVED_ID, MAX_ACTOR_SLOTS, "")
	if err != nil {
		return -1, errors.New("storage count reserved actors failed")
	}
	return len(records), nil
}

// func _has_reserved_actor_for_id(ctx context.Context, nk runtime.NakamaModule, key string) (int, error) {
// 	records, err:= nk.StorageRead(ctx, []*runtime.StorageRead {{
// 		Collection: STORAGE_ACTOR_RESERVED_ID,
// 		Key: key,
// 	}})
// 	if err != nil {
// 		return -1, errors.New("read storage reserved actor id failed")
// 	}
// 	return len(records), nil
// }

func _read_reserved_actor_for_id(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, user_id string, key string) (string, string, error) {
	records, err:= nk.StorageRead(ctx, []*runtime.StorageRead {{
		Collection: STORAGE_ACTOR_RESERVED_ID,
		UserID: user_id,
		Key:  key,
	}})
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": key,
		}).Error("read storage reserved actor id")
		return "", "*", errors.New("read storage reserved actor id failed")
	}
	if len(records) <= 0 {
		// Unknown key
		return "", "*", nil
	}
	var result meta.AccountId
	if err := json.Unmarshal([]byte(records[0].Value), &result); err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": key,
			"data": records[0].Value,
		}).Error("unmarshal reserved actor id")
		return "", "*", errors.New("unmarshal reserved actor id failed")
	}
	return result.Value, records[0].Version, nil
}

func _write_reserved_actor_for_id(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, user_id string, key string, version string, account_id string) (string, error) {
	data, err := json.Marshal(meta.AccountId{
		Value: account_id,
	})
	if err != nil {
		logger.WithField("err", err).Error("json marshal account id")
		return "", errors.New("failed encode account id")
	}
	ack, err := nk.StorageWrite(ctx, []*runtime.StorageWrite {{
		Collection: STORAGE_ACTOR_RESERVED_ID,
		UserID: user_id,
		Key: key,
		Value: string(data),
		Version: version,
		PermissionRead: 2,
		PermissionWrite: 0,
	}})
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": key,
			"data": data,
		}).Error("storage write reserved actor id")
		return "", errors.New("storage write reserved actor id failed")
	}
	if len(ack) != 1 {
		logger.WithFields(map[string]interface{}{
			"msg": "invalid ack",
			"len": len(ack),
			"key": key,
			"data": data,
		}).Error("ack storage write reserved actor id")
		return "", errors.New("ack storage write reserved actor id failed")
	}
	return ack[0].Version, nil
}

func _delete_reserved_actor_for_id(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, key string, version string) error {
	err := nk.StorageDelete(ctx, []*runtime.StorageDelete {{
		Collection: STORAGE_ACTOR_RESERVED_ID,
		Version: version,
		Key: key,
	}})
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": key,
		}).Error("delete reserved actor id")
		return errors.New("delete reserved actor id failed")
	}
	return nil
}
