extends SceneTree

## The beta 0.5 content smoke matrix (authorization §19).
##
##   godot --headless -s res://tools/content_smoke.gd
##   godot --headless -s res://tools/content_smoke.gd -- --runs 50
##
## A STRUCTURAL gate, not a balance ladder: does every authored combination
## run? Pass means no crash, no deadlock, no runaway resolution, every battle
## reaches a winner, every Run reaches its end — and every piece of new content
## actually executed, proven by coverage counters rather than assumed from the
## matrix's shape. Win rates are printed for the curious and asserted on
## nothing.
##
## Battles are bot versus bot, as `smoke.gd` plays them. The Hacker fires every
## charged Program, then commits the bot's best Sync.

const SAFETY := 600
const NEW_FUNCTIONS := [
	"FNC_023", "FNC_024", "FNC_025", "FNC_026", "FNC_027", "FNC_028", "FNC_029",
	"FNC_030", "FNC_031", "FNC_032", "FNC_033", "FNC_034", "FNC_035", "FNC_036",
	"FNC_037", "FNC_038", "FNC_039", "FNC_040",
]

var _failures: Array[String] = []
var _fn_seen := {}          ## fn_id -> activations
var _passive_seen := {}     ## "source/passive" -> PASSIVE events
var _mine_causes := {}      ## cause -> count
var _battles := 0
var _hacker_wins := 0
var _max_turns := 0


func _initialize() -> void:
	var runs := 20
	var args := OS.get_cmdline_user_args()
	var i := args.find("--runs")
	if i >= 0 and i + 1 < args.size():
		runs = int(args[i + 1])

	var loader := ContentLoader.new()
	var result := loader.load_all()
	if not result["ok"]:
		for e in loader.issues.errors().slice(0, 10):
			printerr("  %s" % DataIssues.format(e))
		quit(1)
		return
	Content.set_active(result["content"])
	print("content ok — fingerprint %s" % result["fingerprint"])

	_system_host_matrix()
	_upgrade_battles()
	_coverage()
	_run_walks(runs)

	print("")
	print("%d battles, Hacker won %d, longest %d turns" % [_battles, _hacker_wins, _max_turns])
	if _failures.is_empty():
		print("CONTENT SMOKE: PASS")
	else:
		print("CONTENT SMOKE: %d FAILURE(S)" % _failures.size())
		for f in _failures:
			print("  " + f)
	quit(0 if _failures.is_empty() else 1)


# ---------------------------------------------------------------------------

## Every System, including DOORMAN, on every HOST, THRESHOLD included — which
## also covers "every ordinary System once with THRESHOLD" and "every HOST once
## with a System that exercises it".
func _system_host_matrix() -> void:
	print("\n== System x HOST matrix")
	var seed_value := 1
	for s in Content.all_systems():
		var line := "  %-10s" % s["name"]
		for h in Content.all_hosts():
			var r := _battle(str(s["id"]), str(h["id"]), [], seed_value)
			line += " %s" % ("H" if r.get("winner", -1) == Types.Side.PLAYER else ("S" if r.get("winner", -1) == Types.Side.ENEMY else "!"))
			seed_value += 1
		print(line)
	print("  columns: %s" % " ".join(PackedStringArray(Content.all_hosts().map(func(h): return str(h["id"]).substr(4)))))


## Each UPGRADE on a System chosen so its PASSIVE has something to act on.
## PSV_PACKET_DROP_RATE emits no per-draw event by design (§15.2), so GOLDRUSH
## is proven by the generator weights instead.
func _upgrade_battles() -> void:
	print("\n== UPGRADE battles")
	var opponent := {
		"UPG_09": "SYS_04",  # HAIRTRIGGER: the Hacker's own BOMBER arms countdowns
		"UPG_10": "SYS_07",  # BULWARK: HARRIER's RAGE is ability damage to reduce
	}
	var seed_value := 500
	for u in Content.all_upgrades():
		var id := str(u["id"])
		var sys: String = opponent.get(id, "SYS_05")
		# Up to ten battles: a colour-specific trigger (DYNAMO's RED Sync) can
		# miss three bot-driven battles by chance, and missing is not failing.
		var fired := 0
		var played := 0
		while fired == 0 and played < 10:
			var r := _battle(sys, "HST_01", [id], seed_value)
			seed_value += 1
			played += 1
			fired += int(r.get("upgrade_events", 0))
		var proof := "%d PASSIVE events in %d battle(s)" % [fired, played]
		if id == "UPG_08":
			var state := _state(sys, "HST_01", [id], 1)
			var gen := BoardOps.TileGen.new(Rng.new(1), 1)
			Passives.apply_drop_weights(state.identity, gen)
			fired = 1 if gen.color_weights.size() == Constants.COLOR_COUNT and gen.color_weights[Types.PacketColor.YELLOW] == 115 else 0
			proof = "YEL weight %s" % ("115" if fired > 0 else "MISSING")
		print("  %-12s vs %-7s %s" % [u["name"], sys, proof])
		if fired == 0:
			_failures.append("%s never visibly fired" % id)


