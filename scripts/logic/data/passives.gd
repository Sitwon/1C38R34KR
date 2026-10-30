class_name PassiveEffects
extends RefCounted

## PASSIVE-effect registry — the unified passive layer.
##
## Hackers, Systems, HOSTs, and UPGRADEs all reference rows from ONE external
## `PSV` dataset; the dataset chooses a coded `passive_effect`; this registry is
## the single stable-ID to validation-contract lookup. Trigger and modifier
## behaviour lives in the combat layer, switched exhaustively on the effect ID.
##
## Deliberately NOT a generalized trigger/rule/expression language. Every
## contract is a fixed typed tuple plus a fixed activation, so adding a passive
## kind means adding a registered contract and a coded branch — never authoring
## a script in a spreadsheet cell.

const EXTRA_MATCH_DAMAGE := "PSV_EXTRA_MATCH_DAMAGE"
const EXTRA_MATCH_CHARGE := "PSV_EXTRA_MATCH_CHARGE"
const CHARGE_DAMPEN := "PSV_CHARGE_DAMPEN"
const FUNCTION_DAMAGE_INCREASE := "PSV_FUNCTION_DAMAGE_INCREASE"
const PERM_SHIELD := "PSV_PERM_SHIELD"
const BIGGER_BOMB := "PSV_BIGGER_BOMB"
const CARRIER := "PSV_CARRIER"
const COUNTDOWN_ADJUST := "PSV_COUNTDOWN_ADJUST"
const ABILITY_DAMAGE_RATE := "PSV_ABILITY_DAMAGE_RATE"
const PACKET_DROP_RATE := "PSV_PACKET_DROP_RATE"
const SELF_DAMAGE := "PSV_SELF_DAMAGE"
const STRONG_SLICE_BONUS := "PSV_STRONG_SLICE_BONUS"

## Typed token kinds a parameter tuple can require.
##   COLOR        — a canonical colour token (RED/YEL/MAG/GRE/CYA/BLU)
##   SCOPE        — the ALL wildcard. Its own kind rather than a colour that
##                  happens to spell ALL, so "which axis" and "how broad" can
##                  never be confused by validation or by a reader.
##   POSITIVE_INT — a magnitude >= 1
##   SIGNED_INT   — any integer, shown with an explicit sign (+1 / -1)
##   NON_NEG_INT  — a magnitude >= 0
##   PERCENT      — a positive integer percentage, shown as `15%`
##   SIGNED_PERCENT — a signed integer percentage, shown as `+50%` / `-25%`
##   CHARACTERISTIC — one colour OR shape token (packet-drop target)
##   SELECTOR     — a colour, a shape, or ALL (match-damage qualifier)
##
## New members go on the END: `PARAM_KIND_NAMES` and stored rows index by them.
enum ParamKind {
	COLOR = 0, SCOPE, POSITIVE_INT, SIGNED_INT, NON_NEG_INT,
	PERCENT, SIGNED_PERCENT, CHARACTERISTIC, SELECTOR,
}

## How each kind reads in a validation message, in `ParamKind` order.
const PARAM_KIND_NAMES := [
	"color", "scope", "positiveInt", "signedInt", "nonNegativeInt",
	"percent", "signedPercent", "color|shape", "color|shape|ALL",
]

## The complete authored activation vocabulary.
enum Activation { CONTINUAL = 0, START_OF_TURN }

## The authored agent scope. Meaningful for HAK/SYS/UPG sources; IGNORED for
## HST sources, because a HOST is not an agent — it applies to both sides
## symmetrically.
enum AgentScope { OWNER = 0, ENEMY }

const ALL_SCOPE_TOKEN := "ALL"

const ACTIVATION_NAMES := ["CONTINUAL", "START_OF_TURN"]
const AGENT_SCOPE_NAMES := ["OWNER", "ENEMY"]

## `payload` states whether `function_payload` is required or forbidden. There
## is no "optional" — an unclear payload column is an authoring error either way.
enum Payload { REQUIRED = 0, FORBIDDEN }


static var _registry: Dictionary = {}


static func registry() -> Dictionary:
	if _registry.is_empty():
		_build()
	return _registry


static func contract(id: String) -> Dictionary:
	return registry().get(id, {})


static func is_effect_id(s: String) -> bool:
	return registry().has(s)


static func ids() -> Array:
	return registry().keys()


static func is_activation(s: String) -> bool:
	return ACTIVATION_NAMES.has(s)


static func is_agent_scope(s: String) -> bool:
	return AGENT_SCOPE_NAMES.has(s)


