package actor

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"math/rand"
	"reflect"
	"strconv"
	"strings"
	"time"

	"github.com/heroiclabs/nakama-common/runtime"
	"github.com/vecno-io/metafab-space-whales/server/sector"
)

const MAX_ID_VALUE = uint32(4294967292)
const MAX_TAG_VALUE = uint16(9998)
const MAX_NAME_LENGHT = 24
const MAX_ACTOR_SLOTS = 32

const STORAGE_ACTOR_ITEM = "ACTOR_ITEM"
const STORAGE_ACTOR_META = "ACTOR_META"

const STORAGE_ACTOR_TAG_INDEX = "ACTOR_TAG_INDEX"
const STORAGE_ACTOR_TOKEN_INDEX = "ACTOR_TOKEN_INDEX"

const STORAGE_ACTOR_MINTED_ID = "ACTOR_MINTED_ID"
const STORAGE_ACTOR_RESERVED_ID = "ACTOR_RESERVED_ID"

const STORAGE_ACTOR_COIN_STORED = "ACTOR_COIN_STORED"
const STORAGE_ACTOR_COIN_INVENTORY = "ACTOR_COIN_INVENTORY"
const STORAGE_ACTOR_BOOSTER_STORED = "ACTOR_BOOSTER_STORED"
const STORAGE_ACTOR_BOOSTER_INVENTORY = "ACTOR_BOOSTER_INVENTORY"


type Coin struct {
	Value uint64 `json:"value"`
}

type Boost struct {
	Value uint64 `json:"value"`
}

type Index struct {
	Value uint32 `json:"value"`
}

type Meta struct {
	Id          string  `json:"id"`
	Name        string  `json:"name"`
	Description string  `json:"description"`
	ImageUrl    string  `json:"imageUrl"`
	ExternalUrl string  `json:"externalUrl"`
	Data        Data    `json:"data"`
	Attributes  []Trait `json:"attributes"`
}

type Data struct {
	Stats  []Stat  `json:"stats"`
	Skills []Skill `json:"skills"`
}

type Stat struct {
	Type  string `json:"stat_type"`
	Value uint32 `json:"value"`
}

type Skill struct {
	Type  string `json:"skill_type"`
	Value uint32 `json:"value"`
}

type Trait struct {
	Type    string      `json:"trait_type"`
	Value   interface{} `json:"value"`
}


type Id struct {
	Value  uint32    `json:"value"`
	Sector sector.Id `json:"roots"`
}

func(id *Id) Key() string {
	return fmt.Sprintf(
		"%s::%010d", id.Sector.Key(), id.Value,
	)
}

func(id *Id) Number() string {
	return fmt.Sprintf(
		"%s%010d", id.Sector.Number(), id.Value,
	)
}

func(id *Id) FromKey(val string) error {
	list := strings.Split(string(val), "::")
	if len(list) != 2 {
		return &json.UnsupportedValueError{
			Value: reflect.ValueOf(id),
			Str: string(val),
		}
	}
	var origin sector.Id
	if err := origin.FromKey(list[0]); nil != err {
		return errors.New("decode: invalid origin")
	}
	index, err := strconv.ParseUint(list[1], 10, 32)
	if err != nil {
		return errors.New("decode: invalid index")
	}
	id.Value = uint32(index)
	id.Sector = origin
	return nil
}

func(id *Id) MarshalJSON() ([]byte, error) {
	return json.Marshal(id.Key())
}

func(id *Id) UnmarshalJSON(val []byte) error {
	var key string
	if err := json.Unmarshal(val, &key); err != nil {
		return &json.UnsupportedValueError{
			Value: reflect.ValueOf(id),
			Str: string(val),
		}
	}
	return id.FromKey(key)
}


type Tag struct {
	Value uint16 `json:"value"`
	Name string `json:"name"`
}

func(tag *Tag) Key() string {
	return fmt.Sprintf(
		"%s#%04d", tag.Name, tag.Value,
	)
}

func(tag *Tag) MarshalJSON() ([]byte, error) {
	return json.Marshal(tag.Key())
}