func _coverage() -> void:
	print("\n== new Function coverage")
	for fn in NEW_FUNCTIONS:
		var n: int = _fn_seen.get(fn, 0)
		print("  %s %-12s %d" % [fn, Content.function(fn)["name"], n])
		if n == 0:
			_failures.append("%s never executed" % fn)

	print("\n== HOST PASSIVE events (REDSHIFT weights draws, which log nothing)")
	for h in Content.all_hosts():
		var n := 0
		for k in _passive_seen:
			if str(k).begins_with(str(h["id"]) + "/"):
				n += _passive_seen[k]
		print("  %-10s %d" % [h["name"], n])
		if n == 0 and (h["passives"] as Array).size() > 0 and str(h["id"]) != "HST_08":
			_failures.append("HOST %s never fired a PASSIVE" % h["id"])

	print("\n== Mine trigger causes")
	for c in _mine_causes:
		print("  %-13s %d" % [c, _mine_causes[c]])
	for need in ["slice_owner", "slice_enemy"]:
		if not _mine_causes.has(need):
			_failures.append("no VOLATILE Mine was ever %s" % need)


## Complete Runs through the real Run progression API, battles played. A lost
## battle is retried as a player would; after three losses the win is forced
## through the ordinary damage funnel so the walk still reaches the Boss.
func _run_walks(runs: int) -> void:
	print("\n== Run walks")
	var completed := 0
	var forced := 0
	var systems := {}
	var hosts := {}
	var upgrades := {}
	for n in runs:
		var seed_value := 9000 + n
		var boss_id: String = Content.all_bosses()[n % Content.all_bosses().size()]["id"]
		var setup := RunSetup.commit_boss(boss_id, Constants.default_settings(), seed_value)
		setup = setup.commit_hacker(Content.DEFAULT_HACKER_ID)
		var r := setup.commit_deck(Content.DEFAULT_DECK_ID)
		var ok := true

		for step in Run.RUN_LENGTH:
			if not r.select_path(n % 2):
				_failures.append("run %d step %d: no path to select" % [n, step + 1])
				ok = false
				break
			r.confirm_build(r.opening_build_origin())
			if not r.opponent_is_boss():
				systems[r.opponent_id] = true
			hosts[r.host_id] = true
			var boss := r.step == Run.RUN_LENGTH
			if boss:
				r.enter_pending_boss_battle()

			var won := false
			for attempt in 4:
				var s := Session.create_run_battle(r, seed_value * 10 + attempt)
				if s == null:
					_failures.append("run %d step %d: no battle" % [n, r.step])
					break
				var g := Game.new(s)
				if attempt == 3:
					_collect_from(g.force_outcome(Types.Side.ENEMY))
					forced += 1
				else:
					_play(g, s, "run %d step %d" % [n, r.step])
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
				_failures.append("run %d step %d: could not advance" % [n, r.step])
				ok = false
				break

		for u in r.upgrade_ids:
			upgrades[u] = true
		if ok and r.is_complete() and r.problems().is_empty() and r.upgrade_ids.size() == Run.RUN_LENGTH:
			completed += 1
		else:
			_failures.append("run %d (seed %d) did not complete cleanly: %s" % [n, seed_value, r.problems()])

	print("  %d/%d Runs complete, %d battle(s) forced after three losses" % [completed, runs, forced])
	print("  Systems met %d/11 (DOORMAN included), HOSTs met %d/10, UPGRADEs acquired %d/10" % [systems.size(), hosts.size(), upgrades.size()])


