extends RefCounted

## The frozen Alpha-equivalent content profile (beta 0.5 §17.1).
##
## Beta 0.5 moves live content past the alpha: eight new Systems, five HOSTs,
## six UPGRADEs. Comparing live pools against alpha fixtures would fail for the
## expected reason and prove nothing. The alpha-era IDs are all still present
## and unchanged in the fields route generation reads (ID, pool flag, file
## order), so restricting the live content to them reproduces the alpha's pools
## exactly — and keeps the generators under a real differential.
##
## What this profile does NOT freeze: Program loadouts and strong sets, which the
## workbook deliberately changed. It is for code paths that read pools only.

const SYSTEM_IDS := ["SYS_01", "SYS_02", "SYS_03"]
const HOST_IDS := ["HST_01", "HST_02", "HST_03", "HST_04", "HST_05"]
const UPGRADE_IDS := ["UPG_01", "UPG_02", "UPG_03", "UPG_04"]


## A copy of resolved `content` whose System, HOST, and UPGRADE tables hold only
## the alpha-era rows, in their original order.
static func restrict(content: Dictionary) -> Dictionary:
	var out := content.duplicate()
	out["systems"] = _only(content["systems"], SYSTEM_IDS)
	out["hosts"] = _only(content["hosts"], HOST_IDS)
	out["upgrades"] = _only(content["upgrades"], UPGRADE_IDS)
	return out


static func _only(table: Dictionary, ids: Array) -> Dictionary:
	var out := {}
	for id in table:
		if ids.has(id):
			out[id] = table[id]
	return out
