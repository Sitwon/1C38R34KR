extends SceneTree

## The beta 0.6 content smoke (authorization §20–§21).
##
##   godot --headless -s res://tools/content_smoke_2.gd
##
## Three COVERAGE gates, not balance ladders, beside `content_smoke.gd`, which
## still owns the Content Pass 1 System × HOST / UPGRADE matrix unchanged:
##
##   1. player content — all sixteen Hacker × Deck pairings, each Program in a
##      build, every new player Function executing, and the HEAL / health-cost
##      / direct-charge / Mine surfaces each actually occurring;
##   2. Boss content — every authored Boss Program placement present and
##      firing, and each bespoke mechanic occurring beside that loadout;
##   3. sixteen structural Run walks, one per pairing, through the real session
##      layer, with forced wins counted apart from natural ones.
##
## Pass means every counter is non-zero, no battle deadlocks or runs away, and
## nothing contradicts a Mine's authored trigger class. Win rates are printed
## for the curious and asserted on nothing.
##
## The Hacker policy differs from `content_smoke.gd` on purpose: it fires
## whatever is ready, Deck active included, and REPEATS until nothing is ready,
## so a Program TRANSFUSE fills is fired in the same pre-Sync window (§11.4).
## The Content Pass 1 matrix keeps its own policy so its result stays
## comparable with beta 0.5's.

const SAFETY := 600
const NEW_TOP_LEVEL := [
	"FNC_041", "FNC_042", "FNC_043", "FNC_046", "FNC_049", "FNC_052", "FNC_053",
	"FNC_054", "FNC_055", "FNC_056", "FNC_059", "FNC_060", "FNC_061", "FNC_062",
	"FNC_063", "FNC_064", "FNC_065", "FNC_066", "FNC_067",
]
const CHILDREN := ["FNC_044", "FNC_045", "FNC_047", "FNC_048", "FNC_050", "FNC_051", "FNC_057", "FNC_058"]
const SYSTEMS := ["SYS_01", "SYS_02", "SYS_04", "SYS_05", "SYS_06", "SYS_07", "SYS_08", "SYS_09", "SYS_10", "SYS_11"]
const HOSTS := ["HST_01", "HST_03", "HST_06", "HST_07", "HST_09", "HST_10"]

var _failures: Array[String] = []
var _battles := 0
var _hacker_wins := 0
var _max_turns := 0

var _fn_seen := {}            ## fn_id -> parent or child executions
var _in_build := {}           ## PRG_H id -> battles it was built into
var _pairs_built := {}
var _c := {}                  ## named coverage counter -> count
var _mine := {}               ## "fn_id cause enabled" -> count
var _boss_fires := {}         ## "BOS_xx PRG_S_xxx" -> natural fires
var _boss_mech := {}          ## "BOS_xx KIND" -> count
var _ready_from_charge := {}  ## Program index -> true, reset each pre-Sync window


func _initialize() -> void:
	var loader := ContentLoader.new()
	var result := loader.load_all()
	if not result["ok"]:
		for e in loader.issues.errors().slice(0, 10):
			printerr("  %s" % DataIssues.format(e))
		quit(1)
		return
	Content.set_active(result["content"])
	print("content ok — fingerprint %s" % result["fingerprint"])

	_player_content()
	_controlled_cases()
	_boss_content()
	_run_walks()
	_report()

	print("")
	print("%d battles, Hacker won %d, longest %d turns" % [_battles, _hacker_wins, _max_turns])
	if _failures.is_empty():
		print("CONTENT SMOKE 2: PASS")
	else:
		print("CONTENT SMOKE 2: %d FAILURE(S)" % _failures.size())
		for f in _failures:
			print("  " + f)
	quit(0 if _failures.is_empty() else 1)


func _hackers() -> Array:
	return (Content.active()["hackers"] as Dictionary).keys()


func _decks() -> Array:
	return (Content.active()["decks"] as Dictionary).keys()


# ---------------------------------------------------------------------------
# §20.2 player content
# ---------------------------------------------------------------------------

