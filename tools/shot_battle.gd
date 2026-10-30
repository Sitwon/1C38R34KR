extends SceneTree

## Renders the real battle screen on the desktop and saves a screenshot.
##
##   godot --path . -s res://tools/shot_battle.gd -- --out C:/tmp/b.png
##   godot --path . -s res://tools/shot_battle.gd -- --pack bzone --ovl --out C:/tmp/b.png
##   godot --path . -s res://tools/shot_battle.gd -- --sys SYS_04 --volatile --out C:/tmp/b.png
##
## NOT headless: the dummy renderer draws nothing. Opens a window, waits a few
## frames for layout, captures the root viewport, and quits.
##
## Beta 0.5 — the desktop is the iteration target and the device is the gate
## (lessons-learned §7). A presentation change is judged here in seconds per
## skin, and the tablet confirms the result rather than discovering it.
##
## Options:
##   --pack <name>   graphics pack (default: the default pack)
##   --sys / --host  opponent and battlefield (default SYS_04 on HST_01)
##   --seed <n>      battle seed (default 11)
##   --ovl           stamp every overlay type, as the debug bar's `ovl` does
##   --volatile      cast VOLATILE for the System before capturing
##   --size WxH      window size (default 540x1170, a phone's 1080x2340 halved)
##   --out <path>    PNG to write (required)

var _out := ""
var _frames := 0


func _initialize() -> void:
	var opts := _args()
	_out = str(opts.get("out", ""))
	if _out == "":
		printerr("--out is required")
		quit(1)
		return

	var size := str(opts.get("size", "540x1170")).split("x")
	DisplayServer.window_set_size(Vector2i(int(size[0]), int(size[1])))

	var pack := str(opts.get("pack", ""))
	var problems := Graphics.load_pack_named(pack) if pack != "" else Graphics.load_pack()
	for p in problems:
		printerr(p)

	var loader := ContentLoader.new()
	var result := loader.load_all()
	if not result["ok"]:
		printerr("content failed to load")
		quit(1)
		return
	Content.set_active(result["content"])
	Passives.clear_cache()
	TextStyles.clear_cache()
	Fonts.clear_cache()

	var s := Session.create_quick_match(
		str(opts.get("sys", "SYS_04")), str(opts.get("host", "HST_01")),
		int(opts.get("seed", "11")), Session.default_build()
	)
	if opts.has("volatile"):
		var prog := Content.program("PRG_S_009")
		Game.new(s)._cast_actor(Types.Side.ENEMY, {
			"kind": Types.OwnerKind.PROGRAM, "id": prog["id"], "name": prog["name"], "fn": prog["fn"],
		}, [])

	var holder := Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.theme = UiTheme.build()
	root.add_child(holder)

	var screen := BattleScreen.new()
	screen.resume_only = true
	screen.context_line = "shot_battle"
	screen.setup(s)
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.add_child(screen)
	if opts.has("ovl"):
		screen.call_deferred("_debug_seed_overlays")


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < 12:
		return false
	var img := root.get_texture().get_image()
	var err := img.save_png(_out)
	print("wrote %s (%dx%d) %s" % [_out, img.get_width(), img.get_height(), "" if err == OK else "ERROR %d" % err])
	return true


func _args() -> Dictionary:
	var raw := OS.get_cmdline_user_args()
	var out := {}
	var i := 0
	while i < raw.size():
		var a: String = raw[i]
		if a.begins_with("--"):
			if i + 1 < raw.size() and not raw[i + 1].begins_with("--"):
				out[a.substr(2)] = raw[i + 1]
				i += 2
				continue
			out[a.substr(2)] = true
		i += 1
	return out