static func _build() -> void:
	_registry = {
		# Extra raw Sync damage once per qualifying Sync EVENT, applied before
		# crit, flooring, Buff, and Shield. The selector is a colour (colour-axis
		# Syncs of that colour), a shape (shape-axis Syncs of that shape), or ALL
		# (every Sync on any axis — beta 0.5 §9, FURNACE).
		EXTRA_MATCH_DAMAGE: {
			"id": EXTRA_MATCH_DAMAGE,
			"params": [ParamKind.SELECTOR, ParamKind.POSITIVE_INT],
			"activation": Activation.CONTINUAL,
			"payload": Payload.FORBIDDEN,
		},
		# Inflates the qualifying Sync's charge STREAM before routing, rather
		# than opening a second pool.
		EXTRA_MATCH_CHARGE: {
			"id": EXTRA_MATCH_CHARGE,
			"params": [ParamKind.COLOR, ParamKind.POSITIVE_INT],
			"activation": Activation.CONTINUAL,
			"payload": Payload.FORBIDDEN,
		},
		# Reduces qualifying charge streams. `ALL` covers every stream.
		CHARGE_DAMPEN: {
			"id": CHARGE_DAMPEN,
			"params": [ParamKind.SCOPE, ParamKind.POSITIVE_INT],
			"activation": Activation.CONTINUAL,
			"payload": Payload.FORBIDDEN,
		},
		# Adds to raw Function-originated damage before defensive handling.
		FUNCTION_DAMAGE_INCREASE: {
			"id": FUNCTION_DAMAGE_INCREASE,
			"params": [ParamKind.SCOPE, ParamKind.POSITIVE_INT],
			"activation": Activation.CONTINUAL,
			"payload": Payload.FORBIDDEN,
		},
		# Non-removable Shield value, stacked with Packet Shield. Not a Packet:
		# it cannot be sliced, blasted, or transformed away.
		PERM_SHIELD: {
			"id": PERM_SHIELD,
			"params": [ParamKind.SCOPE, ParamKind.POSITIVE_INT],
			"activation": Activation.CONTINUAL,
			"payload": Payload.FORBIDDEN,
		},
		# Advances every qualifying Bomb one NAMED area-pattern step. Takes no
		# parameters: the step count is the number of active instances.
		BIGGER_BOMB: {
			"id": BIGGER_BOMB,
			"params": [],
			"activation": Activation.CONTINUAL,
			"payload": Payload.FORBIDDEN,
		},
		# Invokes its authored `function_payload` at the start of the relevant
		# turn, paying NO Function cost — no pool is required and none is debited.
		CARRIER: {
			"id": CARRIER,
			"params": [],
			"activation": Activation.START_OF_TURN,
			"payload": Payload.REQUIRED,
		},
		# Beta 0.5 §8.1. Added to a countdown special's authored countdown ONCE,
		# when it is placed; every applicable instance sums, floored at 0.
		COUNTDOWN_ADJUST: {
			"id": COUNTDOWN_ADJUST,
			"params": [ParamKind.SIGNED_INT],
			"activation": Activation.CONTINUAL,
			"payload": Payload.FORBIDDEN,
		},
		# Beta 0.5 §8.2. Percentage applied once, as the SUM of every applicable
		# instance, to an attacker's direct Function/Effect damage.
		ABILITY_DAMAGE_RATE: {
			"id": ABILITY_DAMAGE_RATE,
			"params": [ParamKind.SIGNED_PERCENT],
			"activation": Activation.CONTINUAL,
			"payload": Payload.FORBIDDEN,
		},
		# Beta 0.5 §8.3. Relative weight added to one colour or shape in new
		# Packet generation. Board-wide: it has no meaningful ENEMY scope.
		PACKET_DROP_RATE: {
			"id": PACKET_DROP_RATE,
			"params": [ParamKind.PERCENT, ParamKind.CHARACTERISTIC],
			"activation": Activation.CONTINUAL,
			"payload": Payload.FORBIDDEN,
		},
		# Beta 0.5 §8.4. PASSIVE damage to the combatant whose turn begins.
		SELF_DAMAGE: {
			"id": SELF_DAMAGE,
			"params": [ParamKind.NON_NEG_INT],
			"activation": Activation.START_OF_TURN,
			"payload": Payload.FORBIDDEN,
		},
		# Beta 0.5 §8.5. Added once per sliced Packet the slice valued as strong.
		STRONG_SLICE_BONUS: {
			"id": STRONG_SLICE_BONUS,
			"params": [ParamKind.POSITIVE_INT],
			"activation": Activation.CONTINUAL,
			"payload": Payload.FORBIDDEN,
		},
	}
