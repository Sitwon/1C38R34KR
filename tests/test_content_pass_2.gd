extends RefCounted

## Beta 0.6 — Content Pass 2 (authorization §19).
##
## Live content only, like `test_content_expansion.gd`, whose board and state
## helpers this file borrows rather than restates (lessons-learned, beta 0.4:
## a helper written twice is a list that drifts). Every assertion is the
## authorization or the workbook read back.

const X := preload("res://tests/test_content_expansion.gd")

const P := Types.Side.PLAYER
const E := Types.Side.ENEMY

## §4 / §5 — the authored roster, by stable ID.
const HACKERS := {
	"HAK_01": ["CR45H", 100, ["RED", "GRE", "YEL"], ["TRI", "SQU", "STR"], ["PRG_H_001", "PRG_H_002", "PRG_H_005"]],
	"HAK_02": ["VITRA", 110, ["GRE", "BLU", "MAG"], ["SQU", "CIR", "DIA"], ["PRG_H_007", "PRG_H_008", "PRG_H_009"]],
	"HAK_03": ["RAZE", 90, ["RED", "MAG", "YEL"], ["TRI", "CRO", "STR"], ["PRG_H_010", "PRG_H_011", "PRG_H_012"]],
	"HAK_04": ["NEEDLE", 100, ["GRE", "YEL", "BLU"], ["STR", "CIR", "TRI"], ["PRG_H_013", "PRG_H_014", "PRG_H_015"]],
}
const DECKS := {
	"DEK_01": ["AGIMA", 50, ["PRG_H_003", "PRG_H_004", "PRG_H_006"], "FNC_010"],
	"DEK_02": ["BLEEDLINE", 40, ["PRG_H_016", "PRG_H_017", "PRG_H_018"], "FNC_056"],
	"DEK_03": ["BASTION", 60, ["PRG_H_019", "PRG_H_020", "PRG_H_021"], "FNC_062"],
	"DEK_04": ["FUSEBOX", 45, ["PRG_H_022", "PRG_H_023", "PRG_H_024"], "FNC_065"],
}
## §7 — Boss loadouts and strong axes, in authored order.
const BOSSES := {
	"BOS_01": [["BLU", "MAG", "GRE"], ["CIR", "CRO", "SQU"], ["PRG_S_004", "PRG_S_025", "PRG_S_002", "PRG_S_003"], "OVERRIDE_PLACED"],
	"BOS_02": [["YEL", "RED", "BLU"], ["STR", "TRI", "CIR"], ["PRG_S_002", "PRG_S_014", "PRG_S_007", "PRG_S_004"], "CAPACITOR_PLACED"],
	"BOS_03": [["RED", "YEL", "GRE"], ["TRI", "STR", "SQU"], ["PRG_S_017", "PRG_S_008", "PRG_S_001", "PRG_S_006"], "LOGIC_BOMB_PLACED"],
	"BOS_04": [["MAG", "BLU", "YEL"], ["DIA", "CIR", "CRO"], ["PRG_S_022", "PRG_S_025", "PRG_S_003", "PRG_S_002"], "AXIS_CONCEALED"],
}

var x = X.new()


func run(t: TestCase) -> void:
	var loader := ContentLoader.new()
	var result := loader.load_all()
	if not result["ok"]:
		t.group("content pass 2")
		t.check("content loads", false)
		return
	Content.set_active(result["content"])
	Passives.clear_cache()

	_test_counts(t, loader)
	_test_roster(t)
	_test_bosses_load(t)
	_test_text(t)
	_test_pairs(t)
	_test_contracts(t)

	_test_heal(t)
	_test_self_damage(t)
	_test_chains(t)
	_test_charge(t)
	_test_charge_scopes(t)
	_test_mines(t)
	_test_reused_and_bombs(t)
	_test_spark(t)
	_test_boss_programs(t)
	_test_save_resume(t)

	Content.clear()
	Passives.clear_cache()


# ---------------------------------------------------------------------------
# §3 / §19.1 content
# ---------------------------------------------------------------------------

func _test_counts(t: TestCase, loader: ContentLoader) -> void:
	t.group("content pass 2 / live counts")
	t.eq("4 Hackers", (Content.active()["hackers"] as Dictionary).size(), 4)
	t.eq("4 Decks", (Content.active()["decks"] as Dictionary).size(), 4)
	t.eq("4 Bosses", Content.all_bosses().size(), 4)
	t.eq("11 Systems", Content.all_systems().size(), 11)
	t.eq("10 HOSTs", Content.all_hosts().size(), 10)
	t.eq("10 UPGRADEs", Content.all_upgrades().size(), 10)
	t.eq("24 Hacker/Deck Programs", Content.programs_for(P).size(), 24)
	t.eq("26 System/Boss Programs — none added", Content.programs_for(E).size(), 26)
	t.eq("67 Functions", loader.function_rows.size(), 67)
	t.eq("20 PASSIVEs — none added", loader.passive_rows.size(), 20)
	t.eq("292 text_content rows", loader.text_rows.size(), 292)

	for n in range(41, 68):
		var id := "FNC_%03d" % n
		t.check("%s loads with a plan" % id, not (Content.function(id).get("plan", []) as Array).is_empty())

	# §23 — every warning is a known kind; none is fatal and none is a
	# placement problem.
	var kinds := {}
	for w in loader.issues.warnings():
		var reason := str(w.get("reason", ""))
		var kind := "other"
		if reason.begins_with("duplicate display name"):
			kind = "duplicate name"
		elif reason.contains("not referenced"):
			kind = "unreferenced"
		elif reason.contains("Program sets"):
			kind = "placement"
		kinds[kind] = int(kinds.get(kind, 0)) + 1
	t.eq("warnings by kind", kinds, {"duplicate name": 28, "unreferenced": 6})


