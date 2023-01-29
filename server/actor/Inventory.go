package actor

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"

	"github.com/heroiclabs/nakama-common/runtime"
	"github.com/vecno-io/metafab-space-whales/server/meta"
)

// Note: Actor storage is not bound to accounts as
// actors can be transfered between player accounts.

// TODO: Allot of the code below can be extracted in to functions,
// The double reads and double writes are mostly the same on types.

type CoinState struct {
	Key      string `json:"key"`
	Stored    uint64 `json:"stored"`
	Inventory uint64 `json:"inventory"`
}

type BoosterState struct {
	Type      string `json:"type"`
	Stored    uint64 `json:"stored"`
	Inventory uint64 `json:"inventory"`
}

type CoinResult struct {
	Actor string `json:"actor"`
	CoinState
}

type CoinRequest struct {
	Actor string `json:"actor"`
	CoinState
}

type BoosterResult struct {
	Actor string `json:"actor"`
	BoosterState
}

type BoosterRequest struct {
	Actor string `json:"actor"`
	BoosterState
}

type InvemtoryResult struct {
	Actor    string         `json:"actor"`
	Coins    []CoinState    `json:"coins"`
	Boosters []BoosterState `json:"boosters"`
}

type InvemtoryRequest struct {
	Actor string `json:"actor"`
}

type CombatOutcome struct {
	Actor string `json:"actor"`
	Dust  uint64 `json:"dust"`
	Speed  uint64 `json:"speed"`
	Attack  uint64 `json:"attack"`
}

func (res *CoinResult) FromRequest(req CoinRequest) {
	res.Key = req.Key
	res.Actor = req.Actor
	res.Stored = req.Stored
	res.Inventory = req.Inventory
}

func (res *BoosterResult) FromRequest(req BoosterRequest) {
	res.Type = req.Type
	res.Actor = req.Actor
	res.Stored = req.Stored
	res.Inventory = req.Inventory
}



func InventoryRpc(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	// Requires a valid metafab account, that account needs to own the actor
	user_id, account, err := meta.GetAccountData(ctx, logger, nk)
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
		}).Error("failed to get acount data")
		return "{}", errors.New("failed to load account data")
	}
	var request InvemtoryRequest 
	if err := json.Unmarshal([]byte(payload), &request); err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"code": 500,
			"user": user_id,
			"data": payload,
		}).Error("unmarshal request")
		return "{}", runtime.NewError("invalid request", 500)
	}
	// TODO NEXT -> Player needs to own the actor
	// METAFAB API CALL: Get collection item balance
	// Read coin values for player (storage) and actor (inventory)
	// ===============================
	// Read Inventory state for actor
	var result = InvemtoryResult{}
	result.Actor = request.Actor
	// FixMe: Hardcoded coin and booster keys
	dust_stored, _, err := _read_coin_for_storage(ctx, logger, nk, user_id, "DUST")
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": "DUST",
			"user": user_id,
			"player": account.MetafabId,
		}).Error("read storage (user)")
		return "{}", errors.New("read storage failed")
	}
	dust_inventory, _, err := _read_coin_for_inventory(ctx, logger, nk, request.Actor, "DUST")
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": "DUST",
			"user": user_id,
			"player": account.MetafabId,
		}).Error("read storage (account)")
		return "{}", errors.New("read storage failed")
	}
	result.Coins = []CoinState{{
		Key: "DUST",
		Stored: dust_stored.Value,
		Inventory: dust_inventory.Value,
	}}
	speed_stored, _, err := _read_booster_for_storage(ctx, logger, nk, user_id, "SPEED")
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": "SPEED",
			"user": user_id,
			"player": account.MetafabId,
		}).Error("read storage (user)")
		return "{}", errors.New("read storage failed")
	}
	speed_inventory, _, err := _read_booster_for_inventory(ctx, logger, nk, request.Actor, "SPEED")
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": "SPEED",
			"user": user_id,
			"player": account.MetafabId,
		}).Error("read storage (account)")
		return "{}", errors.New("read storage failed")
	}
	attack_stored, _, err := _read_booster_for_storage(ctx, logger, nk, user_id, "ATTACK")
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": "ATTACK",
			"user": user_id,
			"player": account.MetafabId,
		}).Error("read storage (user)")
		return "{}", errors.New("read storage failed")
	}
	attack_inventory, _, err := _read_booster_for_inventory(ctx, logger, nk, request.Actor, "ATTACK")
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": "ATTACK",
			"user": user_id,
			"player": account.MetafabId,
		}).Error("read storage (account)")
		return "{}", errors.New("read storage failed")
	}
	result.Boosters = []BoosterState{{
		Type: "SPEED",
		Stored: speed_stored.Value,
		Inventory: speed_inventory.Value,
	},{
		Type: "ATTACK",
		Stored: attack_stored.Value,
		Inventory: attack_inventory.Value,
	}}
	// Finalize result and send out
	data, err := json.Marshal(result)
	if err != nil {
		logger.WithField("err", err).Error("json marshal result")
		return "{}", errors.New("json marshal result failed")
	}
	return string(data), nil
}

