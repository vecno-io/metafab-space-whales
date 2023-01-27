package sector

import "testing"

func TestNewId(t *testing.T) {
	id := NewId(1, 2, 3, 4, 5, 6)
	if id != Id(1688871402406401) {
		t.Errorf("NewId(1, 2, 3, 4, 5, 6) = %d; want 1688871402406401", id)
	}
}

func TestIdKey(t *testing.T) {
	id := NewId(1, 2, 3, 4, 5, 6)
	key := id.Key()
	if key != "001:002:003:004:00005:00006" {
		t.Errorf("id.Key() = %s; want 001:002:003:004:00005:00006", key)
	}
}

func TestIdType(t *testing.T) {
	id := NewId(1, 2, 3, 4, 5, 6)
	val := id.Kind()
	if val != 2 {
		t.Errorf("id.Type() = %d; want 2", val)
	}
}

func TestIdVersion(t *testing.T) {
	id := NewId(1, 2, 3, 4, 5, 6)
	val := id.Version()
	if val != 1 {
		t.Errorf("id.Version() = %d; want 1", val)
	}
}

func TestIdRoot(t *testing.T) {
	id := NewId(1, 2, 3, 4, 5, 6)
	val_X, val_y := id.Origin()
	if val_X != 3 || val_y != 4 {
		t.Errorf("id.Root() = %d, %d; want 3, 4", val_X, val_y)
	}
}

func TestIdPosition(t *testing.T) {
	id := NewId(1, 2, 3, 4, 5, 6)
	val_X, val_y := id.Possition()
	if val_X != 5 || val_y != 6 {
		t.Errorf("id.Possition() = %d, %d; want 5, 6", val_X, val_y)
	}
}

func TestIdMarshalJSON(t *testing.T) {
	id := NewId(1, 2, 3, 4, 5, 6)
	val, err := id.MarshalJSON()
	if nil != err {
		t.Errorf("id.MarshalJSON() got error: %s; want nil", err)
	}
	res := []byte("\"001:002:003:004:00005:00006\"")
	if len(val) != len(res) {
		t.Errorf("id.MarshalJSON() invalid len: %d; want %d", len(val), len(res))
	}
	if string(val) != string(res) {
		t.Errorf("id.MarshalJSON() = %s; want %s", string(val), string(res))
	}
}

func TestIdUnmarshalJSON(t *testing.T) {
	id := Id(0)
	err := id.UnmarshalJSON([]byte("\"001:002:003:004:00005:00006\""))
	if nil != err {
		t.Errorf("id.UnmarshalJSON() got error: %s; want nil", err)
	}
	res := NewId(1, 2, 3, 4, 5, 6)
	if id != res {
		// could also test on: want 1688871402406401
		t.Errorf("id.UnmarshalJSON() = %d; want %d", id, res)
	}
}
