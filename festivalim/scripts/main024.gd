extends "res://scripts/main023.gd"

const VERSION_024 := "DEV 0.2.4"
const VIBE_MAX := 100
const VIBE_SCORE_STEP := 30

var best_score := 0
var best_rating := 0
var vibe_bar: ProgressBar
var vibe_label: Label
var festival_boost_used := false
var pause_overlay: ColorRect

func _ready() -> void:
    _load_progress()
    super._ready()

func _load_progress() -> void:
    var cfg := ConfigFile.new()
    if cfg.load("user://festivalim.cfg") == OK:
        best_score = int(cfg.get_value("progress", "best_score", 0))
        best_rating = int(cfg.get_value("progress", "best_rating", 0))

func _save_progress() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("progress", "best_score", best_score)
    cfg.set_value("progress", "best_rating", best_rating)
    cfg.save("user://festivalim.cfg")

func _show_menu() -> void:
    super._show_menu()

    var patch := ColorRect.new()
    patch.position = Vector2(0, 1148)
    patch.size = Vector2(720, 52)
    patch.color = Color("071c1c")
    patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud_layer.add_child(patch)

    _label(hud_layer, "Рекорд: %d   •   Лучший результат: %s" % [best_score, _rating_text(best_rating)], Vector2(70, 930), Vector2(580, 42), 16, Color("9dc7c2"))
    _label(hud_layer, VERSION_024, Vector2(0, 1162), Vector2(720, 28), 13, Color(1, 1, 1, 0.45))

func _start_game() -> void:
    festival_boost_used = false
    pause_overlay = null
    super._start_game()

func _build_game_hud() -> void:
    super._build_game_hud()

    vibe_label = _label(hud_layer, "ДВИЖ: 0%", Vector2(72, 852), Vector2(576, 30), 16, Color("8df0d5"))

    vibe_bar = ProgressBar.new()
    vibe_bar.position = Vector2(72, 884)
    vibe_bar.size = Vector2(576, 20)
    vibe_bar.min_value = 0
    vibe_bar.max_value = VIBE_MAX
    vibe_bar.show_percentage = false
    hud_layer.add_child(vibe_bar)

    var pause_button: Button = _button(hud_layer, "ПАУЗА", Vector2(590, 247), Vector2(105, 38), _pause_game)
    pause_button.add_theme_font_size_override("font_size", 14)

    var patch := ColorRect.new()
    patch.position = Vector2(0, 1008)
    patch.size = Vector2(720, 48)
    patch.color = Color("071719")
    patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud_layer.add_child(patch)
    _label(hud_layer, VERSION_024, Vector2(0, 1018), Vector2(720, 26), 12, Color(1, 1, 1, 0.35))

func _update_hud() -> void:
    var vibe: int = mini(VIBE_MAX, int(score / VIBE_SCORE_STEP))

    if state == "game" and vibe >= VIBE_MAX and not festival_boost_used:
        festival_boost_used = true
        moves += 2
        Input.vibrate_handheld(90)

    super._update_hud()

    if vibe_bar != null:
        vibe_bar.value = vibe
    if vibe_label != null:
        if festival_boost_used:
            vibe_label.text = "ДВИЖ: 100%   •   ФЕСТИВАЛИМ! +2 хода"
            vibe_label.add_theme_color_override("font_color", Color("ffd83d"))
        else:
            vibe_label.text = "ДВИЖ: %d%%   •   заполни шкалу и получи +2 хода" % vibe

func _pause_game() -> void:
    if state != "game" or busy:
        return

    state = "pause"
    busy = true

    pause_overlay = ColorRect.new()
    pause_overlay.color = Color(0, 0, 0, 0.82)
    pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hud_layer.add_child(pause_overlay)

    var panel := ColorRect.new()
    panel.position = Vector2(95, 395)
    panel.size = Vector2(530, 355)
    panel.color = Color("153538")
    pause_overlay.add_child(panel)

    _label(pause_overlay, "ПАУЗА", Vector2(110, 430), Vector2(500, 60), 32, Color("8df0d5"))
    _label(pause_overlay, "Движ никуда не убежит.", Vector2(120, 500), Vector2(480, 50), 18, Color("d9eeee"))
    _button(pause_overlay, "ПРОДОЛЖИТЬ", Vector2(145, 575), Vector2(430, 62), _resume_game)
    _button(pause_overlay, "В МЕНЮ", Vector2(145, 650), Vector2(430, 62), _show_menu)

func _resume_game() -> void:
    if pause_overlay != null and is_instance_valid(pause_overlay):
        pause_overlay.queue_free()
    pause_overlay = null
    state = "game"
    busy = false
    idle_seconds = 0.0

func _finish_level(win: bool) -> void:
    var rating: int = _rating_for_result(win)
    if score > best_score:
        best_score = score
    if rating > best_rating:
        best_rating = rating
    _save_progress()

    super._finish_level(win)

    _label(hud_layer, "Рекорд: %d" % best_score, Vector2(90, 662), Vector2(540, 34), 15, Color("9dc7c2"))