func CombatOutcomeRpc(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	// Requires a valid metafab account, that account needs to own the actor
	user_id, account, err := meta.GetAccountData(ctx, logger, nk)
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
		}).Error("failed to get acount data")
		return "{}", errors.New("failed to load account data")
	}
	var request CombatOutcome 
	if err := json.Unmarshal([]byte(payload), &request); err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"code": 500,
			"user": user_id,
			"data": payload,
		}).Error("unmarshal request")
		return "{}", runtime.NewError("invalid request", 500)
	}
	// TODO NEXT -> Player needs to own the actor
	// METAFAB API CALL: Get collection item balance
	// Read coin values for player (storage) and actor (inventory)
	// ===============================
	// Read Inventory state for actor
	var result = InvemtoryResult{}
	result.Actor = request.Actor
	// FixMe: Hardcoded coin and booster keys
	dust_stored, _, err := _read_coin_for_storage(ctx, logger, nk, user_id, "DUST")
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": "DUST",
			"user": user_id,
			"player": account.MetafabId,
		}).Error("read storage (user)")
		return "{}", errors.New("read storage failed")
	}
	dust_inventory, dust_version, err := _read_coin_for_inventory(ctx, logger, nk, request.Actor, "DUST")
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": "DUST",
			"user": user_id,
			"player": account.MetafabId,
		}).Error("read storage (account)")
		return "{}", errors.New("read storage failed")
	}
	speed_stored, _, err := _read_booster_for_storage(ctx, logger, nk, user_id, "SPEED")
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": "SPEED",
			"user": user_id,
			"player": account.MetafabId,
		}).Error("read storage (user)")
		return "{}", errors.New("read storage failed")
	}
	speed_inventory, speed_version, err := _read_booster_for_inventory(ctx, logger, nk, request.Actor, "SPEED")
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": "SPEED",
			"user": user_id,
			"player": account.MetafabId,
		}).Error("read storage (account)")
		return "{}", errors.New("read storage failed")
	}
	attack_stored, _, err := _read_booster_for_storage(ctx, logger, nk, user_id, "ATTACK")
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": "ATTACK",
			"user": user_id,
			"player": account.MetafabId,
		}).Error("read storage (user)")
		return "{}", errors.New("read storage failed")
	}
	attack_inventory, attack_version, err := _read_booster_for_inventory(ctx, logger, nk, request.Actor, "ATTACK")
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": "ATTACK",
			"user": user_id,
			"player": account.MetafabId,
		}).Error("read storage (account)")
		return "{}", errors.New("read storage failed")
	}
	// Update all values and set result
	// TODO: Validate based on combat logs
	dust_inventory.Value = request.Dust
	speed_inventory.Value = request.Speed
	attack_inventory.Value = request.Attack
	result.Coins = []CoinState{{
		Key: "DUST",
		Stored: dust_stored.Value,
		Inventory: dust_inventory.Value,
	}}
	result.Boosters = []BoosterState{{
		Type: "SPEED",
		Stored: speed_stored.Value,
		Inventory: speed_inventory.Value,
	},{
		Type: "ATTACK",
		Stored: attack_stored.Value,
		Inventory: attack_inventory.Value,
	}}
	if _, err := _write_coin_for_inventory(ctx, logger, nk, request.Actor, "DUST", dust_inventory, dust_version); nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": account.MetafabId,
			"payload": payload,
		}).Error("write coin inventory (DUST)")
		return "{}", errors.New("write coin inventory failed")
	}
	if _, err := _write_booster_for_inventory(ctx, logger, nk, request.Actor, "SPEED", speed_inventory, speed_version); nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": account.MetafabId,
			"payload": payload,
		}).Error("write booster inventory (SPEED)")
		return "{}", errors.New("write booster inventory failed")
	}
	if _, err := _write_booster_for_inventory(ctx, logger, nk, request.Actor, "ATTACK", attack_inventory, attack_version); nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": account.MetafabId,
			"payload": payload,
		}).Error("write booster inventory (ATTACK)")
		return "{}", errors.New("write booster inventory failed")
	}
	// Finalize result and send out
	data, err := json.Marshal(result)
	if err != nil {
		logger.WithField("err", err).Error("json marshal result")
		return "{}", errors.New("json marshal result failed")
	}
	return string(data), nil
}


