package meta

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"

	"github.com/heroiclabs/nakama-common/runtime"
)

func GetAccountData(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule) (string, *AccountData, error) {
	user_id, ok := ctx.Value(runtime.RUNTIME_CTX_USER_ID).(string)
	if !ok { 
		return "", nil, errors.New("user id not found")
	}
	account, err := nk.AccountGetId(ctx, user_id)
	if err != nil {
		return user_id, nil, errors.New("user account not found")
	}
	if len(account.Email) == 0 {
		return user_id, nil, errors.New("invalid user account found (email)")
	}
	if len(account.Devices) > 0 {
		return user_id, nil, errors.New("invalid user account found (device)")
	}
	if len(account.User.Metadata) < 92 {
		return user_id, nil, errors.New("invalid user account found (metadata)")
	}
	data := AccountData{}
	if err := data.from_json(user_id, logger, account.User.Metadata); nil != err {
		return user_id, nil, errors.New("invalid user account data found (metadata)")
	}
	if len(data.WalletId) < 32 {
		return user_id, nil, errors.New("invalid player wallet found (accountdata)")
	}
	if len(data.MetafabId) < 32 {
		return user_id, nil, errors.New("invalid player account found (accountdata)")
	}
	return user_id, &data, nil
}


func GetPlayerData(logger runtime.Logger, player_id string) (*PlayerData, error) {
	url := fmt.Sprintf("https://api.trymetafab.com/v1/players/%s/data", player_id)
	client := CreateHttpClient()
	req, err := http.NewRequest("GET", url, nil)
	if err != nil { 
		logger.WithFields(map[string]interface{}{
			"err": err,
			"player": player_id,
		}).Error("make http request")
		return nil, errors.New("invalid get request")
	}
	req.Header.Add("accept", "application/json")
	res, err := client.Do(req)
	if err != nil { 
		logger.WithFields(map[string]interface{}{
			"err": err,
			"player": player_id,
		}).Error("send http request")
		return nil, errors.New("sending request failed")
	}
	defer res.Body.Close()
	if res.StatusCode != 200 {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"player": player_id,
			"code": res.StatusCode,
			"status": res.Status,
		}).Error("get player data request")
		return nil, errors.New("get player data request failed")
	}
	body, err := ioutil.ReadAll(res.Body)
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"player": player_id,
		}).Error("get player data result")
		return nil, errors.New("get player data result failed")
	}
	var data PlayerData
	if err := json.Unmarshal(body, &data); err != nil {
		logger.WithFields(map[string]interface{}{
			"crit": err,
			"code": 510,
			"data": data,
			"player": player_id,
		}).Error("unmarshal player data")
		// FixMe Setup Error stacks, sanatise logs
		return nil, errors.New("unmarshal player data failed")
	}
	return &data, nil
}

func SetPlayerData(logger runtime.Logger, player_id string, player_data *PlayerData) error {
	// Call the MetaFab api to update the players data and store it on chain 
	// so that others can read the data but only the private game key can write.
	url := fmt.Sprintf("https://api.trymetafab.com/v1/players/%s/data", player_id)
	game_secret := os.Getenv("METAFAB_GAME_SECRET_KEY")
	if len(game_secret) == 0 {
		return errors.New("missing metafab keys")
	}
	payload, err := json.Marshal(player_data)
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
		return errors.New("sending request failed")
	}
	defer res.Body.Close()
	if res.StatusCode != 200 {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"player": player_id,
			"code": res.StatusCode,
			"status": res.Status,
		}).Error("update player result")
		return errors.New("update request failed")
	}
	return nil
}
