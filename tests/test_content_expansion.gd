extends RefCounted

## Beta 0.5 — the initial content expansion (authorization §18).
##
## Live content only. The alpha differential still runs, against the frozen
## alpha-era datasets (`test_load.gd`, `test_csv.gd`, `test_route.gd`); this
## file is the oracle for everything the alpha never had, so every assertion is
## the authorization read back rather than a comparison.
##
## Boards are AUTHORED, not played to. `_lattice` lays a board on which no two
## neighbours share a colour or a shape, so a test can drop exactly the Sync it
## means onto it — and every such fixture asserts its own precondition, because
## a test whose board never reaches the edge it names passes vacuously
## (lessons-learned §2).

## Workbook values, read back. If these drift the workbook changed, and the
## change should be deliberate.
const LIVE_FINGERPRINT := "ce01939e-fwf"
const LIVE_WARNINGS := 18

const RED := Types.PacketColor.RED
const BLUE := Types.PacketColor.BLUE
const TRI := Types.PacketShape.TRIANGLE



func run(t: TestCase) -> void:
	var loader := ContentLoader.new()
	var result := loader.load_all()
	if not result["ok"]:
		t.group("content expansion")
		t.check("content loads", false)
		return
	Content.set_active(result["content"])
	Passives.clear_cache()

	_test_counts_and_pools(t, loader, result)
	_test_strong_sets(t)
	_test_names(t)
	_test_loader_contracts(t)

	_test_stomp(t)
	_test_forage(t)
	_test_system_auto_target(t)

	_test_volatile_placement(t)
	_test_mine_placement_limits(t)
	_test_mine_countdown(t)
	_test_mine_slices(t)
	_test_mine_disabled_destruction(t)
	_test_mine_enabled_destruction(t)
	_test_mine_expiry(t)
	_test_mine_damage_pipeline(t)
	_test_mine_save_resume(t)

	_test_countdown_adjust(t)
	_test_ability_rate(t)
	_test_drop_rate(t)
	_test_self_damage(t)
	_test_match_damage_selector(t)
	_test_strong_slice_bonus(t)
	_test_transform_to_neutral(t)

	Content.clear()
	Passives.clear_cache()


# ---------------------------------------------------------------------------
# §18.1 content and pools
# ---------------------------------------------------------------------------

func _test_counts_and_pools(t: TestCase, loader: ContentLoader, result: Dictionary) -> void:
	t.group("content expansion / counts and pools")
	t.eq("live fingerprint is pinned", str(result["fingerprint"]), LIVE_FINGERPRINT)
	t.eq("load warnings are the expected set", loader.issues.warning_count, LIVE_WARNINGS)
	t.eq("no load errors", loader.issues.error_count, 0)

	t.eq("11 System rows", Content.all_systems().size(), 11)
	t.eq("10 HOST rows", Content.all_hosts().size(), 10)
	t.eq("10 UPGRADE rows", Content.all_upgrades().size(), 10)
	t.eq("26 System Programs", Content.programs_for(Types.Side.ENEMY).size(), 26)
	t.eq("40 Functions", loader.function_rows.size(), 40)
	t.eq("20 PASSIVEs", loader.passive_rows.size(), 20)

	var pool_sys := []
	for s in Content.pool_systems():
		pool_sys.append(str(s["id"]))
	t.eq("10 Systems in the random pool", pool_sys.size(), 10)
	t.check("DOORMAN is not in the random pool", not pool_sys.has(Content.INITIAL_SYSTEM_ID))

	var pool_hst := []
	for h in Content.pool_hosts():
		pool_hst.append(str(h["id"]))
	t.eq("9 HOSTs in the random pool", pool_hst.size(), 9)
	t.check("THRESHOLD is not in the random pool", not pool_hst.has(Content.INITIAL_HOST_ID))

	# Every System fields exactly four valid Programs whose Functions resolve.
	for s in Content.all_systems():
		t.eq("%s fields four Programs" % s["id"], (s["programs"] as Array).size(), Content.SYSTEM_BUILD_SIZE)
		for pid in (s["programs"] as Array):
			var prog := Content.program(str(pid))
			t.check("%s Program %s resolves to a plan" % [s["id"], pid], not (prog["fn"]["plan"] as Array).is_empty())

	# §3.4 — Battle 1 stays DOORMAN on THRESHOLD whatever the pools hold.
	for seed_value in [0, 1, 7, 42, 1337]:
		var p := Route.initial_path_offers(Rng.new(seed_value), [])
		for o in p.offers:
			t.eq("seed %d Battle 1 System" % seed_value, o.opponent_id, Content.INITIAL_SYSTEM_ID)
			t.eq("seed %d Battle 1 HOST" % seed_value, o.host_id, Content.INITIAL_HOST_ID)

	# All ten UPGRADEs are offerable: drawn often enough, every one appears.
	var seen := {}
	for seed_value in 200:
		var picked := Route.pick_offer_upgrades(Rng.new(seed_value), [])
		for id in (picked["ids"] as Array):
			seen[id] = true
	t.eq("every UPGRADE is eligible as a reward", seen.size(), 10)


func _test_strong_sets(t: TestCase) -> void:
	t.group("content expansion / authored strong sets")
	# §2 — the workbook deliberately changed SYS_01-03 and the Boss rows; these
	# are its values, not the alpha's.
	var want := {
		"SYS_01": [["YEL", "BLU", "MAG"], ["TRI", "STR", "CRO"]],
		"SYS_02": [["GRE", "YEL", "BLU"], ["TRI", "SQU", "CIR"]],
		"SYS_03": [["RED", "YEL", "BLU"], ["TRI", "STR", "CIR"]],
	}
	for id in want:
		var s := Content.system(id)
		t.eq_seq("%s strong colours" % id, s["strong_colors"], _tokens(want[id][0], Vocab.COLOR_TOKENS))
		t.eq_seq("%s strong shapes" % id, s["strong_shapes"], _tokens(want[id][1], Vocab.SHAPE_TOKENS))
	for b in Content.all_bosses():
		t.eq_seq("%s strong colours" % b["id"], b["strong_colors"], _tokens(["GRE", "YEL", "BLU"], Vocab.COLOR_TOKENS))


func _tokens(names: Array, vocab: Dictionary) -> Array:
	var out := []
	for n in names:
		out.append(vocab[n])
	return out


func _test_names(t: TestCase) -> void:
	t.group("content expansion / names resolve through text_content")
	var ids := []
	for s in Content.all_systems():
		ids.append([Text.SYSTEM_NAME, s["id"], s["name"]])
	for h in Content.all_hosts():
		ids.append([Text.HOST_NAME, h["id"], h["name"]])
	for u in Content.all_upgrades():
		ids.append([Text.UPGRADE_NAME, u["id"], u["name"]])
	for p in Content.programs_for(Types.Side.ENEMY):
		ids.append([Text.PROGRAM_NAME, p["id"], p["name"]])
		ids.append([Text.FUNCTION_NAME, p["fn"]["id"], p["fn"]["name"]])
	for row in ids:
		var got := Text.get_text(str(row[0]), str(row[1]))
		t.eq("%s/%s" % [row[0], row[1]], got, str(row[2]))

	# Every PASSIVE a current HOST or UPGRADE supplies has display text, with
	# its placeholders expanded and no literal % left over from the template.
	for src in Content.all_hosts() + Content.all_upgrades():
		for p in (src.get("passives", []) as Array):
			if p["effect_type"] == PassiveEffects.CARRIER:
				continue
			var shown := str(p["display"])
			t.check("%s %s has display text" % [src["id"], p["id"]], shown != "")
			t.check("%s %s expanded every placeholder" % [src["id"], p["id"]], not shown.contains("%0") and not shown.contains("%1"))
	t.eq("PSV_011 reads as authored", str(Content.passive("PSV_011")["display"]), "Ability damage +50%")
	t.eq("PSV_017 reads as authored", str(Content.passive("PSV_017")["display"]), "Enemy ability damage -25%")
	t.eq("PSV_012 reads as authored", str(Content.passive("PSV_012")["display"]), "Red packets drop 15% more often")
	t.eq("PSV_010 reads as authored", str(Content.passive("PSV_010")["display"]), "New countdowns adjusted by -1")


