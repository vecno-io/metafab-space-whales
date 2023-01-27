package meta

import (
	"context"
	"encoding/json"
	"errors"

	"github.com/heroiclabs/nakama-common/runtime"
)

const STORAGE_META_ACCOUNT_TXN = "META_ACCOUNT_TXN"


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

func SaveTransaction(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, user_id string, data string) (*Transaction, error) {
	// Decode transaction result
	txn := &Transaction{}
	if err := json.Unmarshal([]byte(data), txn); err != nil {
		logger.WithFields(map[string]interface{}{
			"crit": err,
			"code": 510,
			"data": data,
			"user": user_id,
		}).Error("unmarshal transaction")
		// FixMe Setup Error stacks, sanatise logs
		return nil, errors.New("unmarshal transaction failed")
	}
	// Store the actor id to the users mint history
	if _, err := nk.StorageWrite(ctx, []*runtime.StorageWrite {{
		Collection: STORAGE_META_ACCOUNT_TXN,
		Key: txn.Id,
		Value: data,
		Version: "*",
		UserID: user_id,
		PermissionRead: 2,
		PermissionWrite: 0,
	}}); err != nil {
		logger.WithFields(map[string]interface{}{
			"crit": err,
			"code": 510,
			"data": data,
			"user": user_id,
		}).Error("storage write transaction")
		// FixMe Setup Error stacks, sanatise logs
		return nil, errors.New("storage write transaction failed")
	}
	return txn, nil
}