func _test_roster(t: TestCase) -> void:
	t.group("content pass 2 / Hackers and Decks")
	var placements := {}
	for id in HACKERS:
		var want: Array = HACKERS[id]
		var h := Content.hacker(id)
		t.eq("%s name" % id, str(h["name"]), want[0])
		t.eq("%s BASE_LINK" % id, int(h["base_link"]), want[1])
		t.eq_seq("%s strong colours" % id, h["strong_colors"], x._tokens(want[2], Vocab.COLOR_TOKENS))
		t.eq_seq("%s strong shapes" % id, h["strong_shapes"], x._tokens(want[3], Vocab.SHAPE_TOKENS))
		t.eq_seq("%s Programs" % id, h["portfolio"], want[4])
		for pid in want[4]:
			placements[pid] = int(placements.get(pid, 0)) + 1
	for id in DECKS:
		var want: Array = DECKS[id]
		var d := Content.deck(id)
		t.eq("%s name" % id, str(d["name"]), want[0])
		t.eq("%s ADD_LINK" % id, int(d["add_link"]), want[1])
		t.eq_seq("%s Programs" % id, d["portfolio"], want[2])
		t.eq("%s active Function" % id, str(d["fn"]["id"]), want[3])
		# §5 — every Deck active starts charged through its own row.
		t.check("%s active starts charged" % id, bool(d["fn"]["start_charged"]))
		for pid in want[2]:
			placements[pid] = int(placements.get(pid, 0)) + 1

	# §3 — 24 placements, each player Program in exactly one set.
	t.eq("24 placements", placements.size(), 24)
	for p in Content.programs_for(P):
		t.eq("%s placed exactly once" % p["id"], int(placements.get(p["id"], 0)), 1)
		t.check("%s resolves to a plan" % p["id"], not (p["fn"]["plan"] as Array).is_empty())


func _test_bosses_load(t: TestCase) -> void:
	t.group("content pass 2 / Boss rows")
	for id in BOSSES:
		var want: Array = BOSSES[id]
		var b := Content.boss(id)
		t.eq_seq("%s strong colours" % id, b["strong_colors"], x._tokens(want[0], Vocab.COLOR_TOKENS))
		t.eq_seq("%s strong shapes" % id, b["strong_shapes"], x._tokens(want[1], Vocab.SHAPE_TOKENS))
		t.eq_seq("%s PRG_SET in authored order" % id, b["programs"], want[2])
		# §7 — Boss Attack instantiates the authored loadout, not 0.5's.
		var s := Session.create_boss_attack(id, Content.BOSS_ATTACK_HOST_ID, 3, Session.default_build())
		var units := []
		for u in (s.units[E] as Array):
			units.append(u.program_id)
		t.eq_seq("%s Boss Attack fields the authored loadout" % id, units, want[2])
		t.eq_seq("%s Boss Attack uses the authored colours" % id, s.config["strong_colors"][E], b["strong_colors"])


func _test_text(t: TestCase) -> void:
	t.group("content pass 2 / names resolve")
	var rows := []
	for id in HACKERS:
		rows.append([Text.HACKER_NAME, id, HACKERS[id][0]])
	for id in DECKS:
		rows.append([Text.DECK_NAME, id, DECKS[id][0]])
	for n in range(7, 25):
		var pid := "PRG_H_%03d" % n
		rows.append([Text.PROGRAM_NAME, pid, Content.program(pid)["name"]])
	for n in range(41, 68):
		var fid := "FNC_%03d" % n
		rows.append([Text.FUNCTION_NAME, fid, Content.function(fid)["name"]])
	t.eq("51 new rows checked", rows.size() - 2, 51)  # CR45H and AGIMA ride along
	for r in rows:
		t.eq("%s/%s" % [r[0], r[1]], Text.get_text(str(r[0]), str(r[1])), str(r[2]))


## §6 / §19.1 — all sixteen pairings construct a legal six-candidate Build.
func _test_pairs(t: TestCase) -> void:
	t.group("content pass 2 / all sixteen pairings")
	for h in HACKERS:
		for d in DECKS:
			var inv := Content.inventory_program_ids(h, d)
			t.eq("%s+%s six distinct candidates" % [h, d], _distinct(inv), Content.INVENTORY_SIZE)
			var build := Content.default_build(h, d)
			t.check("%s+%s default build is legal" % [h, d], Content.is_valid_build(build, inv))
			t.eq("%s+%s builds four" % [h, d], build.size(), Content.ACTIVE_BUILD_SIZE)
			var s := _pair(h, d, build)
			t.eq("%s+%s LINK is BASE_LINK + ADD_LINK" % [h, d], s.hp[P], int(HACKERS[h][1]) + int(DECKS[d][1]))
			t.eq("%s+%s battle max matches" % [h, d], s.max_hp_of(P), s.hp[P])
			t.eq("%s+%s identity" % [h, d], [s.identity["hacker_id"], s.identity["deck_id"]], [h, d])
			var a := Session.create_boss_attack("BOS_02", Content.BOSS_ATTACK_HOST_ID, 1, build, {}, false, h, d)
			t.eq("%s+%s Boss Attack plays the pair" % [h, d], [a.identity["hacker_id"], a.identity["deck_id"]], [h, d])


func _distinct(a: Array) -> int:
	var seen := {}
	for v in a:
		seen[v] = true
	return seen.size()


# ---------------------------------------------------------------------------
# §15 validation
# ---------------------------------------------------------------------------