## §14 — malformed new content fails loudly; the narrow cases a live row
## cannot exercise are driven through the validators directly.
func _test_loader_contracts(t: TestCase) -> void:
	t.group("content expansion / Mine and PASSIVE contracts")
	var ctx := {"dataset": DataIssues.DATASET_FUNCTIONS, "file": "test", "row": 1, "id": "FNC_900"}
	var mine := Effects.contract(Effects.MINE)

	var l := ContentLoader.new()
	var out := {}
	t.check("all-zero Mine tuple is accepted", l._resolve_tuple({"tuple_raw": "0:0:0:0:0:0"}, mine, Effects.MINE, ctx, out))
	t.eq("…with a warning", l.issues.warning_count, 1)
	t.eq("…and no error", l.issues.error_count, 0)

	for bad in ["1:1:0:0:0", "1:1:0:0:0:0:0", "2:0:0:0:0:0", "1:x:0:0:0:0"]:
		l = ContentLoader.new()
		t.check("Mine tuple %s is rejected" % bad, not l._resolve_tuple({"tuple_raw": bad}, mine, Effects.MINE, ctx, {}))

	var cols := {"quantity": "4", "countdown": "0", "areaPattern": "", "magnitude": "", "damage": "0"}
	l = ContentLoader.new()
	out = {}
	t.check("countdown 0 and damage 0 are legal", l._resolve_discrete_params({"params": cols}, mine, Effects.MINE, ctx, out))
	t.eq("…and resolve to 0", [out.get("countdown"), out.get("damage")], [0, 0])
	cols = cols.duplicate()
	cols["quantity"] = "0"
	l = ContentLoader.new()
	t.check("quantity 0 is rejected", not l._resolve_discrete_params({"params": cols}, mine, Effects.MINE, ctx, {}))
	cols["quantity"] = "1"
	cols["countdown"] = "-1"
	l = ContentLoader.new()
	t.check("a negative countdown is rejected", not l._resolve_discrete_params({"params": cols}, mine, Effects.MINE, ctx, {}))

	# Sequential Effects share one row; a column two of them claim is an error.
	l = ContentLoader.new()
	var stomp := l._merged_contract([Effects.ATTACK, Effects.BOMB], ctx)
	t.eq("ATTACK:BOMB merges with the Bomb owning the tuple", str(stomp.get("tuple_effect", "")), Effects.BOMB)
	t.check("BOMB:BOMB is rejected", l._merged_contract([Effects.BOMB, Effects.BOMB], ctx).is_empty())

	var cases := [
		[PassiveEffects.COUNTDOWN_ADJUST, "-1", true, "magnitude", -1],
		[PassiveEffects.COUNTDOWN_ADJUST, "+2", true, "magnitude", 2],
		[PassiveEffects.COUNTDOWN_ADJUST, "1:1", false, "", null],
		[PassiveEffects.ABILITY_DAMAGE_RATE, "-25", true, "magnitude", -25],
		[PassiveEffects.ABILITY_DAMAGE_RATE, "ALL", false, "", null],
		[PassiveEffects.PACKET_DROP_RATE, "15:RED", true, "color", RED],
		[PassiveEffects.PACKET_DROP_RATE, "15:TRI", true, "shape", TRI],
		[PassiveEffects.PACKET_DROP_RATE, "15:ALL", false, "", null],
		[PassiveEffects.PACKET_DROP_RATE, "15", false, "", null],
		[PassiveEffects.SELF_DAMAGE, "0", true, "magnitude", 0],
		[PassiveEffects.SELF_DAMAGE, "-1", false, "", null],
		[PassiveEffects.STRONG_SLICE_BONUS, "1", true, "magnitude", 1],
		[PassiveEffects.STRONG_SLICE_BONUS, "0", false, "", null],
		[PassiveEffects.EXTRA_MATCH_DAMAGE, "ALL:1", true, "all_scope", true],
		[PassiveEffects.EXTRA_MATCH_DAMAGE, "TRI:1", true, "shape", TRI],
		[PassiveEffects.EXTRA_MATCH_DAMAGE, "NOPE:1", false, "", null],
	]
	var pctx := {"dataset": DataIssues.DATASET_PASSIVES, "file": "test", "row": 1, "id": "PSV_900"}
	for c in cases:
		l = ContentLoader.new()
		var r := l._check_passive_params(str(c[1]), str(c[0]), PassiveEffects.contract(str(c[0])), pctx)
		t.eq("%s %s accepted" % [c[0], c[1]], bool(r["ok"]), bool(c[2]))
		if c[2]:
			t.eq("%s %s resolves %s" % [c[0], c[1], c[3]], r[c[3]], c[4])


# ---------------------------------------------------------------------------
# §18.2 Function composition
# ---------------------------------------------------------------------------

func _test_stomp(t: TestCase) -> void:
	t.group("content expansion / STOMP runs ATTACK then BOMB")
	var plan: Array = Content.function("FNC_025")["plan"]
	t.eq("two ops", plan.size(), 2)
	t.eq_seq("in authored order", [plan[0]["effect_id"], plan[1]["effect_id"]], [Effects.ATTACK, Effects.BOMB])
	t.eq("both under one Function identity", [plan[0]["fn_id"], plan[1]["fn_id"]], ["FNC_025", "FNC_025"])
	# The ATTACK must not read its sibling Bomb's targeting from the shared row.
	t.eq("the ATTACK is not targeted", plan[0]["target"], Types.TargetKind.NONE)

	var s := _state("SYS_05", "HST_01")
	var g := Game.new(s)
	_charge_only(s, "PRG_S_011")
	var before: int = s.hp[Types.Side.PLAYER]
	var events: Array = []
	g._run_system_function_phase(events)

	var ops := []
	for ev in events:
		if ev["t"] == Types.EVT.OP and ev.get("fn_id", "") == "FNC_025":
			ops.append(ev["effect_id"])
	t.eq_seq("ATTACK fires before BOMB", ops, [Effects.ATTACK, Effects.BOMB])
	t.eq("one activation", _count(events, Types.EVT.ABILITY), 1)
	t.eq("cost paid exactly once", _unit(s, "PRG_S_011").charge, 0)
	var attack := _damage(events, Types.DamageSource.ATTACKER)
	t.eq("the ATTACK deals its authored 12", attack[0]["amount"] if not attack.is_empty() else -1, 12)
	t.check("the Bomb detonated", _count(events, Types.EVT.DETONATE) == 1)
	t.check("LINK fell", s.hp[Types.Side.PLAYER] < before)

	# A lethal first Effect ends the sequence before the Bomb.
	s = _state("SYS_05", "HST_01")
	g = Game.new(s)
	_charge_only(s, "PRG_S_011")
	s.hp[Types.Side.PLAYER] = 5
	events = []
	g._run_system_function_phase(events)
	t.eq("a lethal ATTACK wins the battle", s.winner, Types.Side.ENEMY)
	t.eq("and the Bomb never detonates", _count(events, Types.EVT.DETONATE), 0)


func _test_forage(t: TestCase) -> void:
	t.group("content expansion / FORAGE chains without child costs")
	var s := _state("SYS_05", "HST_01")
	_lattice(s)
	var g := Game.new(s)
	_charge_only(s, "PRG_S_013")
	var events: Array = []
	g._run_system_function_phase(events)
	var fns := []
	for ev in events:
		if ev["t"] == Types.EVT.TRANSFORM:
			fns.append(ev["fn_id"])
	t.eq_seq("FORAGECOLOR then FORAGESHAPE", fns, ["FNC_028", "FNC_029"])
	# The transforms create Syncs that legitimately charge FORAGE again, so
	# "paid once" means: what is left is exactly what was routed back in.
	var routed := 0
	for ev in events:
		if ev["t"] == Types.EVT.CHARGE_ROUTE:
			for a in (ev["assignments"] as Array):
				if a["program_id"] == "PRG_S_013":
					routed += int(a["assigned"])
	t.eq("the parent's cost is paid once", _unit(s, "PRG_S_013").charge, routed)
	t.eq("chained child costs are zero", [int(Content.function("FNC_028")["cost"]), int(Content.function("FNC_029")["cost"])], [0, 0])


## Director ruling Q3: a System casting a targeted Function picks a random valid
## target instead of fizzling for want of one.
func _test_system_auto_target(t: TestCase) -> void:
	t.group("content expansion / System auto-targets SPOTTER")
	t.eq("SPOTTER is authored targeted", Content.function("FNC_032")["plan"][0]["target"], Types.TargetKind.PACKET)
	var s := _state("SYS_06", "HST_01")
	var g := Game.new(s)
	_charge_only(s, "PRG_S_017")
	var events: Array = []
	g._run_system_function_phase(events)
	var hits := []
	for ev in events:
		if ev["t"] == Types.EVT.TARGETED and ev["fn_id"] == "FNC_032":
			hits.append(ev)
	t.eq("one targeted deployment", hits.size(), 1)
	if not hits.is_empty():
		t.check("with a real coordinate", hits[0]["target"] != null)
		t.check("that resolved", bool(hits[0]["resolved"]))
		t.check("and dealt damage (SPOTTER deals, never charges)", int(hits[0]["direct_damage"]) > 0)