func(tag *Tag) UnmarshalJSON(val []byte) error {
	var str string
	if err := json.Unmarshal(val, &str); err != nil {
		return &json.UnsupportedValueError{
			Value: reflect.ValueOf(tag),
			Str: string(val),
		}
	}
	list := strings.Split(string(str), "#")
	if len(list) != 2 {
		return &json.UnsupportedValueError{
			Value: reflect.ValueOf(tag),
			Str: string(str),
		}
	}
	index, err := strconv.ParseUint(list[1], 10, 32)
	if err != nil {
		return errors.New("unmarshal: invalid index")
	}
	tag.Value = uint16(index)
	tag.Name = list[0]
	return nil
}


// read the current actor tag index, a tag index keeps track of the current id for an specified name
func _read_actor_tag_index(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, name string) (Tag, string, error) {
	if len(name) > MAX_NAME_LENGHT {
		logger.WithFields(map[string]interface{}{
			"key": name,
		}).Error("invalid name length")
		return Tag{}, "*", errors.New("invalid name length")
	}
	if strings.Contains(name, "#") {
		logger.WithFields(map[string]interface{}{
			"key": name,
		}).Error("invalid name")
		return Tag{}, "*", errors.New("invalid name")
	}
	records, err:= nk.StorageRead(ctx, []*runtime.StorageRead {{
		Collection: STORAGE_ACTOR_TAG_INDEX,
		Key: name,
	}})
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": name,
		}).Error("storage read tag index")
		return Tag{}, "*", errors.New("storage read tag index failed")
	}
	if len(records) <= 0 {
		// Unknown key, return a new tag index at max value
		rng := rand.New(rand.NewSource(time.Now().UnixNano()))
		half := MAX_TAG_VALUE >> 1
		value := half + uint16(rng.Int31n(int32(half)))
		return Tag{ Value: value, Name: name }, "*", nil
	}
	var result Index 
	if err := json.Unmarshal([]byte(records[0].Value), &result); err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": name,
			"data": records[0].Value,
		}).Error("unmarshal tag index")
		return Tag{}, "*", errors.New("unmarshal tag index failed")
	}
	if result.Value == 0 || result.Value > uint32(MAX_TAG_VALUE) {
		return Tag{}, "*", errors.New("no more valid tags available")
	}
	return Tag{Value: uint16(result.Value), Name: name}, "*", errors.New("err")		
}

// write the current actor tag index, a tag index keeps track of the current id for an specified name
func _write_actor_tag_index(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, index Tag, version string) error {
	if index.Value <= 0 {
		logger.WithFields(map[string]interface{}{
			"key": index.Name,
		}).Error("out of tag values")
		return errors.New("out of tag values")
	}
	if len(index.Name) > MAX_NAME_LENGHT {
		logger.WithFields(map[string]interface{}{
			"key": index.Name,
		}).Error("invalid name length")
		return errors.New("invalid name length")
	}
	if strings.Contains(index.Name, "#") {
		logger.WithFields(map[string]interface{}{
			"key": index.Name,
		}).Error("invalid name")
		return errors.New("invalid name")
	}
	data, err := json.Marshal(Index{Value: uint32(index.Value)})
	if err != nil {
		logger.WithField("err", err).Error("json marshal tag index")
		return errors.New("failed encode tag index data")
	}
	_, err = nk.StorageWrite(ctx, []*runtime.StorageWrite {{
		Collection: STORAGE_ACTOR_TAG_INDEX,
		Key: index.Name,
		Value: string(data),
		Version: version,
		PermissionRead: 2,
		PermissionWrite: 0,
	}})
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"data": data,
		}).Error("storage write tag index")
		return errors.New("storage write tag index failed")
	}
	return nil		
}