## Two builds per pairing put all six candidates into a battle: the first four
## of the inventory, then the last two ahead of the first two.
func _player_content() -> void:
	print("\n== player content: 16 pairings x 2 builds x 2 seeds")
	var seed_value := 6000
	var n := 0
	for h in _hackers():
		var line := "  %-7s" % Content.hacker(h)["name"]
		for d in _decks():
			var inv := Content.inventory_program_ids(h, d)
			if inv.size() != Content.INVENTORY_SIZE:
				_failures.append("%s+%s: inventory of %d" % [h, d, inv.size()])
				continue
			_pairs_built["%s+%s" % [h, d]] = true
			var marks := ""
			for build in [inv.slice(0, 4), [inv[4], inv[5], inv[0], inv[1]]]:
				if not Content.is_valid_build(build, inv):
					_failures.append("%s+%s: illegal build %s" % [h, d, build])
					continue
				for pid in build:
					_in_build[pid] = int(_in_build.get(pid, 0)) + 1
				for k in 2:
					var sys: String = SYSTEMS[n % SYSTEMS.size()]
					var host: String = HOSTS[n % HOSTS.size()]
					n += 1
					Passives.clear_cache()
					var s := Session.create_quick_match(sys, host, seed_value, build, {}, false, h, d)
					seed_value += 1
					var r := _play(Game.new(s), s, "%s+%s vs %s/%s" % [h, d, sys, host])
					marks += "H" if r.get("winner", -1) == Types.Side.PLAYER else ("S" if r.get("winner", -1) == Types.Side.ENEMY else "!")
			line += " %s" % marks
		print(line)
	print("  columns: %s (HHHH = build A x2, build B x2)" % " ".join(PackedStringArray(_decks().map(func(id): return str(Content.deck(id)["name"])))))

	# TRIPWIRE needs a Destroy: a Bomb blast, a line clear's collateral or a
	# Transform/Shake strip. Keep playing NEEDLE until both Mines have fired
	# through their intended class, within a bound.
	var extra := 0
	while extra < 40 and (_mine_hits("FNC_053", ["slice_owner", "slice_enemy"]) == 0 or _mine_hits("FNC_054", ["destroy_owner", "destroy_enemy"]) == 0):
		var d: String = _decks()[extra % _decks().size()]
		var build := ["PRG_H_013", "PRG_H_014", "PRG_H_015", Content.deck(d)["portfolio"][0]]
		Passives.clear_cache()
		var s := Session.create_quick_match(SYSTEMS[extra % SYSTEMS.size()], "HST_04", 7000 + extra, build, {}, false, "HAK_04", d)
		_play(Game.new(s), s, "NEEDLE extra %d" % extra)
		extra += 1
	if extra > 0:
		print("  NEEDLE extra battles for Mine coverage: %d" % extra)


func _mine_hits(fn_id: String, causes: Array) -> int:
	var n := 0
	for c in causes:
		n += int(_mine.get("%s %s true" % [fn_id, c], 0))
	return n


## The two §20.2 cases ordinary play cannot be relied on to produce.
func _controlled_cases() -> void:
	print("\n== controlled cases")
	# A lethal Function SELF_DAMAGE: RAZE at 12 LINK fires OVERDRAW.
	Passives.clear_cache()
	var s := Session.create_quick_match("SYS_01", "HST_01", 1, ["PRG_H_010", "PRG_H_011", "PRG_H_012", "PRG_H_003"], {}, false, "HAK_03", "DEK_01")
	s.hp[Types.Side.PLAYER] = 12
	(s.units[Types.Side.PLAYER] as Array)[0].charge = 4
	_collect(Game.new(s).fire_program(0))
	var lethal := s.winner == Types.Side.ENEMY and int(_c.get("health_cost_lethal", 0)) > 0
	print("  lethal OVERDRAW ends the battle, BUFF aborted: %s" % ("yes" if lethal else "NO"))
	if not lethal:
		_failures.append("controlled lethal SELF_DAMAGE did not end the battle")

	# A HEAL that caps: VITRA one short of full fires MEND.
	Passives.clear_cache()
	s = Session.create_quick_match("SYS_01", "HST_01", 1, ["PRG_H_007", "PRG_H_008", "PRG_H_009", "PRG_H_003"], {}, false, "HAK_02", "DEK_01")
	s.hp[Types.Side.PLAYER] -= 1
	(s.units[Types.Side.PLAYER] as Array)[0].charge = 6
	_collect(Game.new(s).fire_program(0))
	print("  MEND at 1 below full caps: %s" % ("yes" if int(_c.get("heal_capped", 0)) > 0 else "NO"))