# ---------------------------------------------------------------------------
# §18.3 EFFECT_MINE
# ---------------------------------------------------------------------------

func _test_volatile_placement(t: TestCase) -> void:
	t.group("content expansion / VOLATILE places four Mines")
	var s := _state("SYS_04", "HST_01")
	var looks := {}
	for row in s.board:
		for tile in row:
			if tile != null and not tile.is_neutral():
				looks[tile.id] = [tile.color, tile.shape]

	var events := _cast(s, Types.Side.ENEMY, "PRG_S_009")
	var mines := _mines(s)
	t.eq("four Mines", mines.size(), 4)
	for p in mines:
		var tile: Tile = s.board[p.y][p.x]
		var sp := tile.special
		t.eq("Mine at %s is the System's" % p, sp.owner, Types.Side.ENEMY)
		t.eq("Mine at %s countdown 4" % p, sp.countdown, 4)
		t.eq("Mine at %s damage 20" % p, sp.damage, 20)
		t.eq_seq("Mine at %s flags" % p, sp.triggers, [1, 1, 0, 0, 0, 0])
		t.eq("Mine at %s attributed" % p, [sp.program_id, sp.fn_id], ["PRG_S_009", "FNC_023"])
		t.eq("Mine at %s keeps its carrier's colour and shape" % p, [tile.color, tile.shape], looks.get(tile.id, []))
	var placed := []
	for ev in events:
		if ev["t"] == Types.EVT.PLACED:
			placed.append(ev)
	t.check("the placement is recorded as Mines", placed.size() == 1 and str(placed[0]["kind"]) == "mine")


func _test_mine_placement_limits(t: TestCase) -> void:
	t.group("content expansion / Mine placement is the ordinary contract")
	# Pre-existing overlays and neutrals are never candidates.
	var s := _state("SYS_04", "HST_01")
	_lattice(s)
	for x in Constants.BOARD_WIDTH:
		_neutral(s, Vector2i(x, 0))
		_special(s, Vector2i(x, 1), Tile.Special.Type.SHIELD, Types.Side.PLAYER)
	_cast(s, Types.Side.ENEMY, "PRG_S_009")
	for x in Constants.BOARD_WIDTH:
		t.check("row 0 neutral %d stays bare" % x, not s.board[0][x].has_special())
		t.eq("row 1 Shield %d is not overwritten" % x, s.board[1][x].special.type, Tile.Special.Type.SHIELD)
	t.eq("four Mines still placed", _mines(s).size(), 4)

	# Fewer valid targets than quantity: place what fits, waste the rest.
	s = _state("SYS_04", "HST_01")
	_lattice(s)
	for y in Constants.BOARD_HEIGHT:
		for x in Constants.BOARD_WIDTH:
			if not (y == 7 and x < 2):
				_neutral(s, Vector2i(x, y))
	var events := _cast(s, Types.Side.ENEMY, "PRG_S_009")
	t.eq("only two Mines fit", _mines(s).size(), 2)
	var op := _first(events, Types.EVT.OP)
	t.check("the activation still resolves", not op.is_empty() and bool(op["resolved"]))


func _test_mine_countdown(t: TestCase) -> void:
	t.group("content expansion / Mine countdowns tick on the controller's turn")
	var s := _state("SYS_04", "HST_01")
	_lattice(s)
	var a := _mine(s, Vector2i(0, 0), Types.Side.ENEMY, [1, 1, 0, 0, 0, 0], 3)
	var b := _mine(s, Vector2i(5, 5), Types.Side.ENEMY, [1, 1, 0, 0, 0, 0], 1)
	var g := Game.new(s)
	g.start_player_phase()
	t.eq("the Hacker's turn does not tick a System Mine", a.countdown, 3)
	var events: Array = []
	g._tick_countdowns(Types.Side.ENEMY, events)
	t.eq("the System's turn does", a.countdown, 2)
	var ticks := []
	for ev in events:
		if ev["t"] == Types.EVT.COUNTDOWN:
			ticks.append(ev["p"])
	t.eq_seq("oldest placement first", ticks, [Vector2i(0, 0), Vector2i(5, 5)])
	t.check("an expired Mine is not parked at 0", not s.board[5][5].has_special() and b.countdown == 0)


func _test_mine_slices(t: TestCase) -> void:
	t.group("content expansion / VOLATILE fires when sliced by either side")
	for owner in [Types.Side.ENEMY, Types.Side.PLAYER]:
		var s := _state("SYS_04", "HST_01")
		_lattice(s)
		_paint(s, [Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7)], RED, -1)
		_mine(s, Vector2i(1, 7), Types.Side.ENEMY, [1, 1, 0, 0, 0, 0], 4)
		t.eq("fixture: exactly one Sync", MatchFinder.detect(s.board).size(), 1)

		var events: Array = []
		Resolve.resolve_cascades(s, owner, events, 1, Types.DamageSource.MATCH, {})
		var who := "controller" if owner == Types.Side.ENEMY else "opponent"
		var trig := _all(events, Types.EVT.MINE_TRIGGER)
		t.eq("%s slice: one trigger" % who, trig.size(), 1)
		if not trig.is_empty():
			t.eq("%s slice: cause" % who, trig[0]["cause"], "slice_owner" if owner == Types.Side.ENEMY else "slice_enemy")
			t.check("%s slice: enabled" % who, bool(trig[0]["enabled"]))
		var mine_hits := _damage(events, Types.DamageSource.MINE)
		t.eq("%s slice: one Mine damage instance" % who, mine_hits.size(), 1)
		if not mine_hits.is_empty():
			t.eq("%s slice: to the Hacker, the non-controller" % who, mine_hits[0]["target"], Types.Side.PLAYER)
			t.eq("%s slice: for its authored 20" % who, mine_hits[0]["amount"], 20)
			t.eq("%s slice: attributed to VOLATILE" % who, mine_hits[0]["fn_id"], "FNC_023")
			# Ruling Q7 — the slice's own damage lands first.
			var sync_at := _index_of_damage(events, Types.DamageSource.MATCH)
			var mine_at := events.find(mine_hits[0])
			t.check("%s slice: Sync damage precedes Mine damage" % who, sync_at >= 0 and sync_at < mine_at)

	# One removal, one trigger — even when the Packet is in two Syncs at once.
	var s2 := _state("SYS_04", "HST_01")
	_lattice(s2)
	_paint(s2, [Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7)], RED, TRI)
	_mine(s2, Vector2i(1, 7), Types.Side.ENEMY, [1, 1, 0, 0, 0, 0], 4)
	t.eq("fixture: a colour AND a shape Sync over the same cells", MatchFinder.detect(s2.board).size(), 2)
	var ev2: Array = []
	Resolve.resolve_cascades(s2, Types.Side.PLAYER, ev2, 1, Types.DamageSource.MATCH, {})
	t.eq("double-labelled removal triggers once", _all(ev2, Types.EVT.MINE_TRIGGER).size(), 1)

	# A Sync a HOST carrier set up is still the active agent's Sync: its Mine
	# slices are theirs, never `destroy_host` (found by the smoke matrix).
	var s4 := _state("SYS_04", "HST_05")
	_lattice(s4)
	_paint(s4, [Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7)], RED, -1)
	_mine(s4, Vector2i(1, 7), Types.Side.ENEMY, [1, 1, 0, 0, 0, 0], 4)
	s4.host_actor = true
	var ev4: Array = []
	Resolve.resolve_cascades(s4, Types.Side.PLAYER, ev4, 1, Types.DamageSource.MATCH, {})
	s4.host_actor = false
	var trig4 := _first(ev4, Types.EVT.MINE_TRIGGER)
	t.eq("a Sync during a HOST carrier is the agent's slice", trig4.get("cause", ""), "slice_enemy")
	t.eq("…so VOLATILE fires", _damage(ev4, Types.DamageSource.MINE).size(), 1)

	# A lethal slice ends the battle before the Mine it sets off can fire.
	var s3 := _state("SYS_04", "HST_01")
	_lattice(s3)
	_paint(s3, [Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7)], RED, -1)
	_mine(s3, Vector2i(1, 7), Types.Side.ENEMY, [1, 1, 0, 0, 0, 0], 4)
	s3.hp[Types.Side.ENEMY] = 1
	var ev3: Array = []
	Resolve.resolve_cascades(s3, Types.Side.PLAYER, ev3, 1, Types.DamageSource.MATCH, {})
	t.eq("the Hacker's lethal Sync wins", s3.winner, Types.Side.PLAYER)
	t.eq("and the Mine never fires", _damage(ev3, Types.DamageSource.MINE).size(), 0)