func _test_contracts(t: TestCase) -> void:
	t.group("content pass 2 / HEAL, SELF_DAMAGE, CHARGE contracts")
	var ctx := {"dataset": DataIssues.DATASET_FUNCTIONS, "file": "test", "row": 1, "id": "FNC_900"}
	for c in [[Effects.HEAL, "magnitude"], [Effects.SELF_DAMAGE, "damage"], [Effects.CHARGE, "magnitude"]]:
		var effect: String = c[0]
		var col: String = c[1]
		var contract := Effects.contract(effect)
		for v in [["0", true], ["25", true], ["", false], ["-1", false], ["x", false], ["2.5", false]]:
			var cols := {"quantity": "", "countdown": "", "areaPattern": "", "magnitude": "", "damage": ""}
			cols[col] = v[0]
			var l := ContentLoader.new()
			var out := {}
			t.eq("%s %s=%s accepted" % [effect, col, v[0]], l._resolve_discrete_params({"params": cols}, contract, effect, ctx, out), v[1])
			if v[1]:
				t.eq("%s %s=%s resolves" % [effect, col, v[0]], out.get(col), int(v[0]))
		# The column the Effect does NOT read warns when populated.
		var other := "damage" if col == "magnitude" else "magnitude"
		var cols2 := {"quantity": "", "countdown": "", "areaPattern": "", "magnitude": "", "damage": ""}
		cols2[col] = "5"
		cols2[other] = "5"
		var l2 := ContentLoader.new()
		l2._resolve_discrete_params({"params": cols2}, contract, effect, ctx, {})
		t.eq("%s warns on a populated %s" % [effect, other], l2.issues.warning_count, 1)

	var charge := Effects.contract(Effects.CHARGE)
	for v in [["0", true, 0], ["1", true, 1], ["2", true, 2], ["3", false, null], ["", false, null], ["1:1", false, null], ["-1", false, null]]:
		var l := ContentLoader.new()
		var out := {}
		t.eq("CHARGE scope '%s' accepted" % v[0], l._resolve_tuple({"tuple_raw": v[0]}, charge, Effects.CHARGE, ctx, out), v[1])
		if v[1]:
			t.eq("CHARGE scope '%s' resolves" % v[0], out["charge"]["scope"], v[2])
	# HEAL and SELF_DAMAGE take no params string.
	for effect in [Effects.HEAL, Effects.SELF_DAMAGE]:
		var l := ContentLoader.new()
		l._resolve_tuple({"tuple_raw": "1"}, Effects.contract(effect), effect, ctx, {})
		t.eq("%s warns on a params string" % effect, l.issues.warning_count, 1)

	# §11.2 — a SELF scope on a source with no Program fails at LOAD.
	var loader := ContentLoader.new()
	loader.load_all()
	var plan: Array = (loader.plans["FNC_056"] as Array).duplicate(true)
	plan[1]["params"]["charge"]["scope"] = Content.CHARGE_SCOPE_SELF
	loader.plans["FNC_056"] = plan
	loader.issues = DataIssues.new()
	loader.check_charge_self_sources()
	t.eq("a Deck active with CHARGE scope SELF is a load error", loader.issues.error_count, 1)
	t.check("…naming the Deck", loader.issues.error_count == 1 and str(loader.issues.errors()[0]["id"]) == "DEK_02")

	# The authored rows read back as authored.
	var p058: Dictionary = Content.function("FNC_058")["plan"][0]["params"]
	t.eq("TRANSFUSECHARGE offers 4", int(p058["magnitude"]), 4)
	t.eq("…to OTHER_PROGRAMS", int(p058["charge"]["scope"]), Content.CHARGE_SCOPE_OTHER)
	for c in [["FNC_041", "magnitude", 25], ["FNC_044", "magnitude", 12], ["FNC_063", "magnitude", 18],
			["FNC_047", "damage", 12], ["FNC_050", "damage", 15], ["FNC_057", "damage", 20]]:
		t.eq("%s %s" % [c[0], c[1]], int(Content.function(c[0])["plan"][0]["params"][c[1]]), c[2])


# ---------------------------------------------------------------------------
# §9 / §19.2 HEAL
# ---------------------------------------------------------------------------

func _test_heal(t: TestCase) -> void:
	t.group("content pass 2 / HEAL")
	# VITRA + BASTION: 110 + 60.
	var s := _pair("HAK_02", "DEK_03", ["PRG_H_007"])
	t.eq("battle maximum includes ADD_LINK", s.max_hp_of(P), 170)
	s.hp[P] = 100
	var events := _fire(s, "PRG_H_007")
	var h := x._first(events, Types.EVT.HEAL)
	t.eq("MEND restores 25", s.hp[P], 125)
	t.eq("telemetry", [h.get("before"), h.get("attempted"), h.get("applied"), h.get("wasted"), h.get("after")], [100, 25, 25, 0, 125])
	t.eq("attributed to its Program and Function", [h.get("program_id"), h.get("fn_id"), h.get("side")], ["PRG_H_007", "FNC_041", P])

	s.hp[P] = 160
	h = x._first(_fire(s, "PRG_H_007"), Types.EVT.HEAL)
	t.eq("capped at the battle maximum", s.hp[P], 170)
	t.eq("applied 10, wasted 15", [h.get("applied"), h.get("wasted")], [10, 15])

	events = _fire(s, "PRG_H_007")
	h = x._first(events, Types.EVT.HEAL)
	t.eq("at full health: applies 0, wastes 25", [h.get("applied"), h.get("wasted"), s.hp[P]], [0, 25, 170])
	var m := Metrics.create([], [])
	Metrics.consume(m, events)
	t.eq("metrics: applied/wasted", [m.side(P).heal_applied, m.side(P).heal_wasted], [0, 25])
	t.eq("…and no damage anywhere", [m.side(P).total_damage, m.side(E).total_damage], [0, 0])

	# No board resolution at all.
	var kinds := {}
	for ev in events:
		kinds[ev["t"]] = true
	t.eq_seq("only activation, HEAL, op and message events", _sorted(kinds.keys()),
		_sorted([Types.EVT.ABILITY, Types.EVT.HEAL, Types.EVT.OP, Types.EVT.MSG]))

	# Shield and damage modifiers never touch it.
	s = _pair("HAK_02", "DEK_03", ["PRG_H_007"])
	x._lattice(s)
	x._special(s, Vector2i(0, 0), Tile.Special.Type.SHIELD, P, 5)
	x._special(s, Vector2i(2, 0), Tile.Special.Type.BUFF, P, 5)
	x._inject(s, ["PSV_011", "PSV_004"], P)
	x._inject(s, ["PSV_017"], E)
	s.hp[P] = 50
	_fire(s, "PRG_H_007")
	t.eq("Shield, Buff, ARENA and ability-rate change nothing", s.hp[P], 75)

	# §9.3 — owner-generic: a synthetic System-side HEAL restores ICE.
	s = _pair("HAK_02", "DEK_03", ["PRG_H_007"])
	s.hp[E] = 40
	events = _cast_fn(s, E, "FNC_041")
	h = x._first(events, Types.EVT.HEAL)
	t.eq("System HEAL restores ICE", s.hp[E], 65)
	t.eq("…and leaves LINK alone", s.hp[P], 170)
	t.eq("…reported on the System side", h.get("side"), E)
	s.hp[E] = 90
	_cast_fn(s, E, "FNC_041")
	t.eq("…capped at the System's battle ICE", s.hp[E], s.max_hp_of(E))

	# A decided battle is never revived.
	s = _pair("HAK_02", "DEK_03", ["PRG_H_007"])
	var r := Resolve.heal(s, P, 25)
	s.hp[P] = 0
	s.winner = E
	r = Resolve.heal(s, P, 25)
	t.eq("no heal once the battle is over", [r["applied"], s.hp[P]], [0, 0])


# ---------------------------------------------------------------------------
# §10 / §19.3 Function SELF_DAMAGE
# ---------------------------------------------------------------------------