func TakeCoinRpc(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	// Requires a valid metafab account, that account needs to own the actor
	user_id, account, err := meta.GetAccountData(ctx, logger, nk)
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
		}).Error("failed to get acount data")
		return "{}", errors.New("failed to load account data")
	}
	var request CoinRequest 
	if err := json.Unmarshal([]byte(payload), &request); err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"code": 500,
			"user": user_id,
			"data": payload,
		}).Error("unmarshal request")
		return "{}", runtime.NewError("invalid request", 500)
	}
	// TODO NEXT -> Player needs to own the actor
	// METAFAB API CALL: Get collection item balance
	// Read coin values for player and actor
	stored, stored_ver, err := _read_coin_for_storage(ctx, logger, nk, user_id, request.Key)
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": account.MetafabId,
		}).Error("read storage (user)")
		return "{}", errors.New("read storage failed")
	}
	inventory, inventory_ver, err := _read_coin_for_inventory(ctx, logger, nk, request.Actor, request.Key)
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": account.MetafabId,
		}).Error("read storage (account)")
		return "{}", errors.New("read storage failed")
	}
	// Validate and update
	// Take from stored, add to inventory
	if request.Stored >= stored.Value {
		logger.WithFields(map[string]interface{}{
			"user": user_id,
			"player": account.MetafabId,
			"payload": payload,
		}).Error("insufficient funds")
		return "{}", errors.New("insufficient funds")
	}
	var withdrawl = stored.Value - request.Stored
	var total = inventory.Value + withdrawl
	if request.Inventory != total {
		logger.WithFields(map[string]interface{}{
			"user": user_id,
			"player": account.MetafabId,
			"payload": payload,
		}).Error("verify total")
		return "{}", errors.New("verify total failed")
	}
	// Updated database value
	stored.Value = request.Stored
	inventory.Value = request.Inventory
	stored_ver, err = _write_coin_for_storage(ctx, logger, nk, user_id, request.Key, stored, stored_ver)
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": account.MetafabId,
			"payload": payload,
		}).Error("write coin storage (user)")
		return "{}", errors.New("write coin storage failed")
	}
	if _, err := _write_coin_for_inventory(ctx, logger, nk, request.Actor, request.Key, inventory, inventory_ver); nil != err {
		stored.Value += withdrawl
		if _, inner := _write_coin_for_storage(ctx, logger, nk, user_id, request.Key, stored, stored_ver); nil != inner {
			logger.WithFields(map[string]interface{}{
				"errr": inner,
				"user": user_id,
				"player": account.MetafabId,
				"critical": "storage rollback failed",
			}).Error("write coin storage")
			return "{}", errors.New("critical: rollback failed")
		}
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": account.MetafabId,
			"payload": payload,
		}).Error("write coin inventory (actor)")
		return "{}", errors.New("write coin inventory failed")
	}
	var result = CoinResult{}
	result.FromRequest(request)
	data, err := json.Marshal(result)
	if err != nil {
		logger.WithField("err", err).Error("json marshal result")
		return "{}", errors.New("json marshal result failed")
	}
	return string(data), nil
}

