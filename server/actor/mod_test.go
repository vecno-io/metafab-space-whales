package actor

import (
	"testing"

	"github.com/vecno-io/metafab-space-whales/server/sector"
)

func TestIdKey(t *testing.T) {
	id := Id{
		Value: 7,
		Origin: sector.NewId(1, 2, 3, 4, 5, 6),
	}
	key := id.Key()
	res := "001:002:003:004:00005:00006|0000000007"
	if key != res {
		t.Errorf("id.Key() = %s; want %s", key, res)
	}
}

func TestIdMarshalJSON(t *testing.T) {
	id := Id{
		Value: 7,
		Origin: sector.NewId(1, 2, 3, 4, 5, 6),
	}
	val, err := id.MarshalJSON()
	if nil != err {
		t.Errorf("tag.MarshalJSON() got error: %s; want nil", err)
	}
	res := []byte("\"001:002:003:004:00005:00006|0000000007\"")
	if len(val) != len(res) {
		t.Errorf("tag.MarshalJSON() invalid len: %d; want %d", len(val), len(res))
	}
	if string(val) != string(res) {
		t.Errorf("tag.MarshalJSON() = %s; want %s", string(val), string(res))
	}
}

func TestIdUnmarshalJSON(t *testing.T) {
	id := Id{}
	err := id.UnmarshalJSON([]byte("\"001:002:003:004:00005:00006|0000000007\""))
	if nil != err {
		t.Errorf("id.UnmarshalJSON() got error: %s; want nil", err)
	}
	res := Id{
		Value: 7,
		Origin: sector.NewId(1, 2, 3, 4, 5, 6),
	}
	if id.Value != res.Value {
		t.Errorf("id.UnmarshalJSON() Value = %d; want %d", id.Value, res.Value)
	}
	if id.Origin != res.Origin {
		t.Errorf("id.UnmarshalJSON() Origin = %d; want %d", id.Origin, res.Origin)
	}
}


func TestTagKey(t *testing.T) {
	tag := Tag{
		Value: 420,
		Name: "Name",
	}
	key := tag.Key()
	res := "Name#00420"
	if key != res {
		t.Errorf("tag.Key() = %s; want %s", key, res)
	}
}

func TestTagMarshalJSON(t *testing.T) {
	tag := Tag{
		Value: 420,
		Name: "Name",
	}
	val, err := tag.MarshalJSON()
	if nil != err {
		t.Errorf("tag.MarshalJSON() got error: %s; want nil", err)
	}
	res := []byte("\"Name#00420\"")
	if len(val) != len(res) {
		t.Errorf("tag.MarshalJSON() invalid len: %d; want %d", len(val), len(res))
	}
	if string(val) != string(res) {
		t.Errorf("tag.MarshalJSON() = %s; want %s", string(val), string(res))
	}
}

func TestTagUnmarshalJSON(t *testing.T) {
	tag := Tag{}
	err := tag.UnmarshalJSON([]byte("\"Name#00420\""))
	if nil != err {
		t.Errorf("id.UnmarshalJSON() got error: %s; want nil", err)
	}
	res := Tag{
		Value: 420,
		Name: "Name",
	}
	if tag.Value != res.Value {
		t.Errorf("id.UnmarshalJSON() Value = %d; want %d", tag.Value, res.Value)
	}
	if tag.Name != res.Name {
		t.Errorf("id.UnmarshalJSON() Name = %s; want %s", tag.Name, res.Name)
	}
}