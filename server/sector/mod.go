package sector

import (
	"encoding/json"
	"errors"
	"fmt"
	"reflect"
	"strconv"
	"strings"
)

const CURRENT_VERSION = 1
const MAX_SECTOR_SLOTS = 32

const STORAGE_SECTOR_RESERVED_ID = "SECTOR_RESERVED_ID"

type Id uint64

func NewId(version uint8, kind uint8, org_x uint8, org_y uint8, pos_x uint16, pos_y uint16) Id {
	id := uint64(version)
	id += uint64(kind)  << 8
	id += uint64(org_x) << 16
	id += uint64(org_y) << 24
	id += uint64(pos_x)  << 32
	id += uint64(pos_y)  << 48
	return Id(id)
}

func(id *Id) Key() string {
	org_x, org_y := id.Origin() 
	pos_x, pos_y := id.Possition()
	return fmt.Sprintf(
		"%03d:%03d:%03d:%03d:%05d:%05d",
		id.Version(), id.Kind(),
		org_x, org_y, pos_x, pos_y,
	)
}

func(id *Id) Number() string {
	org_x, org_y := id.Origin() 
	pos_x, pos_y := id.Possition()
	return fmt.Sprintf(
		"%d%03d%03d%03d%05d%05d",
		id.Version(), id.Kind(),
		org_x, org_y, pos_x, pos_y,
	)
}

func(id Id) Kind() uint8 {
	// First 16 bits, skip 8 version bits
	return uint8((id >> 8) & 0xff)
}

func(id Id) Version() uint8 {
	// First 16 bits, drop 8 type bits
	return uint8(id & 0xff)
}

func(id Id) Origin() (uint8, uint8) {
	// Second 16 bits, split in xy coords
	root := (id >> 16) & 0xffff
	return uint8(root & 0xff), uint8((root >> 8) & 0xff)  
}

func(id Id) Possition() (uint16, uint16) {
	// Third and Fourth 16 bits, split in xy coords
	return uint16((id >> 32) & 0xffff), uint16((id >> 48) & 0xffff)  
}

func(id *Id) FromKey(val string) error {
	list := strings.Split(string(val), ":")
	if len(list) != 6 {
		return &json.UnsupportedValueError{
			Value: reflect.ValueOf(id),
			Str: string(val),
		}
	}
	ver, err := strconv.ParseUint(list[0], 10, 8)
	if err != nil {
		return errors.New("decode: invalid version")
	}
	kind, err := strconv.ParseUint(list[1], 10, 8)
	if err != nil {
		return errors.New("decode: invalid kind")
	}
	org_x, err := strconv.ParseUint(list[2], 10, 8)
	if err != nil {
		return errors.New("decode: invalid y origin")
	}
	org_y, err := strconv.ParseUint(list[3], 10, 8)
	if err != nil {
		return errors.New("decode: invalid y origin")
	}
	pos_x, err := strconv.ParseUint(list[4], 10, 16)
	if err != nil {
		return errors.New("decode: invalid x position")
	}
	pos_y, err := strconv.ParseUint(list[5], 10, 16)
	if err != nil {
		return errors.New("decode: invalid y position")
	}
	*id = NewId(
		uint8(ver), uint8(kind), 
		uint8(org_x), uint8(org_y), 
		uint16(pos_x), uint16(pos_y),
	)
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


type Origin uint16

// X returns the x position for the origin
func(org Origin) X() uint8 {
	return uint8(org & 0xff)
}

// Y returns the y position for the origin
func(org Origin) Y() uint8 {
	return uint8((org >> 8) & 0xff)
}

// Split returns the x, y positions for the origin
func(org Origin) Split() (uint8, uint8) {
	return uint8(org & 0xff), uint8((org >> 8) & 0xff)
}


type Position uint32

// X returns the x value for the position
func(pos Position) X() uint16 {
	return uint16(pos & 0xffff)
}

// Y returns the y value for the position
func(pos Position) Y() uint16 {
	return uint16((pos >> 8) & 0xffff)
}

// Split returns the x, y value for the position
func(pos Position) Split() (uint16, uint16) {
	return uint16(pos & 0xffff), uint16((pos >> 8) & 0xffff)
}