# ---------------------------------------------------------------------------

func _battle(system_id: String, host_id: String, upgrades: Array, seed_value: int) -> Dictionary:
	var s := _state(system_id, host_id, upgrades, seed_value)
	var g := Game.new(s)
	var counts := _play(g, s, "%s/%s seed %d" % [system_id, host_id, seed_value])
	var upg := 0
	for k in _last_passives:
		for u in upgrades:
			if str(k).begins_with(str(u) + "/"):
				upg += _last_passives[k]
	counts["upgrade_events"] = upg
	return counts


func _state(system_id: String, host_id: String, upgrades: Array, seed_value: int) -> GameState:
	Passives.clear_cache()
	var s := Session.create_quick_match(system_id, host_id, seed_value, Session.default_build())
	if not upgrades.is_empty():
		s.identity["upgrade_ids"] = upgrades.duplicate()
		s.identity["cache_key"] = "%s|%s" % [s.identity["cache_key"], ":".join(PackedStringArray(upgrades))]
	return s


var _last_passives := {}


func _play(g: Game, s: GameState, label: String) -> Dictionary:
	_last_passives = {}
	_battles += 1
	_collect_from(g.start_player_phase())
	var turns := 0
	while not s.has_winner() and turns < SAFETY:
		turns += 1
		_fire_ready(g, s)
		if s.has_winner():
			break
		var mv := Bot.pick_move(s.board, s.config)
		if mv.is_empty():
			_failures.append("%s: no legal move (deadlock prevention failed)" % label)
			return {}
		_collect_from(g.attempt_swap(mv["a"], mv["b"])["events"])
		if s.has_winner():
			break
		_collect_from(g.run_enemy_phase())
		if s.has_winner():
			break
		_collect_from(g.start_player_phase())
	if not s.has_winner():
		_failures.append("%s: no winner after %d turns" % [label, SAFETY])
		return {}
	_max_turns = maxi(_max_turns, s.turn)
	if s.winner == Types.Side.PLAYER:
		_hacker_wins += 1
	return {"winner": s.winner, "turns": s.turn}


func _collect_from(events: Array) -> void:
	for ev in events:
		match ev["t"]:
			Types.EVT.ABILITY:
				# A carrier (WEEDS, SNEAKERS) announces itself as an ABILITY
				# carrying its PASSIVE cause, not as a PASSIVE event.
				if ev.has("cause"):
					var cc: Dictionary = ev["cause"]
					var ck := "%s/%s" % [cc.get("source_id", "?"), cc.get("passive_id", "?")]
					_passive_seen[ck] = int(_passive_seen.get(ck, 0)) + 1
					_last_passives[ck] = int(_last_passives.get(ck, 0)) + 1
				var fn := str(ev["fn"])
				_fn_seen[fn] = int(_fn_seen.get(fn, 0)) + 1
				# A composite's children run inside the parent's activation and
				# emit no ABILITY of their own; credit them from the plan.
				for op in (Content.function(fn)["plan"] as Array):
					if op["fn_id"] != fn:
						_fn_seen[op["fn_id"]] = int(_fn_seen.get(op["fn_id"], 0)) + 1
			Types.EVT.PASSIVE:
				var cause: Dictionary = ev.get("cause", {})
				var key := "%s/%s" % [cause.get("source_id", "?"), cause.get("passive_id", "?")]
				_passive_seen[key] = int(_passive_seen.get(key, 0)) + 1
				_last_passives[key] = int(_last_passives.get(key, 0)) + 1
			Types.EVT.MINE_TRIGGER:
				var c := str(ev["cause"])
				_mine_causes[c] = int(_mine_causes.get(c, 0)) + 1


func _fire_ready(g: Game, s: GameState) -> void:
	var units: Array = s.units[Types.Side.PLAYER]
	for i in units.size():
		if s.has_winner():
			return
		var u: GameState.UnitState = units[i]
		var prog := Content.program(u.program_id)
		if u.charge < int(prog["cost"]):
			continue
		_collect_from(g.fire_program(i, _target_for(s, prog["fn"])))
	if s.has_winner():
		return
	var deck := Content.deck(s.identity["deck_id"])
	if s.deck_charge >= int(deck["fn"]["cost"]):
		_collect_from(g.fire_deck_function(_target_for(s, deck["fn"])))


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