func _test_self_damage(t: TestCase) -> void:
	t.group("content pass 2 / Function SELF_DAMAGE")
	# RAZE + AGIMA: 90 + 50.
	var s := _pair("HAK_03", "DEK_01", ["PRG_H_010", "PRG_H_011"])
	x._lattice(s)
	var events := _fire(s, "PRG_H_010")
	var c := x._first(events, Types.EVT.HEALTH_COST)
	t.eq("OVERDRAW costs exactly 12", s.hp[P], 128)
	t.eq("telemetry", [c.get("before"), c.get("cost"), c.get("after"), c.get("lethal"), c.get("aborted_ops")], [140, 12, 128, false, 0])
	t.eq("…attributed", [c.get("program_id"), c.get("fn_id")], ["PRG_H_010", "FNC_047"])
	t.eq("nonlethal OVERDRAW reaches its BUFF", x._specials_of(s, Tile.Special.Type.BUFF).size(), 2)
	t.check("…after the cost", x._index_of(events, Types.EVT.HEALTH_COST) < x._index_of(events, Types.EVT.SET_TILE))
	t.eq("no damage event at all", x._count(events, Types.EVT.DAMAGE), 0)
	var m := Metrics.create([], [])
	Metrics.consume(m, events)
	t.eq("metrics: health paid", m.side(P).health_cost_paid, 12)
	t.eq("not opponent damage", m.side(E).total_damage, 0)
	t.eq("not environmental damage", m.side(P).environment_damage_taken, 0)

	# Shield, Buff, ARENA and every ability-rate modifier leave it alone.
	s = _pair("HAK_03", "DEK_01", ["PRG_H_010"])
	x._lattice(s)
	x._special(s, Vector2i(0, 0), Tile.Special.Type.SHIELD, P, 9)
	x._special(s, Vector2i(2, 0), Tile.Special.Type.BUFF, P, 5)
	x._special(s, Vector2i(4, 0), Tile.Special.Type.BUFF, E, 5)
	x._inject(s, ["PSV_011", "PSV_004", "PSV_017"], P)
	x._inject(s, ["PSV_011", "PSV_004", "PSV_017"], E)
	events = _fire(s, "PRG_H_010")
	t.eq("bypasses Shield and every modifier", s.hp[P], 128)
	t.eq("…and the Shield records nothing", x._count(events, Types.EVT.SHIELD), 0)

	# Lethal: the battle ends and the BUFF never lands.
	s = _pair("HAK_03", "DEK_01", ["PRG_H_010"])
	x._lattice(s)
	s.hp[P] = 12
	events = _fire(s, "PRG_H_010")
	c = x._first(events, Types.EVT.HEALTH_COST)
	t.eq("a lethal cost ends the battle", s.winner, E)
	t.eq("…at exactly zero", s.hp[P], 0)
	t.eq("…reported lethal with one payload cut off", [c.get("lethal"), c.get("aborted_ops")], [true, 1])
	t.eq("…and the BUFF never lands", x._specials_of(s, Tile.Special.Type.BUFF).size(), 0)
	t.check("cost then battle end", x._index_of(events, Types.EVT.HEALTH_COST) < x._index_of(events, Types.EVT.OVER))
	s = _pair("HAK_03", "DEK_01", ["PRG_H_010"])
	s.hp[P] = 5
	_fire(s, "PRG_H_010")
	t.eq("an overpaid cost floors at zero", s.hp[P], 0)

	# BLOODSPIKE reaches its ATTACK; lethal aborts it.
	s = _pair("HAK_03", "DEK_01", ["PRG_H_011"])
	events = _fire(s, "PRG_H_011")
	t.eq("BLOODSPIKE pays 15", s.hp[P], 125)
	t.eq("…then hits for 40", s.hp[E], 60)
	t.check("cost before hit", x._index_of(events, Types.EVT.HEALTH_COST) < x._index_of(events, Types.EVT.DAMAGE))
	s = _pair("HAK_03", "DEK_01", ["PRG_H_011"])
	s.hp[P] = 15
	_fire(s, "PRG_H_011")
	t.eq("a lethal BLOODSPIKE never hits", [s.winner, s.hp[E]], [E, 100])

	# TRANSFUSE reaches its CHARGE; lethal aborts all of it.
	s = _pair("HAK_03", "DEK_02", ["PRG_H_010"])
	events = Game.new(s).fire_deck_function()
	t.eq("TRANSFUSE pays 20", s.hp[P], 110)
	t.eq("…then charges", x._count(events, Types.EVT.DIRECT_CHARGE), 1)
	s = _pair("HAK_03", "DEK_02", ["PRG_H_010"])
	s.hp[P] = 20
	events = Game.new(s).fire_deck_function()
	t.eq("a lethal TRANSFUSE ends the battle", s.winner, E)
	t.eq("…and charges nothing", [x._count(events, Types.EVT.DIRECT_CHARGE), _charges(s)], [0, [0, 0, 0, 0]])

	# PSV_SELF_DAMAGE (D-061) is unchanged and still environmental.
	s = _pair("HAK_03", "DEK_01", ["PRG_H_010"], "SYS_01", "HST_09")
	var passive_events := Game.new(s).start_player_phase()
	m = Metrics.create([], [])
	Metrics.consume(m, passive_events)
	t.eq("ACID is still environmental damage", m.side(P).environment_damage_taken, 10)
	t.eq("…and not a health cost", m.side(P).health_cost_paid, 0)


# ---------------------------------------------------------------------------
# §14 / §19.6 authored chains
# ---------------------------------------------------------------------------

func _test_chains(t: TestCase) -> void:
	t.group("content pass 2 / authored chains")
	for c in [["FNC_043", ["FNC_044", "FNC_045"], [Effects.HEAL, Effects.BUFF]],
			["FNC_046", ["FNC_047", "FNC_048"], [Effects.SELF_DAMAGE, Effects.BUFF]],
			["FNC_049", ["FNC_050", "FNC_051"], [Effects.SELF_DAMAGE, Effects.ATTACK]],
			["FNC_056", ["FNC_057", "FNC_058"], [Effects.SELF_DAMAGE, Effects.CHARGE]]]:
		var plan: Array = Content.function(c[0])["plan"]
		t.eq("%s expands one level to its two leaves" % c[0], plan.map(func(op): return op["fn_id"]), c[1])
		t.eq("%s runs its Effects in order" % c[0], plan.map(func(op): return op["effect_id"]), c[2])

	# SALVE: heal, then buff, paying the parent's 8 once.
	var s := _pair("HAK_02", "DEK_01", ["PRG_H_009"])
	x._lattice(s)
	s.hp[P] = 100
	var events := _fire(s, "PRG_H_009")
	t.eq("SALVE heals 12", s.hp[P], 112)
	t.eq("…then places one Buff", x._specials_of(s, Tile.Special.Type.BUFF).size(), 1)
	t.check("…in that order", x._index_of(events, Types.EVT.HEAL) < x._index_of(events, Types.EVT.SET_TILE))
	t.eq("…paying only the parent cost", _player_unit(s, "PRG_H_009").charge, 0)
	t.eq("one activation", x._count(events, Types.EVT.ABILITY), 1)