func _test_mine_disabled_destruction(t: TestCase) -> void:
	t.group("content expansion / VOLATILE ignores its disabled categories")
	for c in _destruction_cases():
		var s := _state("SYS_04", "HST_01")
		_lattice(s)
		_mine(s, c["mine_at"], Types.Side.ENEMY, [1, 1, 0, 0, 0, 0], 4)
		var events: Array = c["run"].call(s)
		var trig := _all(events, Types.EVT.MINE_TRIGGER)
		t.eq("%s: classified once" % c["name"], trig.size(), 1)
		if not trig.is_empty():
			t.eq("%s: as %s" % [c["name"], c["cause"]], trig[0]["cause"], c["cause"])
			t.check("%s: disabled" % c["name"], not bool(trig[0]["enabled"]))
		t.eq("%s: no Mine damage" % c["name"], _damage(events, Types.DamageSource.MINE).size(), 0)


## Every destruction category, synthetic, with every flag ON — current content
## enables none of them, so this is their only coverage.
func _test_mine_enabled_destruction(t: TestCase) -> void:
	t.group("content expansion / every enabled destruction category fires")
	for c in _destruction_cases():
		var s := _state("SYS_04", "HST_01")
		_lattice(s)
		_mine(s, c["mine_at"], Types.Side.ENEMY, [1, 1, 1, 1, 1, 1], 4)
		var events: Array = c["run"].call(s)
		var hits := _damage(events, Types.DamageSource.MINE)
		t.eq("%s: one Mine damage" % c["name"], hits.size(), 1)
		if not hits.is_empty():
			t.eq("%s: cause recorded" % c["name"], hits[0].get("mine_cause", ""), c["cause"])


func _destruction_cases() -> Array:
	return [
		{
			"name": "System Bomb", "cause": "destroy_owner", "mine_at": Vector2i(3, 3),
			"run": func(s: GameState) -> Array: return _blast(s, Types.Side.ENEMY),
		},
		{
			"name": "Hacker Bomb", "cause": "destroy_enemy", "mine_at": Vector2i(3, 3),
			"run": func(s: GameState) -> Array: return _blast(s, Types.Side.PLAYER),
		},
		{
			"name": "HOST-sourced blast", "cause": "destroy_host", "mine_at": Vector2i(3, 3),
			"run": func(s: GameState) -> Array:
				s.host_actor = true
				var ev := _blast(s, Types.Side.PLAYER)
				s.host_actor = false
				return ev,
		},
		{
			# Ruling Q6 — line-clear collateral is destruction, not a slice.
			"name": "line-clear collateral", "cause": "destroy_enemy", "mine_at": Vector2i(6, 7),
			"run": func(s: GameState) -> Array:
				_paint(s, [Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7), Vector2i(3, 7)], RED, -1)
				var ev: Array = []
				Resolve.resolve_cascades(s, Types.Side.PLAYER, ev, 1, Types.DamageSource.MATCH, {})
				return ev,
		},
		{
			"name": "Transform stripping", "cause": "destroy_enemy", "mine_at": Vector2i(3, 3),
			"run": func(s: GameState) -> Array:
				var ev: Array = []
				Resolve.apply_transform(s, _smog_spec(Types.Side.PLAYER, 99), ev)
				return ev,
		},
	]


func _blast(s: GameState, owner: Types.Side) -> Array:
	var ev: Array = []
	Resolve.detonate_at(s, Vector2i(3, 3), {
		"owner": owner, "area_pattern": Areas.SQUARE_3X3, "program_id": "X", "fn_id": "FNC_001",
		"deal_damage": Content.DEAL_DAMAGE_NO, "gain_charge": Content.GAIN_CHARGE_NO,
	}, ev, false)
	return ev


func _test_mine_expiry(t: TestCase) -> void:
	t.group("content expansion / Mine expiry")
	var s := _state("SYS_04", "HST_01")
	_lattice(s)
	var p := Vector2i(4, 4)
	var carrier: Tile = s.board[p.y][p.x]
	var look := [carrier.id, carrier.color, carrier.shape]
	_mine(s, p, Types.Side.ENEMY, [1, 1, 0, 0, 0, 0], 1)
	var events: Array = []
	Game.new(s)._tick_countdowns(Types.Side.ENEMY, events)
	var tile: Tile = s.board[p.y][p.x]
	t.check("the overlay is gone", not tile.has_special())
	t.eq("the carrier Packet stays, unchanged", [tile.id, tile.color, tile.shape], look)
	t.eq("VOLATILE expires harmlessly", _damage(events, Types.DamageSource.MINE).size(), 0)
	var trig := _first(events, Types.EVT.MINE_TRIGGER)
	t.check("the expiry is recorded as disabled", not trig.is_empty() and trig["cause"] == "expire" and not trig["enabled"])

	s = _state("SYS_04", "HST_01")
	_lattice(s)
	_mine(s, p, Types.Side.ENEMY, [0, 0, 0, 0, 0, 1], 1)
	events = []
	var before: int = s.hp[Types.Side.PLAYER]
	Game.new(s)._tick_countdowns(Types.Side.ENEMY, events)
	t.eq("an expiry-enabled Mine deals its damage", before - s.hp[Types.Side.PLAYER], 20)
	t.check("and leaves the carrier", s.board[p.y][p.x] != null and not s.board[p.y][p.x].has_special())


func _test_mine_damage_pipeline(t: TestCase) -> void:
	t.group("content expansion / Mine damage uses the ordinary funnel")
	var cases := [
		["THRESHOLD", "HST_01", [], 0, 20],
		["MEGATON +50%", "HST_07", [], 0, 30],
		["BULWARK -25%", "HST_01", ["UPG_10"], 0, 15],
		["MEGATON + BULWARK sum to +25%", "HST_07", ["UPG_10"], 0, 25],
		["Shield 5 after the rate", "HST_07", [], 5, 25],
	]
	for c in cases:
		var s := _state("SYS_04", str(c[1]), c[2])
		_lattice(s)
		if int(c[3]) > 0:
			_special(s, Vector2i(7, 0), Tile.Special.Type.SHIELD, Types.Side.PLAYER, int(c[3]))
		_mine(s, Vector2i(2, 2), Types.Side.ENEMY, [0, 0, 0, 0, 0, 1], 1)
		var before: int = s.hp[Types.Side.PLAYER]
		Game.new(s)._tick_countdowns(Types.Side.ENEMY, [])
		t.eq(str(c[0]), before - s.hp[Types.Side.PLAYER], int(c[4]))


## §16 — a live Mine and a live PASSIVE survive save and resume, and the resumed
## battle plays out exactly as the uninterrupted one.
func _test_mine_save_resume(t: TestCase) -> void:
	t.group("content expansion / save and resume with live Mines")
	for seed_value in [5, 17, 29]:
		var a := _state("SYS_04", "HST_06", ["UPG_09"], seed_value)
		_cast(a, Types.Side.ENEMY, "PRG_S_009")
		t.check("seed %d fixture has live Mines" % seed_value, _mines(a).size() > 0)

		var raw := SaveState.to_dict(a)
		var restored := SaveState.from_dict(raw)
		t.check("seed %d restores" % seed_value, restored["ok"])
		if not restored["ok"]:
			continue
		var b: GameState = restored["state"]
		var am := _mines(a)
		var bm := _mines(b)
		t.eq_seq("seed %d Mine cells survive" % seed_value, bm, am)
		if not am.is_empty() and not bm.is_empty():
			var sa: Tile.Special = a.board[am[0].y][am[0].x].special
			var sb: Tile.Special = b.board[bm[0].y][bm[0].x].special
			t.eq("seed %d Mine state survives" % seed_value,
				[sb.owner, sb.countdown, sb.damage, sb.triggers, sb.program_id, sb.fn_id, sb.seq],
				[sa.owner, sa.countdown, sa.damage, sa.triggers, sa.program_id, sa.fn_id, sa.seq])
		t.eq_seq("seed %d upgrades survive" % seed_value, b.identity["upgrade_ids"], ["UPG_09"])
		t.eq_seq("seed %d continues identically" % seed_value, _play_out(b), _play_out(a))