# ---------------------------------------------------------------------------
# §20.3 Boss content
# ---------------------------------------------------------------------------

func _boss_content() -> void:
	print("\n== Boss content")
	var placements := 0
	for b in Content.all_bosses():
		var id := str(b["id"])
		var progs: Array = b["programs"]
		var s := Session.create_boss_attack(id, Content.BOSS_ATTACK_HOST_ID, 1, Session.default_build())
		var fielded := []
		for u in (s.units[Types.Side.ENEMY] as Array):
			fielded.append(u.program_id)
		if fielded != progs:
			_failures.append("%s fields %s, authored %s" % [id, fielded, progs])
		placements += fielded.size()

		# Controlled charge: each Program, alone and ready, fires.
		var forced := 0
		for pid in progs:
			Passives.clear_cache()
			var cs := Session.create_boss_attack(id, Content.BOSS_ATTACK_HOST_ID, 2, Session.default_build())
			for u in (cs.units[Types.Side.PLAYER] as Array):
				u.charge = 3
			for u in (cs.units[Types.Side.ENEMY] as Array):
				u.charge = int(Content.program(u.program_id)["cost"]) if u.program_id == pid else 0
			var ev: Array = []
			Game.new(cs)._run_system_function_phase(ev)
			for e in ev:
				if e["t"] == Types.EVT.ABILITY and str(e["program_id"]) == str(pid):
					forced += 1
					break
		if forced != progs.size():
			_failures.append("%s: only %d of %d Programs fired under controlled charge" % [id, forced, progs.size()])

		# Natural play: every pairing once against this Boss.
		var seed_value := 8000
		var wins := 0
		_current_boss = id
		for h in _hackers():
			for d in _decks():
				Passives.clear_cache()
				var bs := Session.create_boss_attack(id, Content.BOSS_ATTACK_HOST_ID, seed_value, Content.default_build(h, d), {}, false, h, d)
				seed_value += 1
				var r := _play(Game.new(bs), bs, "Boss Attack %s with %s+%s" % [id, h, d])
				if r.get("winner", -1) == Types.Side.PLAYER:
					wins += 1
		_current_boss = ""
		var natural := 0
		for pid in progs:
			if int(_boss_fires.get("%s %s" % [id, pid], 0)) > 0:
				natural += 1
		var mech := PackedStringArray()
		for k in _boss_mech:
			if str(k).begins_with(id + " "):
				mech.append("%s %d" % [str(k).substr(7), _boss_mech[k]])
		print("  %-9s Programs %d/4 fielded, %d/4 forced, %d/4 fired naturally; Hacker won %d/16" % [b["name"], fielded.size(), forced, natural, wins])
		print("            mechanic: %s" % ", ".join(mech))
		var signature := {"BOS_01": "OVERRIDE_PLACED", "BOS_02": "CAPACITOR_PLACED", "BOS_03": "LOGIC_BOMB_PLACED", "BOS_04": "AXIS_CONCEALED"}
		if int(_boss_mech.get("%s %s" % [id, signature[id]], 0)) == 0:
			_failures.append("%s: %s never occurred beside the new loadout" % [id, signature[id]])
	print("  %d authored Boss Program placements fielded" % placements)
	if placements != 16:
		_failures.append("expected 16 Boss Program placements, fielded %d" % placements)


# ---------------------------------------------------------------------------
# §21 structural Run walks
# ---------------------------------------------------------------------------

