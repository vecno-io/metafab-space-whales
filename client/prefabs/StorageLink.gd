extends Sprite


signal link_opened
signal link_closed

const DUST_TRANSFER = 600

onready var overlay = get_node("%Overlay")

var loading_dust = false
var loading_speed = false
var loading_attack = false

onready var dust_take = get_node("%DustTakeBtn")
onready var dust_store = get_node("%DustStoreBtn")
onready var dust_storage = get_node("%DustStorage")
onready var dust_inventory = get_node("%DustInventory")

onready var speed_take = get_node("%SpeedTakeBtn")
onready var speed_store = get_node("%SpeedStoreBtn")
onready var speed_storage = get_node("%SpeedStorage")
onready var speed_inventory = get_node("%SpeedInventory")

onready var firerate_take = get_node("%FirerateTakeBtn")
onready var firerate_store = get_node("%FirerateStoreBtn")
onready var firerate_storage = get_node("%FirerateStorage")
onready var firerate_inventory = get_node("%FirerateInventory")


func _ready():
	overlay.hide()
	Global.local_store = self
	dust_take.disabled = Global.dust_storage < DUST_TRANSFER
	dust_store.disabled = Global.dust_inventory < DUST_TRANSFER
	dust_storage.text = "%06d" % Global.dust_storage
	dust_inventory.text = "%06d" % Global.dust_inventory
	speed_take.disabled = Global.speed_storage == 0
	speed_store.disabled = Global.speed_inventory == 0
	speed_storage.text = "%04d" % Global.speed_storage
	speed_inventory.text = "%02d/08" % Global.speed_inventory
	firerate_take.disabled = Global.firerate_storage == 0
	firerate_store.disabled = Global.firerate_inventory == 0
	firerate_storage.text = "%04d" % Global.firerate_storage
	firerate_inventory.text = "%02d/08" % Global.firerate_inventory
	#warning-ignore: return_value_discarded
	Global.connect("color_updated", self, "_on_color_updated")
	#warning-ignore: return_value_discarded
	Global.connect("dust_storage_updated", self, "_on_dust_storage_updated")
	#warning-ignore: return_value_discarded
	Global.connect("dust_inventory_updated", self, "_on_dust_inventory_updated")
	#warning-ignore: return_value_discarded
	Global.connect("speed_storage_updated", self, "_on_speed_storage_updated")
	#warning-ignore: return_value_discarded
	Global.connect("speed_inventory_updated", self, "_on_speed_inventory_updated")
	#warning-ignore: return_value_discarded
	Global.connect("firerate_storage_updated", self, "_on_firerate_storage_updated")
	#warning-ignore: return_value_discarded
	Global.connect("firerate_inventory_updated", self, "_on_firerate_inventory_updated")


func _exit_tree():
	Global.disconnect("color_updated", self, "_on_color_updated")
	Global.disconnect("dust_storage_updated", self, "_on_dust_storage_updated")
	Global.disconnect("dust_inventory_updated", self, "_on_dust_inventory_updated")
	Global.disconnect("speed_storage_updated", self, "_on_speed_storage_updated")
	Global.disconnect("speed_inventory_updated", self, "_on_speed_inventory_updated")
	Global.disconnect("firerate_storage_updated", self, "_on_firerate_storage_updated")
	Global.disconnect("firerate_inventory_updated", self, "_on_firerate_inventory_updated")


func _unhandled_input(event: InputEvent):
	if !overlay.visible:
		return
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_TAB:
			get_tree().set_input_as_handled()
			_hide_storage()


func _on_link_area_exited(area: Area2D):
	if area.is_in_group("player"):
		_hide_storage()


func _on_link_area_entered(area: Area2D):
	if area.is_in_group("player"):
		_show_storage()


func _show_storage():
	if !GameServer.has_user():
		return
	# TODO Only show if actor registered
	overlay.show()
	Global.can_jump = false
	emit_signal("link_opened")


func _hide_storage():
	overlay.hide()
	Global.can_jump = true
	emit_signal("link_closed")