# ---------------------------------------------------------------------------
# §11 / §19.4 direct CHARGE
# ---------------------------------------------------------------------------

func _test_charge(t: TestCase) -> void:
	t.group("content pass 2 / TRANSFUSE direct charge")
	# VITRA + BLEEDLINE; caps: MEND 6, AEGIS 7, SALVE 8, LANCET 7.
	var s := _pair("HAK_02", "DEK_02", ["PRG_H_007", "PRG_H_008", "PRG_H_009", "PRG_H_016"])
	t.eq("the Deck active starts charged", s.deck_charge, 5)
	var u: Array = s.units[P]
	u[0].charge = 0
	u[1].charge = 6
	u[2].charge = 8
	u[3].charge = 2
	var g := Game.new(s)
	var events := g.fire_deck_function()
	var dc := x._first(events, Types.EVT.DIRECT_CHARGE)
	t.eq_seq("each active Program offered 4, capped on its own", _charges(s), [4, 7, 8, 6])
	t.eq("the Deck's own pool is not a target", s.deck_charge, 0)
	t.eq("scope and offer", [dc.get("scope"), dc.get("offered"), dc.get("program_id"), dc.get("fn_id"), dc.get("owner_kind")],
		[Content.CHARGE_SCOPE_OTHER, 4, "DEK_02", "FNC_058", Types.OwnerKind.DECK])
	var got := []
	for tg in (dc.get("targets", []) as Array):
		got.append([tg["program_id"], tg["before"], tg["accepted"], tg["after"], tg["discarded"]])
	t.eq("per-target telemetry", got, [
		["PRG_H_007", 0, 4, 4, 0], ["PRG_H_008", 6, 1, 7, 3],
		["PRG_H_009", 8, 0, 8, 4], ["PRG_H_016", 2, 4, 6, 0],
	])
	t.eq("totals", [dc.get("accepted"), dc.get("discarded")], [9, 7])
	t.eq("no match routing, waste or Deck charge events",
		[x._count(events, Types.EVT.CHARGE_ROUTE), x._count(events, Types.EVT.CHARGE_WASTE), x._count(events, Types.EVT.DECK_CHARGE)], [0, 0, 0])
	t.eq("no board resolution", [x._count(events, Types.EVT.DESTROY), x._count(events, Types.EVT.FALL), x._count(events, Types.EVT.SET_TILE)], [0, 0, 0])
	var m := Metrics.create([], [])
	Metrics.consume(m, events)
	t.eq("metrics: accepted / discarded", [m.side(P).direct_charge_accepted, m.side(P).direct_charge_discarded], [9, 7])
	t.eq("…kept out of the match-routing waste figure", m.side(P).charge_wasted_total, 0)

	# §11.4 — a Program TRANSFUSE makes ready fires in the same pre-Sync window.
	s = _pair("HAK_02", "DEK_02", ["PRG_H_007"])
	(s.units[P] as Array)[0].charge = 2
	g = Game.new(s)
	g.fire_deck_function()
	t.eq("MEND is ready", (s.units[P] as Array)[0].charge, 6)
	t.eq("…the window is still open", s.phase, Types.Phase.PLAYER_PRE)
	var fired := g.fire_program(0)
	t.eq("…and it fires at once", x._first(fired, Types.EVT.ABILITY).get("program_id", ""), "PRG_H_007")
	t.eq("…spending its charge", (s.units[P] as Array)[0].charge, 0)


func _test_charge_scopes(t: TestCase) -> void:
	t.group("content pass 2 / CHARGE scopes")
	for c in [[Content.CHARGE_SCOPE_SELF, [0, 3, 0, 0]], [Content.CHARGE_SCOPE_OTHER, [3, 0, 3, 3]], [Content.CHARGE_SCOPE_ALL, [3, 3, 3, 3]]]:
		var s := _pair("HAK_02", "DEK_02", ["PRG_H_007", "PRG_H_008", "PRG_H_009", "PRG_H_016"])
		var events: Array = []
		Game.new(s)._cast_actor(P, _synthetic_actor(c[0], 1), events)
		t.eq_seq("scope %d from Program slot 1" % c[0], _charges(s), c[1])

	# ALL from a Deck — no source to include or skip.
	var s2 := _pair("HAK_02", "DEK_02", ["PRG_H_007", "PRG_H_008", "PRG_H_009", "PRG_H_016"])
	var ev2: Array = []
	Game.new(s2)._cast_actor(P, _synthetic_actor(Content.CHARGE_SCOPE_ALL, -1), ev2)
	t.eq_seq("scope ALL from a Deck", _charges(s2), [3, 3, 3, 3])

	# Side-generic: a System Program charging its own side.
	var s3 := _pair("HAK_02", "DEK_02", ["PRG_H_007"])
	for u in (s3.units[E] as Array):
		u.charge = 0
	var ev3: Array = []
	Game.new(s3)._cast_actor(E, _synthetic_actor(Content.CHARGE_SCOPE_OTHER, 0), ev3)
	var enemy := []
	for u in (s3.units[E] as Array):
		enemy.append(u.charge)
	t.eq_seq("a System CHARGE charges System Programs", enemy, [0, 3, 3, 3])
	t.eq_seq("…and no Hacker Program", _charges(s3), [0, 0, 0, 0])

	# SELF with no Program source fails loudly and guesses nothing. (One of
	# the suite's expected ERROR lines.)
	var s4 := _pair("HAK_02", "DEK_02", ["PRG_H_007"])
	var ev4: Array = []
	Game.new(s4)._cast_actor(P, _synthetic_actor(Content.CHARGE_SCOPE_SELF, -1), ev4)
	t.eq_seq("SELF without a Program charges nothing", _charges(s4), [0, 0, 0, 0])
	var op := x._first(ev4, Types.EVT.OP)
	t.eq("…and the op is unresolved", op.get("resolved", true), false)
	t.eq("…with no charge event", x._count(ev4, Types.EVT.DIRECT_CHARGE), 0)


func _synthetic_actor(scope: int, unit_idx: int) -> Dictionary:
	var fn := {
		"id": "FNC_T", "cost": 0,
		"plan": [{
			"fn_id": "FNC_T", "effect_id": Effects.CHARGE, "target": Types.TargetKind.NONE,
			"params": {"magnitude": 3, "charge": {"scope": scope}},
		}],
	}
	var actor := {"kind": Types.OwnerKind.PROGRAM if unit_idx >= 0 else Types.OwnerKind.DECK, "id": "SYNTH", "name": "SYNTH", "fn": fn}
	if unit_idx >= 0:
		actor["unit_idx"] = unit_idx
	return actor