func _run_walks() -> void:
	print("\n== structural Run walks: one per pairing")
	var completed := 0
	var natural := 0
	var forced := 0
	var n := 0
	for h in _hackers():
		for d in _decks():
			var seed_value := 9500 + n
			var boss_id: String = Content.all_bosses()[n % Content.all_bosses().size()]["id"]
			n += 1
			var setup := RunSetup.commit_boss(boss_id, Constants.default_settings(), seed_value)
			setup = setup.commit_hacker(h)
			if setup == null:
				_failures.append("run %s+%s: Hacker rejected" % [h, d])
				continue
			var r := setup.commit_deck(d)
			if r == null:
				_failures.append("run %s+%s: Deck rejected" % [h, d])
				continue
			if r.inventory != Content.inventory_program_ids(h, d):
				_failures.append("run %s+%s: inventory %s" % [h, d, r.inventory])
			var ok := true
			for step in Run.RUN_LENGTH:
				if not r.select_path(n % 2):
					_failures.append("run %s+%s step %d: no path" % [h, d, step + 1])
					ok = false
					break
				r.confirm_build(r.opening_build_origin())
				var boss := r.step == Run.RUN_LENGTH
				if boss:
					r.enter_pending_boss_battle()
				var won := false
				for attempt in 4:
					var s := Session.create_run_battle(r, seed_value * 10 + attempt)
					if s == null:
						_failures.append("run %s+%s step %d: no battle" % [h, d, r.step])
						break
					if [s.identity["hacker_id"], s.identity["deck_id"]] != [h, d]:
						_failures.append("run %s+%s: battle plays %s+%s" % [h, d, s.identity["hacker_id"], s.identity["deck_id"]])
					if s.identity["upgrade_ids"] != r.upgrade_ids:
						_failures.append("run %s+%s step %d: UPGRADEs did not reach the battle" % [h, d, r.step])
					if boss and s.identity["system_programs"] != Content.boss(boss_id)["programs"]:
						_failures.append("run %s+%s: Boss battle loadout %s" % [h, d, s.identity["system_programs"]])
					# Save/resume through the session envelope on every battle, in
					# the phase the game writes it from (`main._start_run_battle`).
					var prior := r.phase
					r.phase = Types.SessionPhase.ACTIVE_BATTLE
					var env := SessionSave.run_to_dict(r, s)
					var back := SessionSave.from_dict(JSON.parse_string(JSON.stringify(env)))
					r.phase = prior
					if not back["ok"]:
						_failures.append("run %s+%s step %d: session save did not restore (%s)" % [h, d, r.step, back.get("reason", "")])
					elif [back["run"].hacker_id, back["run"].deck_id, back["run"].build, back["state"].identity["hacker_programs"]] != [h, d, r.build, s.identity["hacker_programs"]]:
						_failures.append("run %s+%s step %d: session save lost the pair or build" % [h, d, r.step])
					var g := Game.new(s)
					if attempt == 3:
						_collect(g.force_outcome(Types.Side.ENEMY))
						forced += 1
						_battles += 1
					else:
						_play(g, s, "run %s+%s step %d" % [h, d, r.step])
						if s.winner == Types.Side.PLAYER:
							natural += 1
					if s.winner == Types.Side.PLAYER:
						won = true
						break
					r.retry_battle()
				if not won:
					ok = false
					break
				if boss:
					r.complete_run()
				elif not r.advance_after_victory():
					_failures.append("run %s+%s step %d: could not advance" % [h, d, r.step])
					ok = false
					break
			if ok and r.is_complete() and r.problems().is_empty() and r.upgrade_ids.size() == Run.RUN_LENGTH:
				completed += 1
			else:
				_failures.append("run %s+%s (seed %d) did not complete cleanly: %s" % [h, d, seed_value, r.problems()])
	print("  %d/16 Runs complete; %d battles won naturally, %d wins FORCED after three losses (structural, not balance)" % [completed, natural, forced])


# ---------------------------------------------------------------------------
# Play and collection
# ---------------------------------------------------------------------------

func _play(g: Game, s: GameState, label: String) -> Dictionary:
	_battles += 1
	_collect(g.start_player_phase())
	var turns := 0
	while not s.has_winner() and turns < SAFETY:
		turns += 1
		_fire_until_idle(g, s)
		if s.has_winner():
			break
		var mv := Bot.pick_move(s.board, s.config)
		if mv.is_empty():
			_failures.append("%s: no legal move (deadlock prevention failed)" % label)
			return {}
		_collect(g.attempt_swap(mv["a"], mv["b"])["events"])
		if s.has_winner():
			break
		_collect(g.run_enemy_phase())
		if s.has_winner():
			break
		_collect(g.start_player_phase())
	if not s.has_winner():
		_failures.append("%s: no winner after %d turns" % [label, SAFETY])
		return {}
	_max_turns = maxi(_max_turns, s.turn)
	if s.winner == Types.Side.PLAYER:
		_hacker_wins += 1
	return {"winner": s.winner, "turns": s.turn}


