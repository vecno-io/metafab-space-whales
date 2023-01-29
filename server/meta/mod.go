package meta

import (
	"encoding/json"
	"errors"
	"net"
	"net/http"
	"time"

	"github.com/heroiclabs/nakama-common/runtime"
)

type AccountId struct {
	Value string `json:"value"`
}

type RegisterReq struct {
	WalletId string `json:"wallet_id"`
	MetafabId string `json:"metafab_id"`
}

type AccountData struct {
	WalletId string `json:"wallet_id"`
	MetafabId string `json:"metafab_id"`
}

type PlayerData struct {
	ProtectedData ProtectedData `json:"protectedData"`
}

type ProtectedData struct {
	ActorMints uint16 `json:"actorMints"`
	ActorMinted uint16 `json:"actorMinted"`
}

func CreateHttpClient() http.Client {
	return http.Client{
    Timeout: 16 * time.Second,
    Transport: &http.Transport{
			Dial: (&net.Dialer{
							Timeout:   8 * time.Second,
							KeepAlive: 8 * time.Second,
			}).Dial,
			TLSHandshakeTimeout:   8 * time.Second,
			ResponseHeaderTimeout: 8 * time.Second,
			ExpectContinueTimeout: 8 * time.Second,
	}}
}

func (ref *AccountData) to_map() map[string]interface{} {
	return map[string]interface{}{
		"wallet_id": ref.WalletId,
		"metafab_id": ref.MetafabId,
	}
}

func (ref *AccountData) from_json(user_id string, logger runtime.Logger, data string) error {
	err := json.Unmarshal([]byte(data), ref)
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err, "user": user_id, "data": data,
		}).Error("decode player data")
		return errors.New("invalid player data")
	}
	return nil
}

func (ref *RegisterReq) from_payload(user_id string, logger runtime.Logger, data string) error {
	err := json.Unmarshal([]byte(data), ref)
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err, "user": user_id,
		}).Error("decode request data")
		return errors.New("invalid request data")
	}
	if len(ref.WalletId) < 32 {
		return errors.New("invalid wallet in request (min size)")
	}
	if len(ref.MetafabId) < 32 {
		return errors.New("invalid account in request (min size)")
	}
	return nil
}