func StoreCoinRpc(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	// Requires a valid metafab account, that account needs to own the actor
	user_id, account, err := meta.GetAccountData(ctx, logger, nk)
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
		}).Error("failed to get acount data")
		return "{}", errors.New("failed to load account data")
	}
	var request CoinRequest 
	if err := json.Unmarshal([]byte(payload), &request); err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"code": 500,
			"user": user_id,
			"data": payload,
		}).Error("unmarshal request")
		return "{}", runtime.NewError("invalid request", 500)
	}
	// TODO NEXT -> Player needs to own the actor
	// METAFAB API CALL: Get collection item balance
	// Read coin values for player and actor
	stored, stored_ver, err := _read_coin_for_storage(ctx, logger, nk, user_id, request.Key)
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": account.MetafabId,
		}).Error("read storage (user)")
		return "{}", errors.New("read storage failed")
	}
	inventory, inventory_ver, err := _read_coin_for_inventory(ctx, logger, nk, request.Actor, request.Key)
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": account.MetafabId,
		}).Error("read storage (account)")
		return "{}", errors.New("read storage failed")
	}
	// Validate and update
	// Take from inventory, add to stored
	if request.Inventory >= inventory.Value {
		logger.WithFields(map[string]interface{}{
			"user": user_id,
			"player": account.MetafabId,
			"payload": payload,
		}).Error("insufficient funds")
		return "{}", errors.New("insufficient funds")
	}
	var withdrawl = inventory.Value - request.Inventory
	var total = stored.Value + withdrawl
	if request.Stored != total {
		logger.WithFields(map[string]interface{}{
			"user": user_id,
			"player": account.MetafabId,
			"payload": payload,
		}).Error("verify total")
		return "{}", errors.New("verify total failed")
	}
	// Updated database value
	stored.Value = request.Stored
	inventory.Value = request.Inventory
	stored_ver, err = _write_coin_for_storage(ctx, logger, nk, user_id, request.Key, stored, stored_ver)
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": account.MetafabId,
			"payload": payload,
		}).Error("write coin storage (user)")
		return "{}", errors.New("write coin storage failed")
	}
	if _, err := _write_coin_for_inventory(ctx, logger, nk, request.Actor, request.Key, inventory, inventory_ver); nil != err {
		stored.Value += withdrawl
		if _, inner := _write_coin_for_storage(ctx, logger, nk, user_id, request.Key, stored, stored_ver); nil != inner {
			logger.WithFields(map[string]interface{}{
				"errr": inner,
				"user": user_id,
				"player": account.MetafabId,
				"critical": "storage rollback failed",
			}).Error("write coin storage")
			return "{}", errors.New("critical: rollback failed")
		}
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": account.MetafabId,
			"payload": payload,
		}).Error("write coin inventory (actor)")
		return "{}", errors.New("write coin inventory failed")
	}
	var result = CoinResult{}
	result.FromRequest(request)
	data, err := json.Marshal(result)
	if err != nil {
		logger.WithField("err", err).Error("json marshal result")
		return "{}", errors.New("json marshal result failed")
	}
	return string(data), nil
}

