class_name HostAddresses
extends Node
## The addresses a host can give his friend: the ones on his own network,
## and the one the internet sees, which is looked up at an outside service
## (as in Together Around; it can be switched off with [member look_up_public]).
## What that service answers is a stranger's text and is only shown when it
## is a plain public IPv4 address.

## The look-up is over: [param address] is the public address, or empty
## when it could not be found.
signal public_lookup_finished(address: String)

## Plain text: one IPv4 address and nothing else.
const SERVICE_URL := "https://api.ipify.org"
const TIMEOUT_S := 5.0
const MAX_ANSWER_BYTES := 64
const HTTP_OK := 200

@export var look_up_public := true

## The public address, once found.
var public_address := ""
## Whether the last look-up is over (found or not).
var public_lookup_done := false
var _request: HTTPRequest


func _ready() -> void:
	_request = HTTPRequest.new()
	_request.timeout = TIMEOUT_S
	_request.request_completed.connect(_on_completed)
	add_child(_request)


## Asks for the public address; hosting never waits for it.
func look_up() -> void:
	if not look_up_public:
		public_lookup_done = true
		return
	if not public_address.is_empty() or _request == null:
		return
	if _request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	public_lookup_done = false
	if _request.request(SERVICE_URL) != OK:
		_finish_lookup()


## The private IPv4 addresses of this machine, sorted.
static func local() -> PackedStringArray:
	return private_ipv4(IP.get_local_addresses())


## The private IPv4 addresses (RFC 1918) among [param addresses], sorted and
## without doubles.
static func private_ipv4(addresses: PackedStringArray) -> PackedStringArray:
	var result := PackedStringArray()
	for address in addresses:
		if is_private_ipv4(address) and not result.has(address):
			result.append(address)
	result.sort()
	return result


static func is_private_ipv4(address: String) -> bool:
	var octets := _octets(address)
	if octets.is_empty():
		return false
	if octets[0] == 10:
		return true
	if octets[0] == 172:
		return octets[1] >= 16 and octets[1] <= 31
	return octets[0] == 192 and octets[1] == 168


## Whether [param answer] may be shown as the public address.
static func is_public_ipv4(answer: String) -> bool:
	var octets := _octets(answer)
	if octets.is_empty() or is_private_ipv4(answer):
		return false
	return octets[0] != 127 and not (octets[0] == 169 and octets[1] == 254) and octets[0] != 0


static func _octets(address: String) -> PackedInt32Array:
	if not address.is_valid_ip_address() or address.contains(":"):
		return PackedInt32Array()
	var result := PackedInt32Array()
	for part in address.split("."):
		result.append(part.to_int())
	return result


func _on_completed(
	result: int, code: int, _headers: PackedStringArray, body: PackedByteArray
) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and code == HTTP_OK and body.size() <= MAX_ANSWER_BYTES:
		var answer := body.get_string_from_utf8().strip_edges()
		if is_public_ipv4(answer):
			public_address = answer
	_finish_lookup()


func _finish_lookup() -> void:
	public_lookup_done = true
	public_lookup_finished.emit(public_address)