# ---------------------------------------------------------------------------
# §18.4 countdown adjust
# ---------------------------------------------------------------------------

func _test_countdown_adjust(t: TestCase) -> void:
	t.group("content expansion / PSV_COUNTDOWN_ADJUST")
	var cases := [
		# [label, host, upgrades, side, authored, expect]
		["no modifier", "HST_01", [], Types.Side.PLAYER, 3, 3],
		["FLOORIT shortens the Hacker's", "HST_06", [], Types.Side.PLAYER, 3, 2],
		["FLOORIT shortens the System's", "HST_06", [], Types.Side.ENEMY, 3, 2],
		["HAIRTRIGGER shortens the Hacker's", "HST_01", ["UPG_09"], Types.Side.PLAYER, 3, 2],
		["HAIRTRIGGER leaves the System's", "HST_01", ["UPG_09"], Types.Side.ENEMY, 3, 3],
		["FLOORIT + HAIRTRIGGER: Hacker -2", "HST_06", ["UPG_09"], Types.Side.PLAYER, 3, 1],
		["FLOORIT + HAIRTRIGGER: System -1", "HST_06", ["UPG_09"], Types.Side.ENEMY, 3, 2],
	]
	for c in cases:
		var s := _state("SYS_01", str(c[1]), c[2])
		_lattice(s)
		var g := Game.new(s)
		g._place_specials(_bomb_opts(int(c[3]), int(c[4])), [])
		var bombs := _specials_of(s, Tile.Special.Type.BOMB)
		t.eq(str(c[0]), bombs[0].countdown if not bombs.is_empty() else -99, int(c[5]))

	# PSV_018 (+1, ENEMY) is authored but unreferenced: injected to prove it.
	var s := _state("SYS_01", "HST_01")
	_inject(s, ["PSV_018"], Types.Side.PLAYER)
	_lattice(s)
	Game.new(s)._place_specials(_bomb_opts(Types.Side.ENEMY, 3), [])
	t.eq("PSV_018 slows the enemy's countdowns", _specials_of(s, Tile.Special.Type.BOMB)[0].countdown, 4)

	# Floored at 0, and 0 resolves NOW — for each countdown special type.
	s = _state("SYS_01", "HST_06", ["UPG_09"])
	_lattice(s)
	var events: Array = []
	Game.new(s)._place_specials(_bomb_opts(Types.Side.PLAYER, 1), events)
	t.eq("a Bomb adjusted to 0 detonates at once", _count(events, Types.EVT.DETONATE), 1)
	t.eq("and is not parked", _specials_of(s, Tile.Special.Type.BOMB).size(), 0)

	s = _state("SYS_01", "HST_06", ["UPG_09"])
	_lattice(s)
	Game.new(s)._place_specials({
		"type": Tile.Special.Type.BUFF, "owner": Types.Side.PLAYER, "count": 1, "countdown": 1,
		"magnitude": 4, "delivers": Effects.BUFF, "fn_id": "FNC_034", "actor": {"kind": Types.OwnerKind.PROGRAM, "id": "X"},
	}, [])
	var buffs := _specials_of(s, Tile.Special.Type.BUFF)
	t.check("a countdown Buff adjusted to 0 is live at once", buffs.size() == 1 and buffs[0].countdown == -1)

	s = _state("SYS_04", "HST_06")
	_lattice(s)
	events = []
	Game.new(s)._place_specials(_mine_opts(1, [0, 0, 0, 0, 0, 1]), events)
	t.eq("a Mine adjusted to 0 expires at once", _mines(s).size(), 0)
	t.eq("…delivering its expiry", _damage(events, Types.DamageSource.MINE).size(), 1)

	var adj := []
	for ev in events:
		if ev["t"] == Types.EVT.PASSIVE and ev.has("countdown"):
			adj.append([ev["cause"]["source_id"], ev["countdown"], ev["base_countdown"]])
	t.eq_seq("the adjustment is attributed to its source", adj, [["HST_06", -1, 1]])

	# An immediate Bomb has no fuse and is not a countdown special.
	s = _state("SYS_01", "HST_06")
	_lattice(s)
	events = []
	Game.new(s)._place_specials(_bomb_opts(Types.Side.PLAYER, -1), events)
	var no_adjust := true
	for ev in events:
		if ev["t"] == Types.EVT.PASSIVE and ev.has("countdown"):
			no_adjust = false
	t.check("an un-fused overlay is not adjusted", no_adjust)


# ---------------------------------------------------------------------------
# §18.5 ability damage rate
# ---------------------------------------------------------------------------

func _test_ability_rate(t: TestCase) -> void:
	t.group("content expansion / PSV_ABILITY_DAMAGE_RATE")
	# [label, host, upgrades, target, source, extra info, amount, expect]
	var cases := [
		["MEGATON: System ability +50%", "HST_07", [], Types.Side.PLAYER, Types.DamageSource.ATTACKER, {}, 10, 15],
		["MEGATON: Hacker ability +50%", "HST_07", [], Types.Side.ENEMY, Types.DamageSource.ATTACKER, {}, 30, 45],
		["BULWARK: System ability -25%, truncated", "HST_01", ["UPG_10"], Types.Side.PLAYER, Types.DamageSource.ATTACKER, {}, 10, 7],
		["BULWARK leaves the Hacker's", "HST_01", ["UPG_10"], Types.Side.ENEMY, Types.DamageSource.ATTACKER, {}, 10, 10],
		["MEGATON + BULWARK sum to +25%, not x1.125", "HST_07", ["UPG_10"], Types.Side.PLAYER, Types.DamageSource.ATTACKER, {}, 10, 12],
		["odd value truncates toward zero", "HST_07", [], Types.Side.PLAYER, Types.DamageSource.ATTACKER, {}, 7, 10],
		["Bomb blast qualifies", "HST_07", [], Types.Side.PLAYER, Types.DamageSource.BOMB, {}, 10, 15],
		["LineSlice qualifies", "HST_07", [], Types.Side.PLAYER, Types.DamageSource.LINESLICE, {}, 10, 15],
		["Mine qualifies", "HST_07", [], Types.Side.PLAYER, Types.DamageSource.MINE, {}, 10, 15],
		["Sync damage does not", "HST_07", [], Types.Side.PLAYER, Types.DamageSource.MATCH, {"wave": true}, 10, 10],
		["a Bomb's descended cascade does not (ruling Q8)", "HST_07", [], Types.Side.PLAYER, Types.DamageSource.BOMB, {"wave": true}, 10, 10],
		["PASSIVE damage does not", "HST_07", [], Types.Side.PLAYER, Types.DamageSource.PASSIVE, {}, 10, 10],
	]
	for c in cases:
		var s := _state("SYS_01", str(c[1]), c[2])
		_lattice(s)
		var info: Dictionary = (c[5] as Dictionary).duplicate()
		info["source"] = c[4]
		var target: Types.Side = c[3]
		var before: int = s.hp[target]
		Resolve.deal_damage(s, target, int(c[6]), info, [])
		t.eq(str(c[0]), before - s.hp[target], int(c[7]))

	var s := _state("SYS_01", "HST_07")
	_lattice(s)
	_special(s, Vector2i(0, 0), Tile.Special.Type.SHIELD, Types.Side.PLAYER, 5)
	var before: int = s.hp[Types.Side.PLAYER]
	var events: Array = []
	Resolve.deal_damage(s, Types.Side.PLAYER, 10, {"source": Types.DamageSource.ATTACKER}, events)
	t.eq("Shield applies after the rate (15 - 5)", before - s.hp[Types.Side.PLAYER], 10)
	var rates := []
	for ev in events:
		if ev["t"] == Types.EVT.PASSIVE and ev.has("rate"):
			rates.append([ev["cause"]["source_id"], ev["rate"]])
	t.eq_seq("the rate is attributed to its source", rates, [["HST_07", 50]])

	# Real casts, end to end: DRIP is LEECH's 10-damage ATTACK.
	for host in [["HST_01", 10], ["HST_07", 15]]:
		s = _state("SYS_09", str(host[0]))
		var g := Game.new(s)
		_charge_only(s, "PRG_S_021")
		events = []
		g._run_system_function_phase(events)
		var hits := _damage(events, Types.DamageSource.ATTACKER)
		t.eq("DRIP on %s" % host[0], hits[0]["amount"] if not hits.is_empty() else -1, int(host[1]))