func TakeBoosterRpc(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	// Requires a valid metafab account, that account needs to own the actor
	user_id, account, err := meta.GetAccountData(ctx, logger, nk)
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
		}).Error("failed to get acount data")
		return "{}", errors.New("failed to load account data")
	}
	var request BoosterRequest 
	if err := json.Unmarshal([]byte(payload), &request); err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"code": 500,
			"user": user_id,
			"data": payload,
		}).Error("unmarshal request")
		return "{}", runtime.NewError("invalid request", 500)
	}
	// TODO NEXT -> Player needs to own the actor
	// METAFAB API CALL: Get collection item balance
	// Read booster values for player and actor
	stored, stored_ver, err := _read_booster_for_storage(ctx, logger, nk, user_id, request.Type)
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": account.MetafabId,
		}).Error("read storage (user)")
		return "{}", errors.New("read storage failed")
	}
	inventory, inventory_ver, err := _read_booster_for_inventory(ctx, logger, nk, request.Actor, request.Type)
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": account.MetafabId,
		}).Error("read storage (account)")
		return "{}", errors.New("read storage failed")
	}
	// Validate and update
	// Take from stored, add to inventory
	if request.Stored >= stored.Value {
		logger.WithFields(map[string]interface{}{
			"user": user_id,
			"player": account.MetafabId,
			"payload": payload,
		}).Error("insufficient funds")
		return "{}", errors.New("insufficient funds")
	}
	var withdrawl = stored.Value - request.Stored
	var total = inventory.Value + withdrawl
	if request.Inventory != total {
		logger.WithFields(map[string]interface{}{
			"user": user_id,
			"player": account.MetafabId,
			"payload": payload,
		}).Error("verify total")
		return "{}", errors.New("verify total failed")
	}
	// Updated database value
	stored.Value = request.Stored
	inventory.Value = request.Inventory
	stored_ver, err = _write_booster_for_storage(ctx, logger, nk, user_id, request.Type, stored, stored_ver)
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": account.MetafabId,
			"payload": payload,
		}).Error("write booster storage (user)")
		return "{}", errors.New("write booster storage failed")
	}
	if _, err := _write_booster_for_inventory(ctx, logger, nk, request.Actor, request.Type, inventory, inventory_ver); nil != err {
		stored.Value += withdrawl
		if _, inner := _write_booster_for_storage(ctx, logger, nk, user_id, request.Type, stored, stored_ver); nil != inner {
			logger.WithFields(map[string]interface{}{
				"errr": inner,
				"user": user_id,
				"player": account.MetafabId,
				"critical": "storage rollback failed",
			}).Error("write booster storage")
			return "{}", errors.New("critical: rollback failed")
		}
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": account.MetafabId,
			"payload": payload,
		}).Error("write booster inventory (actor)")
		return "{}", errors.New("write booster inventory failed")
	}
	var result = BoosterResult{}
	result.FromRequest(request)
	data, err := json.Marshal(result)
	if err != nil {
		logger.WithField("err", err).Error("json marshal result")
		return "{}", errors.New("json marshal result failed")
	}
	return string(data), nil
}

func StoreBoosterRpc(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	// Requires a valid metafab account, that account needs to own the actor
	user_id, account, err := meta.GetAccountData(ctx, logger, nk)
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
		}).Error("failed to get acount data")
		return "{}", errors.New("failed to load account data")
	}
	var request BoosterRequest 
	if err := json.Unmarshal([]byte(payload), &request); err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"code": 500,
			"user": user_id,
			"data": payload,
		}).Error("unmarshal request")
		return "{}", runtime.NewError("invalid request", 500)
	}
	// TODO NEXT -> Player needs to own the actor
	// METAFAB API CALL: Get collection item balance
	// Read coin values for player (storage) and actor (inventory)
	stored, stored_ver, err := _read_booster_for_storage(ctx, logger, nk, user_id, request.Type)
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": account.MetafabId,
		}).Error("read storage (user)")
		return "{}", errors.New("read storage failed")
	}
	inventory, inventory_ver, err := _read_booster_for_inventory(ctx, logger, nk, request.Actor, request.Type)
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": account.MetafabId,
		}).Error("read storage (actor)")
		return "{}", errors.New("read storage failed")
	}
	// Validate and update
	// Take from inventory, add to stored
	if request.Inventory >= inventory.Value {
		logger.WithFields(map[string]interface{}{
			"user": user_id,
			"player": account.MetafabId,
			"payload": payload,
		}).Error("insufficient funds")
		return "{}", errors.New("insufficient funds")
	}
	var withdrawl = inventory.Value - request.Inventory
	var total = stored.Value + withdrawl
	if request.Stored != total {
		logger.WithFields(map[string]interface{}{
			"user": user_id,
			"player": account.MetafabId,
			"payload": payload,
		}).Error("verify total")
		return "{}", errors.New("verify total failed")
	}
	// Updated database value
	stored.Value = request.Stored
	inventory.Value = request.Inventory
	stored_ver, err = _write_booster_for_storage(ctx, logger, nk, user_id, request.Type, stored, stored_ver)
	if nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": account.MetafabId,
			"payload": payload,
		}).Error("write booster storage (user)")
		return "{}", errors.New("write booster storage failed")
	}
	if _, err := _write_booster_for_inventory(ctx, logger, nk, request.Actor, request.Type, inventory, inventory_ver); nil != err {
		stored.Value += withdrawl
		if _, inner := _write_booster_for_storage(ctx, logger, nk, user_id, request.Type, stored, stored_ver); nil != inner {
			logger.WithFields(map[string]interface{}{
				"errr": inner,
				"user": user_id,
				"player": account.MetafabId,
				"critical": "storage rollback failed",
			}).Error("write booster storage")
			return "{}", errors.New("critical: rollback failed")
		}
		logger.WithFields(map[string]interface{}{
			"err": err,
			"user": user_id,
			"player": account.MetafabId,
			"payload": payload,
		}).Error("write booster inventory (actor)")
		return "{}", errors.New("write booster inventory failed")
	}
	var result = BoosterResult{}
	result.FromRequest(request)
	data, err := json.Marshal(result)
	if err != nil {
		logger.WithField("err", err).Error("json marshal result")
		return "{}", errors.New("json marshal result failed")
	}
	return string(data), nil
}


