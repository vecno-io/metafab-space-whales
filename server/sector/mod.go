package sector

import (
	"encoding/json"
	"errors"
	"fmt"
	"reflect"
	"strconv"
	"strings"
)

type Id uint64

func NewId(version uint8, typed uint8, root_x uint8, root_y uint8, pos_x uint16, pos_y uint16) Id {
	id := uint64(version)
	id += uint64(typed)  << 8
	id += uint64(root_x) << 16
	id += uint64(root_y) << 24
	id += uint64(pos_x)  << 32
	id += uint64(pos_y)  << 48
	return Id(id)
}

func(id Id) Key() string {
	root_x, root_y := id.Root() 
	pos_x, pos_y := id.Possition()
	return fmt.Sprintf(
		"%03d:%03d:%03d:%03d:%05d:%05d",
		id.Version(), id.Type(),
		root_x, root_y,
		pos_x, pos_y,
	)
}

func(id Id) Type() uint8 {
	// First 16 bits, skip 8 version bits
	return uint8((id >> 8) & 0xff)
}

func(id Id) Version() uint8 {
	// First 16 bits, drop 8 type bits
	return uint8(id & 0xff)
}

func(id Id) Root() (uint8, uint8) {
	// Second 16 bits, split in xy coords
	root := (id >> 16) & 0xffff
	return uint8(root & 0xff), uint8((root >> 8) & 0xff)  
}

func(id Id) Possition() (uint16, uint16) {
	// Third and Fourth 16 bits, split in xy coords
	return uint16((id >> 32) & 0xffff), uint16((id >> 48) & 0xffff)  
}


func(id Id) MarshalJSON() ([]byte, error) {
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
	list := strings.Split(string(str), ":")
	if len(list) != 6 {
		return &json.UnsupportedValueError{
			Value: reflect.ValueOf(id),
			Str: string(str),
		}
	}
	version, err := strconv.ParseUint(list[0], 10, 8)
	if err != nil {
		return errors.New("unmarshal: invalid version")
	}
	typed, err := strconv.ParseUint(list[1], 10, 8)
	if err != nil {
		return errors.New("unmarshal: invalid type")
	}
	root_x, err := strconv.ParseUint(list[2], 10, 16)
	if err != nil {
		return errors.New("unmarshal: invalid y root")
	}
	root_y, err := strconv.ParseUint(list[3], 10, 16)
	if err != nil {
		return errors.New("unmarshal: invalid y root")
	}
	pos_x, err := strconv.ParseUint(list[4], 10, 8)
	if err != nil {
		return errors.New("unmarshal: invalid x position")
	}
	pos_y, err := strconv.ParseUint(list[5], 10, 8)
	if err != nil {
		return errors.New("unmarshal: invalid y position")
	}
	*id = NewId(
		uint8(version), uint8(typed), 
		uint8(root_x), uint8(root_y), 
		uint16(pos_x), uint16(pos_y),
	)
	return nil
}