// read the current actor token index from nakama storage, this index keeps track of the current id for an specified origin
func _read_actor_token_index(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, origin string) (Id, string, error) {
	var sector sector.Id
	if err := sector.FromKey(origin); nil != err {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": origin,
		}).Error("invalid origin")
		return Id{}, "*", errors.New("invalid origin")		
	}
	records, err:= nk.StorageRead(ctx, []*runtime.StorageRead {{
		Collection: STORAGE_ACTOR_TOKEN_INDEX,
		Key: sector.Key(),
	}})
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": sector.Key(),
		}).Error("storage read token index")
		return Id{}, "*", errors.New("storage read token index failed")
	}
	if len(records) <= 0 {
		// Unknown key, return a new token index at max value
		rng := rand.New(rand.NewSource(time.Now().UnixNano()))
		half := MAX_ID_VALUE >> 1
		value := half + uint32(rng.Int31n(int32(half)))
		return Id{Value: value, Sector: sector}, "*", nil
	}
	var result Index 
	if err := json.Unmarshal([]byte(records[0].Value), &result); err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": sector.Key(),
			"data": records[0].Value,
		}).Error("unmarshal token index")
		return Id{}, "*", errors.New("unmarshal token index failed")
	}
	if result.Value == 0 || result.Value > MAX_ID_VALUE {
		return Id{}, "*", errors.New("no more valid ids available")
	}
	// Valid, return id and the current version
	return Id{Value: uint32(result.Value), Sector: sector}, records[0].Version, nil
}

// write the current actor token index from nakama storage, this index keeps track of the current id for an specified origin
func _write_actor_token_index(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, index Id, version string) error {
	data, err := json.Marshal(Index{Value: index.Value})
	if err != nil {
		logger.WithField("err", err).Error("json marshal token index")
		return errors.New("failed encode token index data")
	}
	_, err = nk.StorageWrite(ctx, []*runtime.StorageWrite {{
		Collection: STORAGE_ACTOR_TOKEN_INDEX,
		Key: index.Sector.Key(),
		Value: string(data),
		Version: version,
		PermissionRead: 2,
		PermissionWrite: 0,
	}})
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"data": data,
		}).Error("storage write token index")
		return errors.New("storage write token index failed")
	}
	return nil
}


func _has_actor_meta(ctx context.Context, nk runtime.NakamaModule, key string) (int, error) {
	records, err:= nk.StorageRead(ctx, []*runtime.StorageRead {{
		Collection: STORAGE_ACTOR_META,
		Key: key,
	}})
	if err != nil {
		return -1, errors.New("read storage actor meta failed")
	}
	return len(records), nil
}

func _read_actor_meta(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, user_id string, key string) (*Meta, string, string, error) {
	records, err:= nk.StorageRead(ctx, []*runtime.StorageRead {{
		Collection: STORAGE_ACTOR_META,
		UserID: user_id,
		Key:  key,
	}})
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": key,
		}).Error("read storage reserved actor id")
		return nil, "", "*", errors.New("read storage reserved actor id failed")
	}
	if len(records) <= 0 {
		// Unknown key
		return nil, "", "*", nil
	}
	result := &Meta{}
	if err := json.Unmarshal([]byte(records[0].Value), result); err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": key,
			"data": records[0].Value,
		}).Error("unmarshal reserved actor id")
		return nil, "", "*", errors.New("unmarshal reserved actor id failed")
	}
	return result, records[0].UserId, records[0].Version, nil
}

func _write_actor_meta(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, user_id string, version string, key string, metadata *Meta) (string, error) {
	data, err := json.Marshal(metadata)
	if err != nil {
		logger.WithField("err", err).Error("marshal metadata")
		return "", errors.New("marshal metadata failed")
	}
	ack, err := nk.StorageWrite(ctx, []*runtime.StorageWrite {{
		Collection: STORAGE_ACTOR_META,
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
			"data": data,
		}).Error("storage write actor meta")
		return "", errors.New("storage write actor meta failed")
	}
	if len(ack) != 1 {
		logger.WithFields(map[string]interface{}{
			"msg": "invalid ack",
			"len": len(ack),
			"data": data,
		}).Error("ack storage write actor meta")
		return "", errors.New("ack storage write actor meta failed")
	}
	return ack[0].Version, nil
}

func _delete_actor_meta(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, user_id string, key string, version string) error {
	err := nk.StorageDelete(ctx, []*runtime.StorageDelete {{
		Collection: STORAGE_ACTOR_META,
		Version: version,
		UserID: user_id,
		Key: key,
	}})
	if err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": key,
		}).Error("delete actor meta")
		return errors.New("delete actor meta")
	}
	return nil
}