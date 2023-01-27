package sector

import (
	"context"
	"encoding/json"
	"errors"
	"math/rand"
	"time"

	"github.com/heroiclabs/nakama-common/runtime"
	"github.com/vecno-io/metafab-space-whales/server/meta"
)


const MAX_RESERVE_TRIES = 4


// Reserves a random id for a specific account, note an account can only have one reserved origin.
func Reserve(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, account *meta.AccountData, typed uint8, origin Origin) (Id, error) {
	user_id, ok := ctx.Value(runtime.RUNTIME_CTX_USER_ID).(string)
	if !ok { 
		return Id(0), errors.New("user id not found")
	}
	// If account has reserved sector, error
	cnt, err := _cnt_reserved_sectors_for(ctx, nk, user_id)
	if nil != err {
		return Id(0), errors.New("count reserved sectors")
	}
	if cnt >= MAX_SECTOR_SLOTS {
		return Id(0), errors.New("no free sector slots left")
	}
		// If id is reserved try next, max tries or error
	chk := 0
	id := Id(0)
	for chk < MAX_RESERVE_TRIES {
		next := _next_random_position(typed, origin)
		cnt, err := _has_reserved_sector_for_id(
			ctx, nk, next.Key(),
		)
		if cnt == 0 && err == nil {
			id = next
			break
		}
		chk++
	}
	if Id(0) == id {
		return Id(0), errors.New("failed to find free sector")
	}
	// Save the reservation links to storage and return the id as result
	_, err = _write_reserved_sector_for_id(ctx, logger, nk, user_id, id.Key(), "*", account.MetafabId)
	if nil != err {
		return Id(0), errors.New("failed to reserve sector (id)")
	}
	// if _, err := _write_reserved_sector_for_account(ctx, logger, nk, account.MetafabId, "*", id); nil != err {
	// 	_ = _delete_reserved_sector_for_id(ctx, logger, nk, id.Key(), ver)
	// 	return Id(0), errors.New("failed to reserve sector (account)")
	// }
	return id, nil
}

func _next_random_position(typed uint8, origin Origin) Id {
	rng := rand.New(rand.NewSource(time.Now().UnixNano()))
	// Range from zero to max value for uint16
	pos_x := uint16(rng.Int31n(65535))
	pos_y := uint16(rng.Int31n(65535))
	org_x, org_y := origin.Split()
	return NewId(
		CURRENT_VERSION, typed,
		org_x, org_y, pos_x, pos_y,
	)
}


func _cnt_reserved_sectors_for(ctx context.Context, nk runtime.NakamaModule, user_id string) (int, error) {
	records, _, err:= nk.StorageList(ctx, user_id, STORAGE_SECTOR_RESERVED_ID, MAX_SECTOR_SLOTS, "")
	if err != nil {
		return -1, errors.New("storage count reserved actors failed")
	}
	return len(records), nil
}

func _has_reserved_sector_for_id(ctx context.Context, nk runtime.NakamaModule, key string) (int, error) {
	records, err:= nk.StorageRead(ctx, []*runtime.StorageRead {{
		Collection: STORAGE_SECTOR_RESERVED_ID,
		Key: key,
	}})
	if err != nil {
		return -1, errors.New("read storage reserved sector id failed")
	}
	return len(records), nil
}

func _read_reserved_sector_for_id(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, user_id string, key string) (string, string, error) {
	records, err:= nk.StorageRead(ctx, []*runtime.StorageRead {{
		Collection: STORAGE_SECTOR_RESERVED_ID,
		UserID: user_id,
		Key:  key,
	}})
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": key,
		}).Error("read storage reserved sector id")
		return "", "*", errors.New("read storage reserved sector id failed")
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
		}).Error("unmarshal reserved sector id")
		return "", "*", errors.New("unmarshal reserved sector id failed")
	}
	return result.Value, records[0].Version, nil
}

func _write_reserved_sector_for_id(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, user_id string, key string, version string, account_id string) (string, error) {
	data, err := json.Marshal(meta.AccountId {
		Value: account_id,
	})
	if err != nil {
		logger.WithField("err", err).Error("json marshal account id")
		return "", errors.New("failed encode account id")
	}
	ack, err := nk.StorageWrite(ctx, []*runtime.StorageWrite {{
		Collection: STORAGE_SECTOR_RESERVED_ID,
		Version: version,
		UserID: user_id,
		Key: key,
		Value: string(data),
		PermissionRead: 2,
		PermissionWrite: 0,
	}})
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": key,
			"data": data,
		}).Error("write storage reserved sector id")
		return "", errors.New("write storage reserved sector id failed")
	}
	if len(ack) != 1 {
		logger.WithFields(map[string]interface{}{
			"msg": "invalid ack",
			"len": len(ack),
			"key": key,
			"data": data,
		}).Error("ack write storage reserved sector id")
		return "", errors.New("ack write storage reserved sector id failed")
	}
	return ack[0].Version, nil
}

func _delete_reserved_sector_for_id(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, user_id string, key string, version string) error {
	err := nk.StorageDelete(ctx, []*runtime.StorageDelete {{
		Collection: STORAGE_SECTOR_RESERVED_ID,
		Version: version,
		UserID: user_id,
		Key: key,
	}})
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": key,
		}).Error("delete reserved sector id")
		return errors.New("delete reserved sector id failed")
	}
	return nil
}
