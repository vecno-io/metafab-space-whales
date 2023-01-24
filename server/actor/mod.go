package actor

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"reflect"
	"strconv"
	"strings"

	"github.com/heroiclabs/nakama-common/runtime"
	"github.com/vecno-io/metafab-space-whales/server/sector"
)

const MAX_ID_VALUE = 4294967295
const MAX_TAG_VALUE = 65535
const MAX_NAME_LENGHT = 24

const STORAGE_ACTOR_ITEM = "ACTOR_ITEM"

const STORAGE_ACTOR_TAG_INDEX = "ACTOR_TAG_INDEX"
const STORAGE_ACTOR_TOKEN_INDEX = "ACTOR_TOKEN_INDEX"


type idx struct {
	Value uint64 `json:"value"`
}


type Id struct {
	Value uint32 `json:"value"`
	Origin sector.Id `json:"origin"`
}

func(id *Id) Key() string {
	return fmt.Sprintf(
		"%s|%010d", id.Origin.Key(), id.Value,
	)
}

func(id *Id) MarshalJSON() ([]byte, error) {
	return json.Marshal(id.Key())
}

func(id *Id) UnmarshalJSON(val []byte) error {
	var str string
	if err := json.Unmarshal(val, &str); err != nil {
		return &json.UnsupportedValueError{
			Value: reflect.ValueOf(id),
			Str: string(val),
		}
	}
	list := strings.Split(string(str), "|")
	if len(list) != 2 {
		return &json.UnsupportedValueError{
			Value: reflect.ValueOf(id),
			Str: string(str),
		}
	}
	var origin sector.Id
	str = fmt.Sprintf("\"%s\"", list[0])
	if err := origin.UnmarshalJSON([]byte(str)); nil != err {
		return errors.New("unmarshal: invalid origin")
	}
	index, err := strconv.ParseUint(list[1], 10, 32)
	if err != nil {
		return errors.New("unmarshal: invalid index")
	}
	id.Value = uint32(index)
	id.Origin = origin
	return nil
}


type Tag struct {
	Value uint16 `json:"value"`
	Name string `json:"name"`
}

func(tag *Tag) Key() string {
	return fmt.Sprintf(
		"%s#%05d", tag.Name, tag.Value,
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
		return Tag{ Value: MAX_TAG_VALUE, Name: name }, "*", nil
	}
	var result idx 
	if err := json.Unmarshal([]byte(records[0].Value), &result); err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": name,
			"data": records[0].Value,
		}).Error("unmarshal tag index")
		return Tag{}, "*", errors.New("unmarshal tag index failed")
	}
	value := uint16(result.Value)
	if result.Value > MAX_TAG_VALUE {
		value = MAX_TAG_VALUE
	}
	return Tag{Value: value, Name: name}, "*", errors.New("err")		
}

// write the current actor tag index, a tag index keeps track of the current id for an specified name
func _write_actor_tag_index(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, index Tag, version string) error {
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
	data, err := json.Marshal(idx{Value: uint64(index.Value)})
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
	if err := sector.UnmarshalJSON([]byte(origin)); nil != err {
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
		return Id{Value: MAX_ID_VALUE, Origin: sector}, "*", nil
	}
	var result idx 
	if err := json.Unmarshal([]byte(records[0].Value), &result); err != nil {
		logger.WithFields(map[string]interface{}{
			"err": err,
			"key": sector.Key(),
			"data": records[0].Value,
		}).Error("unmarshal token index")
		return Id{}, "*", errors.New("unmarshal token index failed")
	}
	value := uint32(result.Value)
	if result.Value > MAX_ID_VALUE {
		value = MAX_ID_VALUE
	}
	// Valid, return id and the current version
	return Id{Value: value, Origin: sector}, records[0].Version, nil
}

// write the current actor token index from nakama storage, this index keeps track of the current id for an specified origin
func _write_actor_token_index(ctx context.Context, logger runtime.Logger, nk runtime.NakamaModule, index Id, version string) error {
	data, err := json.Marshal(idx{Value: uint64(index.Value)})
	if err != nil {
		logger.WithField("err", err).Error("json marshal token index")
		return errors.New("failed encode token index data")
	}
	_, err = nk.StorageWrite(ctx, []*runtime.StorageWrite {{
		Collection: STORAGE_ACTOR_TOKEN_INDEX,
		Key: index.Origin.Key(),
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