## Fires the Deck active and every ready Program, repeatedly, until a full pass
## fires nothing. A HEAL at full health is skipped — a player would not spend
## it — but the cap case is still covered by `_controlled_cases`.
func _fire_until_idle(g: Game, s: GameState) -> void:
	_ready_from_charge = {}
	for _pass in 8:
		var fired := false
		var deck := Content.deck(s.identity["deck_id"])
		if s.deck_charge >= int(deck["fn"]["cost"]) and not s.has_winner():
			_collect(g.fire_deck_function(_target_for(s, deck["fn"])))
			fired = true
		var units: Array = s.units[Types.Side.PLAYER]
		for i in units.size():
			if s.has_winner():
				return
			var u: GameState.UnitState = units[i]
			var prog := Content.program(u.program_id)
			if u.charge < int(prog["cost"]):
				continue
			if _is_pure_heal(prog["fn"]) and s.hp[Types.Side.PLAYER] >= s.max_hp_of(Types.Side.PLAYER):
				continue
			if _ready_from_charge.has(i):
				_c["fired_after_direct_charge"] = int(_c.get("fired_after_direct_charge", 0)) + 1
			_collect(g.fire_program(i, _target_for(s, prog["fn"])))
			fired = true
		if not fired or s.has_winner():
			return


func _is_pure_heal(fn: Dictionary) -> bool:
	for op in (fn["plan"] as Array):
		if op["effect_id"] != Effects.HEAL:
			return false
	return true


func _target_for(s: GameState, fn: Dictionary):
	var plan: Array = fn["plan"]
	if plan.is_empty():
		return null
	match plan[0]["target"]:
		Types.TargetKind.UNIT:
			var best := 0
			var enemy: Array = s.units[Types.Side.ENEMY]
			for i in enemy.size():
				if enemy[i].charge > enemy[best].charge:
					best = i
			return {"kind": Types.TargetKind.UNIT, "idx": best}
		Types.TargetKind.PACKET:
			var cells := s.occupied_cells()
			return {"kind": Types.TargetKind.PACKET, "p": cells[0]} if not cells.is_empty() else null
	return null


func _bump(key: String, by := 1) -> void:
	_c[key] = int(_c.get(key, 0)) + by


func _collect(events: Array) -> void:
	for ev in events:
		match ev["t"]:
			Types.EVT.ABILITY:
				var fn := str(ev["fn"])
				_fn_seen[fn] = int(_fn_seen.get(fn, 0)) + 1
				for op in (Content.function(fn)["plan"] as Array):
					if op["fn_id"] != fn:
						_fn_seen[op["fn_id"]] = int(_fn_seen.get(op["fn_id"], 0)) + 1
				if int(ev["side"]) == Types.Side.ENEMY and int(ev["owner_kind"]) == Types.OwnerKind.PROGRAM:
					var bid := _boss_of(str(ev["program_id"]))
					if bid != "":
						var k := "%s %s" % [bid, ev["program_id"]]
						_boss_fires[k] = int(_boss_fires.get(k, 0)) + 1
			Types.EVT.HEAL:
				_bump("heal_events")
				if int(ev["applied"]) > 0:
					_bump("heal_applied")
				if int(ev["wasted"]) > 0:
					_bump("heal_capped")
			Types.EVT.HEALTH_COST:
				_bump("health_cost_events")
				if int(ev["before"]) > int(ev["after"]):
					_bump("health_cost_paid")
				if bool(ev["lethal"]):
					_bump("health_cost_lethal")
			Types.EVT.DIRECT_CHARGE:
				_bump("charge_events")
				_bump("charge_offered", int(ev["offered"]) * (ev["targets"] as Array).size())
				_bump("charge_accepted", int(ev["accepted"]))
				_bump("charge_discarded", int(ev["discarded"]))
				if int(ev["side"]) == Types.Side.PLAYER:
					for tg in (ev["targets"] as Array):
						var cost := int(Content.program(str(tg["program_id"]))["cost"])
						if int(tg["before"]) < cost and int(tg["after"]) >= cost:
							_ready_from_charge[int(tg["idx"])] = true
			Types.EVT.MINE_TRIGGER:
				var k := "%s %s %s" % [ev["fn_id"], ev["cause"], "true" if bool(ev["enabled"]) else "false"]
				_mine[k] = int(_mine.get(k, 0)) + 1
			Types.EVT.BOSS_MECHANIC:
				var k := "%s %s" % [ev["boss_id"], ev["kind"]]
				_boss_mech[k] = int(_boss_mech.get(k, 0)) + 1


