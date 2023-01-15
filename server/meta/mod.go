package meta

import (
	"encoding/json"
	"errors"
	"net"
	"net/http"
	"time"

	"github.com/heroiclabs/nakama-common/runtime"
)

type RegisterReq struct {
	WalletId string `json:"wallet_id"`
	MetafabId string `json:"metafab_id"`
}

type Transaction struct {
	Id string `json:"id"`
	Hash string `json:"hash"`
	Function string `json:"function"`
	WalletId string `json:"walletId"`
	ContractId string `json:"contractId"`
	UpdatedAt string `json:"updatedAt"`
	CreatedAt string `json:"createdAt"`
	Arguments []interface{} `json:"args"`
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
    Timeout: 12 * time.Second,
    Transport: &http.Transport{
			Dial: (&net.Dialer{
							Timeout:   4 * time.Second,
							KeepAlive: 4 * time.Second,
			}).Dial,
			TLSHandshakeTimeout:   4 * time.Second,
			ResponseHeaderTimeout: 8 * time.Second,
			ExpectContinueTimeout: 4 * time.Second,
	}}
}

func (ref *AccountData) to_map() map[string]interface{} {
	return map[string]interface{}{
		"wallet_id": ref.WalletId,
		"metafab_id": ref.MetafabId,
	}
}

func (ref *AccountData) from_json(data string, user_id string, logger runtime.Logger) error {
	err := json.Unmarshal([]byte(data), ref)
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err, "user": user_id, "data": data,
		}).Error("decode player data")
		return errors.New("invalid player data")
	}
	return nil
}

func (ref *RegisterReq) from_payload(data string, user_id string, logger runtime.Logger) error {
	err := json.Unmarshal([]byte(data), ref)
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err, "user": user_id,
		}).Error("decode request data")
		return errors.New("invalid request data")
	}
	return nil
}