# ---------------------------------------------------------------------------
# §13 / §19.5 SEEDMINE and TRIPWIRE
# ---------------------------------------------------------------------------

func _test_mines(t: TestCase) -> void:
	t.group("content pass 2 / NEEDLE Mines")
	# Placement through the real Programs, with the authored values stamped.
	for c in [["PRG_H_013", "FNC_053", 3, 3, 18, [1, 1, 0, 0, 0, 0]], ["PRG_H_014", "FNC_054", 2, 5, 28, [0, 0, 1, 1, 0, 0]]]:
		var s := _pair("HAK_04", "DEK_01", [c[0]])
		x._lattice(s)
		var events := _fire(s, c[0])
		var mines := x._specials_of(s, Tile.Special.Type.MINE)
		t.eq("%s places %d Mines" % [c[1], c[2]], mines.size(), c[2])
		if not mines.is_empty():
			var sp: Tile.Special = mines[0]
			t.eq("%s stamps owner, countdown, damage, triggers, source" % c[1],
				[sp.owner, sp.countdown, sp.damage, Array(sp.triggers), sp.program_id, sp.fn_id],
				[P, c[3], c[4], c[5], c[0], c[1]])
		t.eq("%s uses the ordinary placement event" % c[1], x._first(events, Types.EVT.PLACED).get("kind", ""), "mine")

		# D-060 — countdown adjusted once at placement (FLOORIT + HAIRTRIGGER).
		s = _pair("HAK_04", "DEK_01", [c[0]], "SYS_01", "HST_06", 11, ["UPG_09"])
		x._lattice(s)
		_fire(s, c[0])
		mines = x._specials_of(s, Tile.Special.Type.MINE)
		t.eq("%s countdown adjusted at placement" % c[1], mines[0].countdown if not mines.is_empty() else -1, c[3] - 2)

	# Removal class discriminates the two.
	var cases := [
		["slice by the opponent", func(s: GameState, p: Vector2i) -> Array: return _slice_at(s, p, E), "slice_enemy"],
		["slice by the owner", func(s: GameState, p: Vector2i) -> Array: return _slice_at(s, p, P), "slice_owner"],
		["owner Bomb", func(s: GameState, p: Vector2i) -> Array: return _blast_at(s, p, P), "destroy_owner"],
		["opponent Bomb", func(s: GameState, p: Vector2i) -> Array: return _blast_at(s, p, E), "destroy_enemy"],
		["opponent 4-match collateral", func(s: GameState, _p: Vector2i) -> Array: return _four_match(s, E), "destroy_enemy"],
	]
	var fires := {
		"FNC_053": {"slice_enemy": true, "slice_owner": true, "destroy_owner": false, "destroy_enemy": false},
		"FNC_054": {"slice_enemy": false, "slice_owner": false, "destroy_owner": true, "destroy_enemy": true},
	}
	for fn_id in fires:
		var flags: Dictionary = Content.function(fn_id)["plan"][0]["params"]["mine"]
		for c in cases:
			var s := _pair("HAK_04", "DEK_01", ["PRG_H_013"])
			x._lattice(s)
			var p := Vector2i(6, 7) if str(c[0]).contains("4-match") else Vector2i(3, 3)
			var sp: Tile.Special = x._mine(s, p, P, Effects.MINE_FLAG_NAMES.map(func(n): return flags[n]), 3)
			sp.damage = int(Content.function(fn_id)["plan"][0]["params"]["damage"])
			sp.fn_id = fn_id
			sp.program_id = "PRG_H_013" if fn_id == "FNC_053" else "PRG_H_014"
			var events: Array = c[1].call(s, p)
			var trig := x._all(events, Types.EVT.MINE_TRIGGER)
			var want: bool = fires[fn_id][c[2]]
			t.eq("%s %s: classified once as %s" % [fn_id, c[0], c[2]], trig.map(func(e): return e["cause"]), [c[2]])
			var hits := x._damage(events, Types.DamageSource.MINE)
			t.eq("%s %s: %s" % [fn_id, c[0], "fires" if want else "does not fire"], hits.size(), 1 if want else 0)
			if want and not hits.is_empty():
				t.eq("%s %s: hits the System for %d, attributed" % [fn_id, c[0], sp.damage],
					[hits[0]["target"], hits[0]["amount"], hits[0]["fn_id"], hits[0]["program_id"]],
					[E, sp.damage, fn_id, sp.program_id])

	# Expiry: neither authored row damages on expiry.
	for fn_id in ["FNC_053", "FNC_054"]:
		var flags: Dictionary = Content.function(fn_id)["plan"][0]["params"]["mine"]
		var s := _pair("HAK_04", "DEK_01", ["PRG_H_013"])
		x._lattice(s)
		x._mine(s, Vector2i(3, 3), P, Effects.MINE_FLAG_NAMES.map(func(n): return flags[n]), 1)
		var events := Game.new(s).start_player_phase()
		t.eq("%s expiry is silent" % fn_id, x._damage(events, Types.DamageSource.MINE).size(), 0)
		t.eq("%s expiry removes it" % fn_id, x._mines(s).size(), 0)


## A 3-in-row Sync through `p`, resolved by `owner`.
func _slice_at(s: GameState, p: Vector2i, owner: Types.Side) -> Array:
	x._paint(s, [p + Vector2i(-1, 0), p, p + Vector2i(1, 0)], Types.PacketColor.RED, -1)
	var events: Array = []
	Resolve.resolve_cascades(s, owner, events, 1, Types.DamageSource.MATCH, {})
	return events


func _blast_at(s: GameState, p: Vector2i, owner: Types.Side) -> Array:
	var events: Array = []
	Resolve.detonate_at(s, p, {
		"owner": owner, "area_pattern": Areas.SQUARE_3X3, "program_id": "X", "fn_id": "FNC_001",
		"deal_damage": Content.DEAL_DAMAGE_NO, "gain_charge": Content.GAIN_CHARGE_NO,
	}, events, false)
	return events


## A 4-in-row on row 7 whose line clear takes (6, 7) as collateral.
func _four_match(s: GameState, owner: Types.Side) -> Array:
	x._paint(s, [Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7), Vector2i(3, 7)], Types.PacketColor.RED, -1)
	var events: Array = []
	Resolve.resolve_cascades(s, owner, events, 1, Types.DamageSource.MATCH, {})
	return events


