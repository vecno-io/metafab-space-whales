package meta

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"os"

	"github.com/heroiclabs/nakama-common/runtime"
)

func Register(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	// Validate: Requires a registered user account (has email), without a metafab player;
	// device accounts (no e-mail) or accounts with Metadata can not register a metafab player.
	user_id, ok := ctx.Value(runtime.RUNTIME_CTX_USER_ID).(string)
	if !ok { 
		return "{}", errors.New("user id not found")
	}
	account, err := nk.AccountGetId(ctx, user_id)
	if err != nil {
		return "{}", errors.New("user account not found")
	}
	if len(account.Email) == 0 {
		return "{}", errors.New("invalid user account found (email)")
	}
	if len(account.Devices) > 0 {
		return "{}", errors.New("invalid user account found (device)")
	}
	if len(account.User.Metadata) > 3 {
		return "{}", errors.New("invalid user account found (metadata)")
	}
	var request RegisterReq
	if err := request.from_payload(payload, user_id, logger); nil != err {
		return "{}", err
	}
	// Store the registration request as metadata on the players account
	var accountData AccountData
	accountData.WalletId = request.WalletId
	accountData.MetafabId = request.MetafabId
	if err := nk.AccountUpdateId(
		ctx, user_id, account.User.Username, accountData.to_map(), 
		account.Email, "", "", "", "",
	); err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": request.MetafabId,
		}).Error("failed to update acount data")
		return "0", errors.New("failed to save acount data")
	}
	// Setup the initial data and currency for the player
	// If the player owns less then 3 actors minting is open.
	if err := _savePlayerData(logger, request.MetafabId, PlayerData{
		ProtectedData: ProtectedData{ ActorMints: 3, ActorMinted: 0 },
	}); err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": request.MetafabId,
		}).Error("failed to init free mints")
		return "0", errors.New("failed to assign free mints")
	}
	return "{}", nil
}

func _savePlayerData(logger runtime.Logger, player_id string, data PlayerData) error {
	// Call the MetaFab api to update the players data and store it on chain 
	// so that others can read the data but only the private game key can write.
	url := fmt.Sprintf("https://api.trymetafab.com/v1/players/%s/data", player_id)
	game_secret := os.Getenv("METAFAB_GAME_SECRET_KEY")
	if len(game_secret) == 0 {
		return errors.New("missing metafab keys")
	}
	payload, err := json.Marshal(data)
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"player": player_id,
		}).Error("marshal player data")
		return errors.New("failed encode player data")
	}
	client := CreateHttpClient()
	req, err := http.NewRequest("POST", url, bytes.NewReader(payload))
	if err != nil { 
		logger.WithFields(map[string]interface{}{
			"err": err,
			"player": player_id,
		}).Error("make http request")
		return errors.New("invalid update request")
	}
	req.Header.Add("accept", "application/json")
	req.Header.Add("content-type", "application/json")
	req.Header.Add("X-Authorization", game_secret)
	res, err := client.Do(req)
	if err != nil { 
		logger.WithFields(map[string]interface{}{
			"err": err,
			"player": player_id,
		}).Error("send http request")
		return errors.New("sending update request failed")
	}
	defer res.Body.Close()
	if res.StatusCode != 200 {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"player": player_id,
			"code": res.StatusCode,
			"status": res.Status,
		}).Error("update player result")
		return errors.New("update player transaction failed")
	}
	return nil
}