# ---------------------------------------------------------------------------
# §18.6 packet drop rate
# ---------------------------------------------------------------------------

func _test_drop_rate(t: TestCase) -> void:
	t.group("content expansion / PSV_PACKET_DROP_RATE")
	var red := Types.PacketColor.RED
	var yel := Types.PacketColor.YELLOW

	var gen := _gen(_state("SYS_01", "HST_01"), 1)
	t.check("no modifier leaves the generator unweighted", gen.color_weights.is_empty() and gen.shape_weights.is_empty())
	# The unweighted path is the ORIGINAL draw sequence, draw for draw.
	var rng := Rng.new(99)
	var a := BoardOps.TileGen.new(Rng.new(99), 1)
	var same := true
	for i in 200:
		var tile := BoardOps.random_tile(a)
		var neutral := rng.next() < Constants.NEUTRAL_TILE_DROP_RATE
		if neutral != tile.is_neutral():
			same = false
		if not neutral and (rng.int_below(Constants.COLOR_COUNT) != tile.color or rng.int_below(Constants.SHAPE_COUNT) != tile.shape):
			same = false
	t.check("the unweighted path draws exactly as before", same)

	gen = _gen(_state("SYS_01", "HST_08"), 1)
	t.eq_seq("REDSHIFT weights RED only", gen.color_weights, _weights(red, 115))
	t.check("REDSHIFT leaves shapes unweighted", gen.shape_weights.is_empty())
	gen = _gen(_state("SYS_01", "HST_01", ["UPG_08"]), 1)
	t.eq_seq("GOLDRUSH weights YEL only", gen.color_weights, _weights(yel, 115))
	gen = _gen(_state("SYS_01", "HST_08", ["UPG_08"]), 1)
	var both := _weights(red, 115)
	both[yel] = 115
	t.eq_seq("REDSHIFT and GOLDRUSH coexist", gen.color_weights, both)

	var s := _state("SYS_01", "HST_08")
	_inject(s, ["PSV_012"], Types.Side.PLAYER)
	t.eq_seq("two +15 RED add in weight space (130, not 132.25)", _gen(s, 1).color_weights, _weights(red, 130))

	# Neutral rate untouched: the neutrality draw is the same draw, so the same
	# seed puts neutrals in the same places weighted or not.
	var plain := BoardOps.TileGen.new(Rng.new(5), 1)
	var heavy := BoardOps.TileGen.new(Rng.new(5), 1)
	heavy.color_weights = _weights(red, 100000)
	var neutral_match := true
	var all_red := true
	for i in 300:
		var p := BoardOps.random_tile(plain)
		var h := BoardOps.random_tile(heavy)
		if p.is_neutral() != h.is_neutral():
			neutral_match = false
		if not h.is_neutral() and h.color != red:
			all_red = false
	t.check("weighting never changes which Packets are neutral", neutral_match)
	t.check("an overwhelming weight draws only its target (no rejection loop)", all_red)

	var r1 := BoardOps.TileGen.new(Rng.new(7), 1)
	var r2 := BoardOps.TileGen.new(Rng.new(7), 1)
	r1.color_weights = _weights(red, 115)
	r2.color_weights = _weights(red, 115)
	var det := true
	for i in 100:
		var x := BoardOps.random_tile(r1)
		var y := BoardOps.random_tile(r2)
		if x.is_neutral() != y.is_neutral() or x.color != y.color or x.shape != y.shape:
			det = false
	t.check("fixed-seed weighted draws are deterministic", det)

	var board := BoardOps.generate_initial(heavy)
	t.eq("a weighted initial board is still match-free", MatchFinder.detect(board).size(), 0)

	# Refill uses the same policy: replay the exact weighted draw the refill
	# should have made, from the same RNG state, and compare Packet for Packet.
	s = _state("SYS_01", "HST_08")
	_lattice(s)
	for y in 4:
		for x in Constants.BOARD_WIDTH:
			s.board[y][x] = null
	var replay := BoardOps.TileGen.new(Rng.new(s.rng.get_state()), s.next_id)
	replay.color_weights = _weights(red, 115)
	var expected := []
	for x in Constants.BOARD_WIDTH:
		for y in 4:
			var tile := BoardOps.random_tile(replay)
			expected.append([tile.is_neutral(), tile.color, tile.shape])
	var ev: Array = []
	Resolve.apply_gravity_and_refill(s, ev)
	var got := []
	for x in Constants.BOARD_WIDTH:
		for y in 4:
			var tile: Tile = s.board[y][x]
			got.append([tile.is_neutral(), tile.color, tile.shape])
	t.eq_seq("refill draws with the REDSHIFT weights", got, expected)
	var start_scene := Session.create_quick_match("SYS_01", "HST_08", 3, Session.default_build())
	t.check("an initial battle board on REDSHIFT is match-free", MatchFinder.detect(start_scene.board).is_empty())


func _gen(s: GameState, start: int) -> BoardOps.TileGen:
	var g := BoardOps.TileGen.new(Rng.new(1), start)
	Passives.apply_drop_weights(s.identity, g)
	return g


func _weights(target: int, w: int) -> Array[int]:
	var out: Array[int] = []
	for i in Constants.COLOR_COUNT:
		out.append(w if i == target else 100)
	return out


# ---------------------------------------------------------------------------
# §18.7 SELF_DAMAGE
# ---------------------------------------------------------------------------

func _test_self_damage(t: TestCase) -> void:
	t.group("content expansion / ACID")
	var s := _state("SYS_01", "HST_09")
	_lattice(s)
	_special_countdown_bomb(s, Vector2i(0, 0), Types.Side.PLAYER, 3)
	var g := Game.new(s)
	var before: int = s.hp[Types.Side.PLAYER]
	var events := g.start_player_phase()
	t.eq("the Hacker takes 10 on their own turn", before - s.hp[Types.Side.PLAYER], 10)
	var hit := _index_of_damage(events, Types.DamageSource.PASSIVE)
	var tick := _index_of(events, Types.EVT.COUNTDOWN)
	t.check("before countdowns tick", hit >= 0 and tick > hit)
	var dmg := _damage(events, Types.DamageSource.PASSIVE)
	t.check("attributed to ACID", not dmg.is_empty() and dmg[0]["cause"]["source_id"] == "HST_09")

	var ice: int = s.hp[Types.Side.ENEMY]
	events = g.run_enemy_phase()
	var first := _damage(events, Types.DamageSource.PASSIVE)
	t.check("the System takes 10 at the start of its turn", not first.is_empty() and first[0]["target"] == Types.Side.ENEMY and first[0]["amount"] == 10)
	t.check("…as the first damage of its turn", _index_of(events, Types.EVT.DAMAGE) == _index_of_damage(events, Types.DamageSource.PASSIVE))
	t.check("ICE fell", s.hp[Types.Side.ENEMY] < ice)

	s = _state("SYS_01", "HST_09")
	_lattice(s)
	_special(s, Vector2i(1, 1), Tile.Special.Type.SHIELD, Types.Side.PLAYER, 4)
	before = s.hp[Types.Side.PLAYER]
	Game.new(s).start_player_phase()
	t.eq("Shield applies (10 - 4)", before - s.hp[Types.Side.PLAYER], 6)

	s = _state("SYS_01", "HST_09")
	_inject(s, ["PSV_011"], Types.Side.ENEMY)
	_lattice(s)
	before = s.hp[Types.Side.PLAYER]
	Game.new(s).start_player_phase()
	t.eq("an ability-damage rate does not touch it", before - s.hp[Types.Side.PLAYER], 10)

	s = _state("SYS_01", "HST_09")
	_lattice(s)
	_special_countdown_bomb(s, Vector2i(0, 0), Types.Side.PLAYER, 3)
	s.hp[Types.Side.PLAYER] = 5
	events = Game.new(s).start_player_phase()
	t.eq("lethal self-damage ends the battle", s.winner, Types.Side.ENEMY)
	t.eq("before any countdown ticks", _count(events, Types.EVT.COUNTDOWN), 0)
	var m := Metrics.create([], [])
	Metrics.consume(m, [{"t": Types.EVT.DAMAGE, "target": Types.Side.PLAYER, "amount": 10, "source": Types.DamageSource.PASSIVE}])
	t.eq("metrics: taken from the environment", m.side(Types.Side.PLAYER).environment_damage_taken, 10)
	t.eq("metrics: not dealt by the System", m.side(Types.Side.ENEMY).total_damage, 0)