# ---------------------------------------------------------------------------
# §14 reused Functions and Bomb rows
# ---------------------------------------------------------------------------

func _test_reused_and_bombs(t: TestCase) -> void:
	t.group("content pass 2 / reused Functions and Bomb rows")
	t.eq("DAMPEN reuses DRAIN", Content.program("PRG_H_021")["fn"]["id"], "FNC_004")
	t.eq("…and targets a System slot", Content.program("PRG_H_021")["fn"]["plan"][0]["target"], Types.TargetKind.UNIT)
	t.eq("CUTTER reuses DATACUT", Content.program("PRG_H_024")["fn"]["id"], "FNC_011")
	t.eq("…and targets a Packet", Content.program("PRG_H_024")["fn"]["plan"][0]["target"], Types.TargetKind.PACKET)

	# DAMPEN drains through the ordinary player path.
	var s := _pair("HAK_01", "DEK_03", ["PRG_H_021"])
	(s.units[E] as Array)[2].charge = 5
	var idx := _player_idx(s, "PRG_H_021")
	(s.units[P] as Array)[idx].charge = 9
	var events := Game.new(s).fire_program(idx, {"kind": Types.TargetKind.UNIT, "idx": 2})
	t.eq("DAMPEN drains the chosen slot", [(s.units[E] as Array)[2].charge, x._first(events, Types.EVT.OP).get("drained", -1)], [0, 5])

	# CUTTER slices the targeted row like NINJA.
	s = _pair("HAK_01", "DEK_04", ["PRG_H_024"])
	idx = _player_idx(s, "PRG_H_024")
	(s.units[P] as Array)[idx].charge = 7
	events = Game.new(s).fire_program(idx, {"kind": Types.TargetKind.PACKET, "p": Vector2i(2, 4)})
	var tg := x._first(events, Types.EVT.TARGETED)
	t.eq("CUTTER slices the whole targeted row", (tg.get("sliced", []) as Array).size(), Constants.BOARD_WIDTH)

	# D-067 polarity on the new Bomb rows.
	for c in [["FNC_066", 2, 2, "AREA_SQUARE_3X3", 1, 1], ["FNC_067", 1, 4, "AREA_SQUARE_5X5", 1, 0],
			["FNC_052", 2, 1, "AREA_SQUARE_3X3", 1, 0], ["FNC_065", 1, 0, "AREA_CARDINAL_1", 1, 1]]:
		var pr: Dictionary = Content.function(c[0])["plan"][0]["params"]
		t.eq("%s quantity/countdown/area/damage/charge" % c[0],
			[pr["quantity"], pr.get("countdown", 0), pr["areaPattern"], pr["bomb"]["dealDamage"], pr["bomb"]["gainCharge"]],
			[c[1], c[2], c[3], c[4], c[5]])
		t.eq("%s is random-placed" % c[0], pr["bomb"]["targeting"], Content.TARGETING_RANDOM)


## §14 / §19.6 — SPARK stays immediate under every countdown adjustment.
func _test_spark(t: TestCase) -> void:
	t.group("content pass 2 / SPARK is immediate")
	for c in [["no modifier", "HST_01", []], ["FLOORIT", "HST_06", []], ["HAIRTRIGGER", "HST_01", ["UPG_09"]], ["both", "HST_06", ["UPG_09"]]]:
		var s := _pair("HAK_01", "DEK_04", ["PRG_H_001"], "SYS_01", str(c[1]), 11, c[2])
		var events := Game.new(s).fire_deck_function()
		t.eq("%s: detonates at once" % c[0], x._count(events, Types.EVT.DETONATE), 1)
		t.eq("%s: parks no overlay" % c[0], x._specials_of(s, Tile.Special.Type.BOMB).size(), 0)
		var adjusted := false
		for ev in events:
			if ev["t"] == Types.EVT.PASSIVE and ev.has("countdown"):
				adjusted = true
		t.check("%s: no countdown adjustment applied" % c[0], not adjusted)
	# The UPGRADE's own Bombs still adjust — the immediate one is just not one.
	var s2 := _pair("HAK_01", "DEK_04", ["PRG_H_022"], "SYS_01", "HST_01", 11, ["UPG_09"])
	x._lattice(s2)
	_fire(s2, "PRG_H_022")
	var bombs := x._specials_of(s2, Tile.Special.Type.BOMB)
	t.eq("CHARGEPACK under HAIRTRIGGER arms at 1", bombs[0].countdown if not bombs.is_empty() else -1, 1)


# ---------------------------------------------------------------------------
# §19.7 Boss Programs with their mechanics
# ---------------------------------------------------------------------------

func _test_boss_programs(t: TestCase) -> void:
	t.group("content pass 2 / Boss Programs fire beside the mechanic")
	for id in BOSSES:
		var want: Array = BOSSES[id]
		# Each Program fires on its own under controlled charge.
		for i in (want[2] as Array).size():
			var s := Session.create_boss_attack(id, Content.BOSS_ATTACK_HOST_ID, 7, Session.default_build())
			for u in (s.units[P] as Array):
				u.charge = 3  # something for a DISABLER to drain
			x._charge_only(s, want[2][i])
			var events: Array = []
			Game.new(s)._run_system_function_phase(events)
			t.eq("%s %s fires" % [id, want[2][i]], x._first(events, Types.EVT.ABILITY).get("program_id", ""), want[2][i])

		# Played out, the Programs and the bespoke mechanic both occur in the
		# same battles. (Every Program firing is the Boss smoke's job; RAHNDAHL's
		# Capacitor ends most bot battles before its 11-cost SHELLER fills.)
		var seen := {}
		var mech := 0
		for seed_value in [1, 2, 3, 4, 5, 6]:
			var s := Session.create_boss_attack(id, Content.BOSS_ATTACK_HOST_ID, seed_value, Session.default_build())
			for ev in _boss_play(s):
				if ev["t"] == Types.EVT.ABILITY and int(ev["side"]) == E and int(ev["owner_kind"]) == Types.OwnerKind.PROGRAM:
					seen[ev["program_id"]] = true
				if ev["t"] == Types.EVT.BOSS_MECHANIC and str(ev["kind"]) == want[3]:
					mech += 1
		t.check("%s mechanic %s still occurs" % [id, want[3]], mech > 0)
		t.check("%s Programs fire during play (%d of 4 seen)" % [id, seen.size()], seen.size() >= 1)