func _read_coin_for_inventory(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, actor_id string, key string) (*Coin, string, error) {
	records, err:= nk.StorageRead(ctx, []*runtime.StorageRead {{
		Collection: STORAGE_ACTOR_COIN_INVENTORY,
		Key: fmt.Sprintf(
			"%s||%s", key, actor_id,
		),
	}})
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": key,
			"actor": actor_id,
		}).Error("read storage")
		return nil, "*", errors.New("read storage failed")
	}
	if len(records) <= 0 {
		// Unknown key, return zero
		return &Coin{Value:0}, "*", nil
	}
	result := &Coin{}
	if err := json.Unmarshal([]byte(records[0].Value), result); err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": key,
			"actor": actor_id,
			"result": records[0].Value,
		}).Error("unmarshal result")
		return nil, "*", errors.New("unmarshal result failed")
	}
	return result, records[0].Version, nil
}

func _write_coin_for_inventory(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, actor_id string, key string, value *Coin, ver string) (string, error) {
	data, err := json.Marshal(value)
	if err != nil {
		logger.WithField("err", err).Error("marshal value")
		return "", errors.New("marshal value failed")
	}
	ack, err := nk.StorageWrite(ctx, []*runtime.StorageWrite {{
		Collection: STORAGE_ACTOR_COIN_INVENTORY,
		Version: ver,
		Key:  fmt.Sprintf(
			"%s||%s", key, actor_id,
		),
		Value: string(data),
		PermissionRead: 2,
		PermissionWrite: 0,
	}})
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": key,
			"data": data,
			"actor": actor_id,
		}).Error("storage write")
		return "", errors.New("storage write failed")
	}
	if len(ack) != 1 {
		logger.WithFields(map[string]interface{}{
			"msg": "invalid ack",
			"len": len(ack),
			"key": key,
			"data": data,
			"actor": actor_id,
		}).Error("ack storage write")
		return "", errors.New("ack storage write failed")
	}
	return ack[0].Version, nil
}

func _read_booster_for_inventory(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, actor_id string, key string) (*Boost, string, error) {
	records, err:= nk.StorageRead(ctx, []*runtime.StorageRead {{
		Collection: STORAGE_ACTOR_BOOSTER_INVENTORY,
		Key: fmt.Sprintf(
			"%s||%s", key, actor_id,
		),
	}})
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": key,
			"actor": actor_id,
		}).Error("read storage")
		return nil, "*", errors.New("read storage failed")
	}
	if len(records) <= 0 {
		// Unknown key, return zero
		return &Boost{Value:0}, "*", nil
	}
	result := &Boost{}
	if err := json.Unmarshal([]byte(records[0].Value), result); err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": key,
			"actor": actor_id,
			"result": records[0].Value,
		}).Error("unmarshal result")
		return nil, "*", errors.New("unmarshal result failed")
	}
	return result, records[0].Version, nil
}

func _write_booster_for_inventory(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, actor_id string, key string, value *Boost, ver string) (string, error) {
	data, err := json.Marshal(value)
	if err != nil {
		logger.WithField("err", err).Error("marshal value")
		return "", errors.New("marshal value failed")
	}
	ack, err := nk.StorageWrite(ctx, []*runtime.StorageWrite {{
		Collection: STORAGE_ACTOR_BOOSTER_INVENTORY,
		Version: ver,
		Key:  fmt.Sprintf(
			"%s||%s", key, actor_id,
		),
		Value: string(data),
		PermissionRead: 2,
		PermissionWrite: 0,
	}})
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": key,
			"data": data,
			"actor": actor_id,
		}).Error("storage write")
		return "", errors.New("storage write failed")
	}
	if len(ack) != 1 {
		logger.WithFields(map[string]interface{}{
			"msg": "invalid ack",
			"len": len(ack),
			"key": key,
			"data": data,
			"actor": actor_id,
		}).Error("ack storage write")
		return "", errors.New("ack storage write failed")
	}
	return ack[0].Version, nil
}


