class_name MetaConfig
extends Reference


const KEY_GAME_ID = "game_id"
const KEY_PUBLIC_KEY = "public_key"
const KEY_WALLET_GAME = "game_wallet"
const KEY_WALLET_FUNDING = "funding_wallet"
const KEY_CURRENCY_DUST = "dust_currency"
const KEY_COLLECTION_WHALES = "whales_collection"
const KEY_COLLECTION_SECTORS = "sectors_collection"
const KEY_COLLECTION_BOOSTERS = "boosters_collection"


var game_id: String
var public_key: String
var wallet_game: String
var wallet_funding: String
var currency_dust: String
var collection_actors: String
var collection_sectors: String
var collection_boosters: String


func is_valid() -> bool:
	if game_id.empty():
		return false
	if public_key.empty():
		return false
	if wallet_game.empty():
		return false
	if wallet_funding.empty():
		return false
	if currency_dust.empty():
		return false
	if collection_actors.empty():
		return false
	if collection_sectors.empty():
		return false
	if collection_boosters.empty():
		return false
	return true


func from_result(data: Dictionary) -> int:
	if data == null: return -1
	if !data.has_all([
		KEY_GAME_ID,
		KEY_PUBLIC_KEY,
		KEY_WALLET_GAME,
		KEY_WALLET_FUNDING,
		KEY_CURRENCY_DUST,
		KEY_COLLECTION_WHALES,
		KEY_COLLECTION_SECTORS ,
		KEY_COLLECTION_BOOSTERS,
	]): return -2
	game_id = data[KEY_GAME_ID]
	public_key = data[KEY_PUBLIC_KEY]
	wallet_game = data[KEY_WALLET_GAME]
	wallet_funding = data[KEY_WALLET_FUNDING]
	currency_dust = data[KEY_CURRENCY_DUST]
	collection_actors = data[KEY_COLLECTION_WHALES]
	collection_sectors = data[KEY_COLLECTION_SECTORS]
	collection_boosters = data[KEY_COLLECTION_BOOSTERS]
	if !is_valid(): 
		return -3
	return OK