# ---------------------------------------------------------------------------
# §18.8 FURNACE and strong slices
# ---------------------------------------------------------------------------

func _test_match_damage_selector(t: TestCase) -> void:
	t.group("content expansion / FURNACE ALL:1")
	var red_cells := [Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7)]
	for owner in [Types.Side.PLAYER, Types.Side.ENEMY]:
		var base := _first_sync(_state("SYS_01", "HST_01"), owner, red_cells, RED, -1)
		var hot := _first_sync(_state("SYS_01", "HST_10"), owner, red_cells, RED, -1)
		t.eq("%s colour Sync +1" % Types.SIDE_NAMES[owner], hot - base, 1)
		var base_s := _first_sync(_state("SYS_01", "HST_01"), owner, red_cells, -1, TRI)
		var hot_s := _first_sync(_state("SYS_01", "HST_10"), owner, red_cells, -1, TRI)
		t.eq("%s shape Sync +1" % Types.SIDE_NAMES[owner], hot_s - base_s, 1)

	# EDGE (+1 RED) and CERULEAN (+1 BLU) still select by colour, and stack.
	var base := _first_sync(_state("SYS_01", "HST_01"), Types.Side.PLAYER, red_cells, RED, -1)
	t.eq("EDGE adds to a RED Sync", _first_sync(_state("SYS_01", "HST_01", ["UPG_05"]), Types.Side.PLAYER, red_cells, RED, -1) - base, 1)
	t.eq("EDGE + FURNACE stack additively", _first_sync(_state("SYS_01", "HST_10", ["UPG_05"]), Types.Side.PLAYER, red_cells, RED, -1) - base, 2)
	# Row 0, because on row 7 the lattice already has BLU beside these cells and
	# the paint would make an accidental 4-Sync.
	var top := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	var blue := _first_sync(_state("SYS_01", "HST_01"), Types.Side.PLAYER, top, BLUE, -1)
	t.eq("CERULEAN adds to a BLU Sync", _first_sync(_state("SYS_01", "HST_01", ["UPG_07"]), Types.Side.PLAYER, top, BLUE, -1) - blue, 1)
	t.eq("EDGE does not touch a BLU Sync", _first_sync(_state("SYS_01", "HST_01", ["UPG_05"]), Types.Side.PLAYER, top, BLUE, -1) - blue, 0)

	var s := _state("SYS_01", "HST_10")
	_lattice(s)
	var before: int = s.hp[Types.Side.ENEMY]
	Resolve.deal_damage(s, Types.Side.ENEMY, 30, {"source": Types.DamageSource.ATTACKER}, [])
	t.eq("FURNACE does not touch direct ability damage", before - s.hp[Types.Side.ENEMY], 30)


func _test_strong_slice_bonus(t: TestCase) -> void:
	t.group("content expansion / PSV_STRONG_SLICE_BONUS")
	var cells := [Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7)]
	# The Hacker's strong colours include RED; BLU is weak for them.
	var plain := _first_sync(_state("SYS_01", "HST_01"), Types.Side.PLAYER, cells, RED, -1)
	var boosted := _first_sync(_injected("PSV_020"), Types.Side.PLAYER, cells, RED, -1)
	t.eq("+1 per strong sliced Packet", boosted - plain, 3)
	var both_plain := _first_sync(_state("SYS_01", "HST_01"), Types.Side.PLAYER, cells, RED, TRI)
	var both_boost := _first_sync(_injected("PSV_020"), Types.Side.PLAYER, cells, RED, TRI)
	t.eq("a Packet strong on both axes counts once", both_boost - both_plain, 3)
	var top := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	var weak_plain := _first_sync(_state("SYS_01", "HST_01"), Types.Side.PLAYER, top, BLUE, -1)
	var weak_boost := _first_sync(_injected("PSV_020"), Types.Side.PLAYER, top, BLUE, -1)
	t.eq("a weak Sync gets nothing", weak_boost - weak_plain, 0)

	# LineSlice uses the ordinary profile, so it picks the bonus up; a Bomb does not.
	var s := _state("SYS_01", "HST_01")
	_lattice(s)
	var strong := 0
	for x in Constants.BOARD_WIDTH:
		var tile: Tile = s.board[3][x]
		if Constants.is_strong_color(s.config, Types.Side.PLAYER, tile.color) or Constants.is_strong_shape(s.config, Types.Side.PLAYER, tile.shape):
			strong += 1
	t.check("fixture: the row holds strong Packets", strong > 0)
	var line := {"dimension": 0, "targeting": 0, "specialRetention": 0, "dealDamage": Content.DEAL_DAMAGE_YES, "gainCharge": Content.GAIN_CHARGE_NO}
	var plain_line: int = Resolve.resolve_line_slice(s, Vector2i(0, 3), {"owner": Types.Side.PLAYER, "params": line}, [])["damage"]
	s = _injected("PSV_020")
	_lattice(s)
	var boosted_line: int = Resolve.resolve_line_slice(s, Vector2i(0, 3), {"owner": Types.Side.PLAYER, "params": line}, [])["damage"]
	t.eq("LineSlice: +1 per strong Packet in the line", boosted_line - plain_line, strong)

	var bombs := []
	for state in [_state("SYS_01", "HST_01"), _injected("PSV_020")]:
		_lattice(state)
		var before: int = state.hp[Types.Side.ENEMY]
		Resolve.detonate_at(state, Vector2i(3, 3), {
			"owner": Types.Side.PLAYER, "area_pattern": Areas.SQUARE_3X3, "program_id": "X", "fn_id": "FNC_001",
			"deal_damage": Content.DEAL_DAMAGE_YES, "gain_charge": Content.GAIN_CHARGE_NO,
		}, [], false)
		bombs.append(before - state.hp[Types.Side.ENEMY])
	t.eq("a Bomb does not", bombs[1] - bombs[0], 0)


func _injected(psv: String) -> GameState:
	var s := _state("SYS_01", "HST_01")
	_inject(s, [psv], Types.Side.PLAYER)
	return s


## The first Sync damage instance when `owner` resolves a Sync painted over
## `cells`. -1 for an axis leaves that axis as the lattice laid it.
func _first_sync(s: GameState, owner: Types.Side, cells: Array, color: int, shape: int) -> int:
	_lattice(s)
	_paint(s, cells, color, shape)
	var events: Array = []
	Resolve.resolve_cascades(s, owner, events, 1, Types.DamageSource.MATCH, {})
	var hits := _damage(events, Types.DamageSource.MATCH)
	return int(hits[0]["amount"]) if not hits.is_empty() else -1000


# ---------------------------------------------------------------------------
# §18.9 Transform to NEU
# ---------------------------------------------------------------------------

func _test_transform_to_neutral(t: TestCase) -> void:
	t.group("content expansion / SMOG transforms to NEU")
	var fn := Content.function("FNC_037")
	var params: Dictionary = fn["plan"][0]["params"]
	t.check("SMOG's result is NEU", bool(params["axisResult"]["neutral"]))
	t.eq("SMOG destroys overlays (ruling Q9)", params["transform"]["specialPacketTreatment"], Content.SPECIALS_DESTROY)

	var s := _state("SYS_10", "HST_01")
	_lattice(s)
	_special(s, Vector2i(2, 2), Tile.Special.Type.SHIELD, Types.Side.PLAYER, 3)
	var events: Array = []
	var out := Resolve.apply_transform(s, _smog_spec(Types.Side.ENEMY, 5), events)
	t.eq("five Packets converted", (out["cells"] as Array).size(), 5)
	for p in (out["cells"] as Array):
		var tile: Tile = s.board[p.y][p.x]
		t.check("%s is neutral with both axes cleared" % p, tile.is_neutral() and tile.color == -1 and tile.shape == -1)
	t.eq("the transform itself deals no damage", _count(events, Types.EVT.DAMAGE), 0)
	t.eq("…and routes no charge", _count(events, Types.EVT.CHARGE_ROUTE), 0)

	# Even with retain-all, a neutral never carries an overlay (Tile invariant).
	s = _state("SYS_10", "HST_01")
	_lattice(s)
	_special(s, Vector2i(2, 2), Tile.Special.Type.SHIELD, Types.Side.PLAYER, 3)
	var keep := _smog_spec(Types.Side.ENEMY, 99)
	keep["params"] = {"targeting": 0, "specialPacketTreatment": Content.SPECIALS_RETAIN_ALL}
	Resolve.apply_transform(s, keep, [])
	var bad := 0
	for row in s.board:
		for tile in row:
			if tile != null and tile.is_neutral() and tile.has_special():
				bad += 1
	t.eq("no neutral carries an overlay", bad, 0)