func _read_coin_for_storage(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, user_id string, key string) (*Coin, string, error) {
	records, err:= nk.StorageRead(ctx, []*runtime.StorageRead {{
		Collection: STORAGE_ACTOR_COIN_STORED,
		UserID: user_id,
		Key:  key,
	}})
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": key,
			"player": user_id,
		}).Error("read storage")
		return nil, "*", errors.New("read storage failed")
	}
	if len(records) <= 0 {
		// Unknown key, return zero
		return &Coin{Value:0}, "*", nil
	}
	result := &Coin{}
	if err := json.Unmarshal([]byte(records[0].Value), result); err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": key,
			"player": user_id,
			"result": records[0].Value,
		}).Error("unmarshal result")
		return nil, "*", errors.New("unmarshal result failed")
	}
	return result, records[0].Version, nil
}

func _write_coin_for_storage(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, user_id string, key string, value *Coin, ver string) (string, error) {
	data, err := json.Marshal(value)
	if err != nil {
		logger.WithField("err", err).Error("marshal value")
		return "", errors.New("marshal value failed")
	}
	ack, err := nk.StorageWrite(ctx, []*runtime.StorageWrite {{
		Collection: STORAGE_ACTOR_COIN_STORED,
		Version: ver,
		UserID: user_id,
		Key:  key,
		Value: string(data),
		PermissionRead: 2,
		PermissionWrite: 0,
	}})
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": key,
			"data": data,
			"player": user_id,
		}).Error("storage write")
		return "", errors.New("storage write failed")
	}
	if len(ack) != 1 {
		logger.WithFields(map[string]interface{}{
			"msg": "invalid ack",
			"len": len(ack),
			"key": key,
			"data": data,
			"player": user_id,
		}).Error("ack storage write")
		return "", errors.New("ack storage write failed")
	}
	return ack[0].Version, nil
}

func _read_booster_for_storage(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, user_id string, key string) (*Boost, string, error) {
	records, err:= nk.StorageRead(ctx, []*runtime.StorageRead {{
		Collection: STORAGE_ACTOR_BOOSTER_STORED,
		UserID: user_id,
		Key:  key,
	}})
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": key,
			"player": user_id,
		}).Error("read storage")
		return nil, "*", errors.New("read storage failed")
	}
	if len(records) <= 0 {
		// Unknown key, return zero
		return &Boost{Value:0}, "*", nil
	}
	result := &Boost{}
	if err := json.Unmarshal([]byte(records[0].Value), result); err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": key,
			"player": user_id,
			"result": records[0].Value,
		}).Error("unmarshal result")
		return nil, "*", errors.New("unmarshal result failed")
	}
	return result, records[0].Version, nil
}

func _write_booster_for_storage(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, user_id string, key string, value *Boost, ver string) (string, error) {
	data, err := json.Marshal(value)
	if err != nil {
		logger.WithField("err", err).Error("marshal value")
		return "", errors.New("marshal value failed")
	}
	ack, err := nk.StorageWrite(ctx, []*runtime.StorageWrite {{
		Collection: STORAGE_ACTOR_BOOSTER_STORED,
		Version: ver,
		UserID: user_id,
		Key:  key,
		Value: string(data),
		PermissionRead: 2,
		PermissionWrite: 0,
	}})
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": key,
			"data": data,
			"player": user_id,
		}).Error("storage write")
		return "", errors.New("storage write failed")
	}
	if len(ack) != 1 {
		logger.WithFields(map[string]interface{}{
			"msg": "invalid ack",
			"len": len(ack),
			"key": key,
			"data": data,
			"player": user_id,
		}).Error("ack storage write")
		return "", errors.New("ack storage write failed")
	}
	return ack[0].Version, nil
}