func _boss_play(s: GameState) -> Array:
	var g := Game.new(s)
	var out: Array = []
	for _turn in 40:
		if s.has_winner():
			break
		var mv := Bot.pick_move(s.board, s.config)
		if mv.is_empty():
			break
		out.append_array(g.attempt_swap(mv["a"], mv["b"])["events"])
		if s.has_winner():
			break
		out.append_array(g.run_enemy_phase())
		if s.has_winner():
			break
		out.append_array(g.start_player_phase())
	return out


# ---------------------------------------------------------------------------
# §17 continuation
# ---------------------------------------------------------------------------

func _test_save_resume(t: TestCase) -> void:
	t.group("content pass 2 / save and resume")
	t.eq("battle save schema is 6", SaveState.SCHEMA, 6)
	t.eq("metrics schema is 3", BattleLog.METRICS_SCHEMA_VERSION, 3)

	# 1 — after TRANSFUSE charged Programs, with accounting on.
	var a := Session.create_quick_match("SYS_01", "HST_01", 21,
		_build_with("HAK_02", "DEK_02", ["PRG_H_007", "PRG_H_008"]), {}, true, "HAK_02", "DEK_02")
	Game.new(a).fire_deck_function()
	var b := _round_trip(t, "TRANSFUSE", a)
	if b != null:
		t.eq_seq("TRANSFUSE charges survive", _charges(b), _charges(a))
		t.eq("…and the metrics aggregate", b.metrics.side(P).direct_charge_accepted, a.metrics.side(P).direct_charge_accepted)
		t.eq("…and the health paid", b.metrics.side(P).health_cost_paid, 20)
		t.eq_seq("…and play continues identically", x._play_out(b), x._play_out(a))

	# 2 — after HEAL and a health cost.
	a = _pair("HAK_02", "DEK_02", ["PRG_H_007"])
	a.hp[P] = 60
	_fire(a, "PRG_H_007")
	b = _round_trip(t, "HEAL", a)
	if b != null:
		t.eq("LINK after HEAL survives", b.hp[P], 85)
		t.eq_seq("…and play continues identically", x._play_out(b), x._play_out(a))

	# 3 — a NEEDLE Mine on the board.
	a = _pair("HAK_04", "DEK_01", ["PRG_H_013", "PRG_H_014"])
	_fire(a, "PRG_H_014")
	b = _round_trip(t, "TRIPWIRE", a)
	if b != null:
		var am := x._mines(a)
		t.eq_seq("Mine cells survive", x._mines(b), am)
		if not am.is_empty():
			var sa: Tile.Special = a.board[am[0].y][am[0].x].special
			var sb: Tile.Special = b.board[am[0].y][am[0].x].special
			t.eq("Mine state survives", [sb.owner, sb.countdown, sb.damage, sb.triggers, sb.program_id, sb.fn_id, sb.seq],
				[sa.owner, sa.countdown, sa.damage, sa.triggers, sa.program_id, sa.fn_id, sa.seq])
		t.eq_seq("…and play continues identically", x._play_out(b), x._play_out(a))

	# 4 — a Boss battle on its new loadout, mid-fight.
	for id in BOSSES:
		a = Session.create_boss_attack(id, Content.BOSS_ATTACK_HOST_ID, 5,
			Content.default_build("HAK_04", "DEK_04"), {}, true, "HAK_04", "DEK_04")
		var g := Game.new(a)
		g.start_player_phase()
		for _r in 3:
			if a.has_winner():
				break
			var mv := Bot.pick_move(a.board, a.config)
			if mv.is_empty():
				break
			g.attempt_swap(mv["a"], mv["b"])
			if not a.has_winner():
				g.run_enemy_phase()
			if not a.has_winner():
				g.start_player_phase()
		b = _round_trip(t, id, a)
		if b != null:
			var units_a := []
			var units_b := []
			for u in (a.units[E] as Array):
				units_a.append([u.program_id, u.charge])
			for u in (b.units[E] as Array):
				units_b.append([u.program_id, u.charge])
			t.eq("%s loadout and charge survive" % id, units_b, units_a)
			t.eq("%s Boss state survives" % id, [b.boss_phase, b.hidden_axis], [a.boss_phase, a.hidden_axis])
			t.eq_seq("%s play continues identically" % id, x._play_out(b), x._play_out(a))


func _round_trip(t: TestCase, label: String, a: GameState) -> GameState:
	var restored := SaveState.from_dict(JSON.parse_string(JSON.stringify(SaveState.to_dict(a))))
	t.check("%s save restores" % label, restored["ok"])
	return restored["state"] if restored["ok"] else null


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## A Quick Match for one Hacker/Deck pair whose build starts with `want`.
func _pair(h: String, d: String, want: Array, sys := "SYS_01", host := "HST_01", seed_value := 11, upgrades: Array = []) -> GameState:
	Passives.clear_cache()
	var s := Session.create_quick_match(sys, host, seed_value, _build_with(h, d, want), {}, false, h, d)
	if not upgrades.is_empty():
		s.identity["upgrade_ids"] = upgrades.duplicate()
		s.identity["cache_key"] = "%s|%s" % [s.identity["cache_key"], ":".join(PackedStringArray(upgrades))]
	return s


func _build_with(h: String, d: String, want: Array) -> Array:
	var out := want.duplicate()
	for pid in Content.inventory_program_ids(h, d):
		if out.size() >= Content.ACTIVE_BUILD_SIZE:
			break
		if not out.has(pid):
			out.append(pid)
	return out


## Fires one of the Hacker's Programs through the real activation path.
func _fire(s: GameState, program_id: String) -> Array:
	var idx := _player_idx(s, program_id)
	var u: GameState.UnitState = (s.units[P] as Array)[idx]
	u.charge = int(Content.program(program_id)["cost"])
	return Game.new(s).fire_program(idx)


## Casts a Function for `side` as an anonymous Program, charge aside.
func _cast_fn(s: GameState, side: Types.Side, fn_id: String) -> Array:
	var events: Array = []
	Game.new(s)._cast_actor(side, {
		"kind": Types.OwnerKind.PROGRAM, "id": "PRG_TEST", "name": "TEST", "fn": Content.function(fn_id),
	}, events)
	return events


func _player_idx(s: GameState, program_id: String) -> int:
	var units: Array = s.units[P]
	for i in units.size():
		if units[i].program_id == program_id:
			return i
	return -1


func _player_unit(s: GameState, program_id: String) -> GameState.UnitState:
	return (s.units[P] as Array)[_player_idx(s, program_id)]


func _charges(s: GameState) -> Array:
	var out := []
	for u in (s.units[P] as Array):
		out.append(u.charge)
	return out


func _sorted(a: Array) -> Array:
	var out := a.duplicate()
	out.sort()
	return out