func _on_close_pressed():
	_hide_storage()


func _on_take_dust():
	if Global.dust_storage < DUST_TRANSFER:
		return
	if loading_dust:
		return
	loading_dust = true
	dust_take.disabled = true
	dust_store.disabled = true
	yield(GameServer.actor.take_coin(
		"DUST",
		Global.dust_storage - DUST_TRANSFER,
		Global.dust_inventory + DUST_TRANSFER
	), "completed")
	Global.dust_storage -= DUST_TRANSFER
	Global.dust_inventory += DUST_TRANSFER
	loading_dust = false


func _on_store_dust():
	if Global.dust_inventory < DUST_TRANSFER:
		return
	if loading_dust:
		return
	loading_dust = true
	dust_take.disabled = true
	dust_store.disabled = true
	yield(GameServer.actor.store_coin(
		"DUST",
		Global.dust_storage + DUST_TRANSFER,
		Global.dust_inventory - DUST_TRANSFER
	), "completed")
	Global.dust_storage += DUST_TRANSFER
	Global.dust_inventory -= DUST_TRANSFER
	loading_dust = false


func _on_take_speed():
	if Global.speed_storage == 0:
		return
	if loading_speed:
		return
	loading_speed = true
	speed_take.disabled = true
	speed_store.disabled = true
	yield(GameServer.actor.take_booster(
		"SPEED",
		Global.speed_storage - 1,
		Global.speed_inventory + 1
	), "completed")
	Global.speed_storage -= 1
	Global.speed_inventory += 1
	loading_speed = false


func _on_store_speed():
	if Global.speed_inventory == 0:
		return
	if loading_speed:
		return
	loading_speed = true
	speed_take.disabled = true
	speed_store.disabled = true
	yield(GameServer.actor.store_booster(
		"SPEED",
		Global.speed_storage + 1,
		Global.speed_inventory - 1
	), "completed")
	Global.speed_storage += 1
	Global.speed_inventory -= 1
	loading_speed = false


func _on_take_firerate():
	if Global.firerate_storage == 0:
		return
	if loading_attack:
		return
	loading_attack = true
	firerate_take.disabled = true
	firerate_store.disabled = true
	yield(GameServer.actor.take_booster(
		"ATTACK",
		Global.firerate_storage - 1 ,
		Global.firerate_inventory + 1
	), "completed")
	Global.firerate_storage -= 1
	Global.firerate_inventory += 1
	loading_attack = false


func _on_store_firerate():
	if Global.firerate_inventory == 0:
		return
	if loading_attack:
		return
	loading_attack = true
	firerate_take.disabled = true
	firerate_store.disabled = true
	yield(GameServer.actor.store_booster(
		"ATTACK",
		Global.firerate_storage + 1,
		Global.firerate_inventory - 1
	), "completed")
	Global.firerate_storage += 1
	Global.firerate_inventory -= 1
	loading_attack = false


func _on_color_updated(value):
	var light = get_node("Light2D")
	light.color = value


func _on_dust_storage_updated(value):
	if value < 0: value = 0
	dust_storage.text = "%06d" % value
	dust_take.disabled = value < DUST_TRANSFER


func _on_dust_inventory_updated(value):
	if value < 0: value = 0
	dust_inventory.text = "%06d" % value
	dust_store.disabled = value < DUST_TRANSFER


func _on_speed_storage_updated(value):
	if value < 0: value = 0
	speed_storage.text = "%04d" % value
	speed_take.disabled = 0 == value


func _on_speed_inventory_updated(value):
	if value < 0: value = 0
	speed_inventory.text = "%02d/04" % value
	speed_store.disabled = 0 == value


func _on_firerate_storage_updated(value):
	if value < 0: value = 0
	firerate_storage.text = "%04d" % value
	firerate_take.disabled = 0 == value


func _on_firerate_inventory_updated(value):
	if value < 0: value = 0
	firerate_inventory.text = "%02d/04" % value
	firerate_store.disabled = 0 == value