func _smog_spec(owner: Types.Side, quantity: int) -> Dictionary:
	var params: Dictionary = Content.function("FNC_037")["plan"][0]["params"]
	return {
		"owner": owner, "params": params["transform"],
		"axis_target": params["axisTarget"], "axis_result": params["axisResult"],
		"quantity": quantity, "program_id": "PRG_S_025", "fn_id": "FNC_037",
	}


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

## A Quick Match on the default build, optionally with acquired UPGRADEs. A
## Quick Match carries none, so they are installed on the identity and the
## PASSIVE cache re-keyed — the same thing a Run battle's identity holds.
func _state(system_id: String, host_id: String, upgrades: Array = [], seed_value := 11) -> GameState:
	Passives.clear_cache()
	var s := Session.create_quick_match(system_id, host_id, seed_value, Session.default_build())
	if not upgrades.is_empty():
		s.identity["upgrade_ids"] = upgrades.duplicate()
		s.identity["cache_key"] = "%s|%s" % [s.identity["cache_key"], ":".join(PackedStringArray(upgrades))]
	return s


## Adds PASSIVE instances the authored content does not reference, as if a
## source owned by `owner` supplied them — the only way to cover PSV_018-020.
func _inject(s: GameState, ids: Array, owner: Types.Side) -> void:
	s.identity["cache_key"] = "%s|inject:%s" % [s.identity["cache_key"], ":".join(PackedStringArray(ids))]
	var list := Passives.active(s.identity)
	for id in ids:
		list.append(Passives.Instance.new(Content.passive(id), Types.PassiveSourceKind.UPG, "TEST", owner))


## A board on which no two orthogonal neighbours share a colour or a shape, so
## nothing matches until a test paints the Sync it wants.
func _lattice(s: GameState) -> void:
	for y in Constants.BOARD_HEIGHT:
		for x in Constants.BOARD_WIDTH:
			var tile := Tile.standard(s.next_id, (x + 2 * y) % Constants.COLOR_COUNT, (2 * x + y) % Constants.SHAPE_COUNT)
			s.next_id += 1
			s.board[y][x] = tile


func _paint(s: GameState, cells: Array, color: int, shape: int) -> void:
	for p in cells:
		var tile: Tile = s.board[p.y][p.x]
		if color >= 0:
			tile.color = color
		if shape >= 0:
			tile.shape = shape


func _neutral(s: GameState, p: Vector2i) -> void:
	var tile: Tile = s.board[p.y][p.x]
	tile.kind = Tile.Kind.NEUTRAL
	tile.color = -1
	tile.shape = -1
	tile.special = null


func _special(s: GameState, p: Vector2i, type: Tile.Special.Type, owner: Types.Side, magnitude := -1) -> Tile.Special:
	var sp := Tile.Special.new()
	sp.type = type
	sp.owner = owner
	sp.magnitude = magnitude
	sp.seq = s.next_seq
	s.next_seq += 1
	s.board[p.y][p.x].special = sp
	return sp


func _special_countdown_bomb(s: GameState, p: Vector2i, owner: Types.Side, countdown: int) -> void:
	var sp := _special(s, p, Tile.Special.Type.BOMB, owner)
	sp.countdown = countdown
	sp.delivers = Effects.BOMB
	sp.area_pattern = Areas.SQUARE_3X3


func _mine(s: GameState, p: Vector2i, owner: Types.Side, flags: Array, countdown: int) -> Tile.Special:
	var sp := _special(s, p, Tile.Special.Type.MINE, owner)
	sp.countdown = countdown
	sp.delivers = Effects.MINE
	sp.damage = 20
	sp.program_id = "PRG_S_009"
	sp.fn_id = "FNC_023"
	for f in flags:
		sp.triggers.append(int(f))
	return sp


func _bomb_opts(owner: Types.Side, countdown: int) -> Dictionary:
	return {
		"type": Tile.Special.Type.BOMB, "owner": owner, "count": 1, "countdown": countdown,
		"area_pattern": Areas.SQUARE_3X3, "deal_damage": Content.DEAL_DAMAGE_NO,
		"gain_charge": Content.GAIN_CHARGE_NO, "delivers": Effects.BOMB,
		"fn_id": "FNC_001", "actor": {"kind": Types.OwnerKind.PROGRAM, "id": "X"},
	}


func _mine_opts(countdown: int, flags: Array) -> Dictionary:
	var named := {}
	for i in Effects.MINE_FLAG_NAMES.size():
		named[Effects.MINE_FLAG_NAMES[i]] = flags[i]
	return {
		"type": Tile.Special.Type.MINE, "owner": Types.Side.ENEMY, "count": 1, "countdown": countdown,
		"damage": 20, "triggers": named, "delivers": Effects.MINE,
		"fn_id": "FNC_023", "actor": {"kind": Types.OwnerKind.PROGRAM, "id": "PRG_S_009"},
	}


## Casts one System Program's Function directly, charge aside.
func _cast(s: GameState, side: Types.Side, program_id: String) -> Array:
	var prog := Content.program(program_id)
	var events: Array = []
	Game.new(s)._cast_actor(side, {
		"kind": Types.OwnerKind.PROGRAM, "id": prog["id"], "name": prog["name"], "fn": prog["fn"],
	}, events)
	return events


## Leaves exactly one System Program ready, so the System phase must pick it.
func _charge_only(s: GameState, program_id: String) -> void:
	for u in (s.units[Types.Side.ENEMY] as Array):
		u.charge = int(Content.program(u.program_id)["cost"]) if u.program_id == program_id else 0


func _unit(s: GameState, program_id: String) -> GameState.UnitState:
	for u in (s.units[Types.Side.ENEMY] as Array):
		if u.program_id == program_id:
			return u
	return null


func _mines(s: GameState) -> Array:
	var out := []
	for y in Constants.BOARD_HEIGHT:
		for x in Constants.BOARD_WIDTH:
			var tile: Tile = s.board[y][x]
			if tile != null and tile.has_special() and tile.special.type == Tile.Special.Type.MINE:
				out.append(Vector2i(x, y))
	return out


func _specials_of(s: GameState, type: Tile.Special.Type) -> Array:
	var out := []
	for row in s.board:
		for tile in row:
			if tile != null and tile.has_special() and tile.special.type == type:
				out.append(tile.special)
	return out


## Plays a battle to its end with the bot driving both sides, returning a
## normalized signature of every event — the same continuation check
## `test_save.gd` uses.
func _play_out(s: GameState) -> Array:
	var g := Game.new(s)
	var out := []
	var safety := 0
	while not s.has_winner() and safety < 400:
		safety += 1
		var mv := Bot.pick_move(s.board, s.config)
		if mv.is_empty():
			break
		for ev in g.attempt_swap(mv["a"], mv["b"])["events"]:
			out.append(TraceNorm.stringify(TraceNorm.normalize_event(ev)))
		if s.has_winner():
			break
		for ev in g.run_enemy_phase():
			out.append(TraceNorm.stringify(TraceNorm.normalize_event(ev)))
		if s.has_winner():
			break
		for ev in g.start_player_phase():
			out.append(TraceNorm.stringify(TraceNorm.normalize_event(ev)))
	out.append("final %d/%d winner %d" % [s.hp[0], s.hp[1], s.winner])
	return out


func _all(events: Array, type) -> Array:
	var out := []
	for ev in events:
		if ev["t"] == type:
			out.append(ev)
	return out


func _first(events: Array, type) -> Dictionary:
	for ev in events:
		if ev["t"] == type:
			return ev
	return {}


func _count(events: Array, type) -> int:
	return _all(events, type).size()


func _index_of(events: Array, type) -> int:
	for i in events.size():
		if events[i]["t"] == type:
			return i
	return -1


func _damage(events: Array, source: int) -> Array:
	var out := []
	for ev in events:
		if ev["t"] == Types.EVT.DAMAGE and int(ev["source"]) == source:
			out.append(ev)
	return out


func _index_of_damage(events: Array, source: int) -> int:
	for i in events.size():
		var ev: Dictionary = events[i]
		if ev["t"] == Types.EVT.DAMAGE and int(ev["source"]) == source:
			return i
	return -1
