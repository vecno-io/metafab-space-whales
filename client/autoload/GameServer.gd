extends Node

signal signed_in
signal signed_out

signal session_closed
signal session_created


# Note: Set key and domain before build
const SERVER_KEY = "Client-Key-420-1337"
const SERVER_DOMAIN = "%s%s.game-server.test"


var _client: NakamaClient = null setget _no_set
var _account: ServerAccount = null setget _no_set
var _exception: ServerException = null setget _no_set


func _init() -> void:
	# Configure the servers client
	_exception = ServerException.new()
	if ConfigWorker.get_server_localhost():
		print("[Game.Server] Using: localhost")
		_server_setup("127.0.0.1")
		return
	var region = ConfigWorker.get_server_region()
	var network = ConfigWorker.get_server_network()
	var address = SERVER_DOMAIN % [ region, network ]
	print("[Game.Server] Using: %s" % address)
	_server_setup(address)


func _ready():
	# TODO If user: auth user else:
	_account.authenticate_device()


func _no_set(_value) -> void:
	push_error("[Game.Server] no set")


func _server_setup(address: String):
	# Create the Client, Account, and Storage; connect all signals
	_client = Nakama.create_client(SERVER_KEY, address, 7350, "http", 12)
	_client.auto_retry = false
	_account = ServerAccount.new(_client, _exception)
	#warning-ignore: return_value_discarded
	_account.connect("signed_in", self, "_on_account_signed_in")
	#warning-ignore: return_value_discarded
	_account.connect("signed_out", self, "_on_account_signed_out")
	#warning-ignore: return_value_discarded
	_account.connect("session_closed", self, "_on_account_session_closed")
	#warning-ignore: return_value_discarded
	_account.connect("session_created", self, "_on_account_session_created")


func _on_account_signed_in():
	emit_signal("signed_in")


func _on_account_signed_out():
	emit_signal("signed_out")


func _on_account_session_closed():
	emit_signal("session_closed")


func _on_account_session_created():
	emit_signal("session_created")
