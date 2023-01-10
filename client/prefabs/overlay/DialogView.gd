extends Control


onready var dust_storage = get_node("%DustStorage")
onready var dust_inventory = get_node("%DustInventory")
onready var speed_cost = get_node("%SpeedCost")
onready var speed_craft = get_node("%SpeedCraft")
onready var speed_storage = get_node("%SpeedStorage")
onready var speed_inventory = get_node("%SpeedInventory")
onready var firerate_cost = get_node("%FirerateCost")
onready var firerate_craft = get_node("%FirerateCraft")
onready var firerate_storage = get_node("%FirerateStorage")
onready var firerate_inventory = get_node("%FirerateInventory")

onready var speed_craft_btn = get_node("%SpeedCraftBtn")
onready var speed_refine_btn = get_node("%SpeedRefineBtn")
onready var firerate_craft_btn = get_node("%FirerateCraftBtn")
onready var firerate_refine_btn = get_node("%FirerateRefineBtn")


func _ready():
	dust_storage.text = "%06d" % Global.dust_storage
	dust_inventory.text = "%06d" % Global.dust_inventory
	speed_cost.text = "%d" % Global.speed_cost
	speed_craft.text = "%04d" % Global.speed_storage
	speed_storage.text = "%04d" % Global.speed_storage
	speed_inventory.text = "%02d/08" % Global.speed_inventory
	speed_craft_btn.disabled = Global.speed_cost <= Global.speed_storage
	speed_refine_btn.disabled = 0 >= Global.speed_storage
	firerate_cost.text = "%d" % Global.firerate_cost
	firerate_craft.text = "%04d" % Global.firerate_storage
	firerate_storage.text = "%04d" % Global.firerate_storage
	firerate_inventory.text = "%02d/08" % Global.firerate_inventory
	firerate_craft_btn.disabled = 	Global.firerate_cost <= Global.firerate_storage
	firerate_refine_btn.disabled = 0 >= Global.firerate_storage
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
	Global.disconnect("dust_storage_updated", self, "_on_dust_storage_updated")
	Global.disconnect("dust_inventory_updated", self, "_on_dust_inventory_updated")
	Global.disconnect("speed_storage_updated", self, "_on_speed_storage_updated")
	Global.disconnect("speed_inventory_updated", self, "_on_speed_inventory_updated")
	Global.disconnect("firerate_storage_updated", self, "_on_firerate_storage_updated")
	Global.disconnect("firerate_inventory_updated", self, "_on_firerate_inventory_updated")


func _on_dust_storage_updated(value):
	if value < 0: value = 0
	dust_storage.text = "%06d" % value
	speed_craft_btn.disabled = Global.speed_cost > value
	firerate_craft_btn.disabled = 	Global.firerate_cost > value


func _on_dust_inventory_updated(value):
	if value < 0: value = 0
	dust_inventory.text = "%06d" % value


func _on_speed_storage_updated(value):
	if value < 0: value = 0
	speed_craft.text = "%04d" % value
	speed_storage.text = "%04d" % value
	speed_refine_btn.disabled = 0 >= value


func _on_speed_inventory_updated(value):
	if value < 0: value = 0
	speed_inventory.text = "%02d/08" % value


func _on_firerate_storage_updated(value):
	if value < 0: value = 0
	firerate_craft.text = "%04d" % value
	firerate_storage.text = "%04d" % value
	firerate_refine_btn.disabled = 0 >= value


func _on_firerate_inventory_updated(value):
	if value < 0: value = 0
	firerate_inventory.text = "%02d/08" % value


func _on_take_dust():
	if 100 > Global.dust_storage:
		return
	Global.dust_storage -= 100
	Global.dust_inventory += 100


func _on_store_dust():
	if 100 > Global.dust_inventory:
		return
	Global.dust_storage += 100
	Global.dust_inventory -= 100


func _on_take_speed_boost():
	if 1 > Global.speed_storage:
		return
	Global.speed_storage -= 1
	Global.speed_inventory += 1


func _on_store_speed_boost():
	if 1 > Global.speed_inventory:
		return
	Global.speed_storage += 1
	Global.speed_inventory -= 1


func _on_craft_speed_boost():
	if Global.speed_cost > Global.dust_storage:
		return
	Global.dust_storage -= Global.speed_cost
	Global.speed_storage += 1


func _on_refine_speed_boost():
	if 1 > Global.speed_storage:
		return
	Global.dust_storage += int(Global.speed_cost * 0.8)
	Global.speed_storage -= 1


func _on_take_firerate_boost():
	if 1 > Global.firerate_storage:
		return
	Global.firerate_storage -= 1
	Global.firerate_inventory += 1


func _on_store_firerate_boost():
	if 1 > Global.firerate_inventory:
		return
	Global.firerate_storage += 1
	Global.firerate_inventory -= 1


func _on_craft_firerate_boost():
	if Global.firerate_cost > Global.dust_storage:
		return
	Global.dust_storage -= Global.firerate_cost
	Global.firerate_storage += 1


func _on_refine_firerate_boost():
	if 1 > Global.firerate_storage:
		return
	Global.dust_storage += int(Global.firerate_cost * 0.8)
	Global.firerate_storage -= 1