## The Boss whose battle is in play is not on the event, but every Boss
## Program event in this tool comes from a Boss Attack or a Run's Boss battle.
var _current_boss := ""


func _boss_of(_program_id: String) -> String:
	return _current_boss


# ---------------------------------------------------------------------------

func _report() -> void:
	print("\n== player coverage")
	var pairs := _pairs_built.size()
	print("  pairings constructed %d/16" % pairs)
	if pairs != 16:
		_failures.append("only %d of 16 pairings constructed" % pairs)
	var missing := []
	for n in range(7, 25):
		var pid := "PRG_H_%03d" % n
		if int(_in_build.get(pid, 0)) == 0:
			missing.append(pid)
	print("  PRG_H_007-024 in a battle build: %d/18" % (18 - missing.size()))
	if not missing.is_empty():
		_failures.append("never built: %s" % missing)

	print("  new top-level Functions:")
	for fn in NEW_TOP_LEVEL:
		var n: int = _fn_seen.get(fn, 0)
		print("    %s %-12s %d" % [fn, Content.function(fn)["name"], n])
		if n == 0:
			_failures.append("%s never executed" % fn)
	print("  chain children:")
	for fn in CHILDREN:
		var n: int = _fn_seen.get(fn, 0)
		print("    %s %-15s %d" % [fn, Content.function(fn)["name"], n])
		if n == 0:
			_failures.append("%s never resolved" % fn)

	print("  HEAL events %d, applied %d, capped %d" % [_c.get("heal_events", 0), _c.get("heal_applied", 0), _c.get("heal_capped", 0)])
	print("  health cost events %d, paid %d, lethal %d" % [_c.get("health_cost_events", 0), _c.get("health_cost_paid", 0), _c.get("health_cost_lethal", 0)])
	print("  direct charge events %d: offered %d, accepted %d, discarded %d; Programs fired after it in the same window %d" % [
		_c.get("charge_events", 0), _c.get("charge_offered", 0), _c.get("charge_accepted", 0),
		_c.get("charge_discarded", 0), _c.get("fired_after_direct_charge", 0),
	])
	for key in ["heal_applied", "heal_capped", "health_cost_paid", "health_cost_lethal", "charge_accepted", "charge_discarded", "fired_after_direct_charge"]:
		if int(_c.get(key, 0)) == 0:
			_failures.append("coverage counter %s is zero" % key)

	print("  Mine triggers (fn cause enabled):")
	var keys := _mine.keys()
	keys.sort()
	for k in keys:
		print("    %-32s %d" % [k, _mine[k]])
	if _mine_hits("FNC_053", ["slice_owner", "slice_enemy"]) == 0:
		_failures.append("SEEDMINE never fired through a Slice")
	if _mine_hits("FNC_054", ["destroy_owner", "destroy_enemy"]) == 0:
		_failures.append("TRIPWIRE never fired through a Destroy")
	# A contradiction of the authored class is a failure, not a coverage gap.
	for c in ["destroy_owner", "destroy_enemy", "destroy_host", "expire"]:
		if int(_mine.get("FNC_053 %s true" % c, 0)) > 0:
			_failures.append("SEEDMINE fired on %s" % c)
	for c in ["slice_owner", "slice_enemy", "destroy_host", "expire"]:
		if int(_mine.get("FNC_054 %s true" % c, 0)) > 0:
			_failures.append("TRIPWIRE fired on %s" % c)
