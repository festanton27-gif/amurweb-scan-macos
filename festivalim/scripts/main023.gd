extends "res://scripts/main022.gd"

const Tile023 = preload("res://scripts/tile023.gd")
const TILE_SHEET_023: Texture2D = preload("res://assets/tiles_023.webp")
const APP_ICON_023: Texture2D = preload("res://assets/icon_023.png")
const TILE_SOURCE_SIZE_023 := 96.0
const VERSION_023 := "DEV 0.2.3"

var shuffle_used_023 := false
var shuffle_button_023: Button

func _build_textures() -> void:
    textures.clear()
    for i in range(6):
        var atlas := AtlasTexture.new()
        atlas.atlas = TILE_SHEET_023
        atlas.region = Rect2(
            float(i % 3) * TILE_SOURCE_SIZE_023,
            float(int(i / 3)) * TILE_SOURCE_SIZE_023,
            TILE_SOURCE_SIZE_023,
            TILE_SOURCE_SIZE_023
        )
        textures.append(atlas)

func _show_menu() -> void:
    state = "menu"
    busy = false
    if board != null:
        board.visible = false
    _clear_screen()
    _solid_background(Color("071c1c"))

    var ui := _root(hud_layer)
    var logo := TextureRect.new()
    logo.texture = APP_ICON_023
    logo.position = Vector2(250, 125)
    logo.size = Vector2(220, 220)
    logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui.add_child(logo)

    _label(ui, "ФЕСТИВАЛИМ", Vector2(60, 385), Vector2(600, 58), 38, Color("eafff8"))
    _label(ui, "СОБЕРИ ДВИЖ!", Vector2(60, 442), Vector2(600, 58), 33, Color("8df0d5"))
    _label(ui, "Свайпни фишку к соседней.\nСобери 3 одинаковые в ряд.\nЦель — 12 сердец за 18 ходов.", Vector2(75, 550), Vector2(570, 135), 20, Color("d9eeee"))
    _button(ui, "ИГРАТЬ", Vector2(170, 735), Vector2(380, 78), _start_game)
    _label(ui, "4+ — бонус к очкам   •   5+ — дополнительный ход", Vector2(70, 845), Vector2(580, 70), 16, Color("9dc7c2"))
    _label(ui, VERSION_023, Vector2(0, 1165), Vector2(720, 30), 13, Color(1, 1, 1, 0.45))

func _start_game() -> void:
    state = "game"
    busy = false
    moves = START_MOVES
    hearts = 0
    score = 0
    selected = Vector2i(-1, -1)
    touch_cell = Vector2i(-1, -1)
    dragged = false
    mouse_down = false
    idle_seconds = 0.0
    first_match = false
    shuffle_used_023 = false

    _clear_screen()
    _build_game_background()
    _build_game_hud()

    board.position = Vector2(114, 330)
    board.visible = true
    _new_board()
    _update_hud()
    message_label.text = "Свайпни фишку к соседней, чтобы собрать тройку."

func _build_game_hud() -> void:
    var ui := _root(hud_layer)
    _label(ui, "ФЕСТИВАЛИМ — ПЯТНИЦА", Vector2(25, 12), Vector2(670, 45), 25, Color("eafff8"))
    tutorial_label = _label(ui, "Собери 3 одинаковые фишки в ряд", Vector2(40, 55), Vector2(640, 42), 17, Color("8df0d5"))

    goal_label = _label(ui, "", Vector2(20, 102), Vector2(230, 38), 18)
    moves_label = _label(ui, "", Vector2(245, 102), Vector2(230, 38), 18)
    score_label = _label(ui, "", Vector2(470, 102), Vector2(230, 38), 18)

    progress = ProgressBar.new()
    progress.position = Vector2(72, 145)
    progress.size = Vector2(576, 24)
    progress.min_value = 0
    progress.max_value = HEART_GOAL
    progress.show_percentage = false
    ui.add_child(progress)

    message_label = _label(ui, "", Vector2(45, 181), Vector2(630, 62), 17, Color("e0eeee"))

    _button(ui, "ПОДСКАЗКА", Vector2(47, 930), Vector2(190, 62), _show_hint)
    shuffle_button_023 = _button(ui, "ПЕРЕМЕШАТЬ", Vector2(265, 930), Vector2(190, 62), _shuffle_board_023)
    _button(ui, "ЗАНОВО", Vector2(483, 930), Vector2(190, 62), _start_game)
    _label(ui, VERSION_023, Vector2(0, 1020), Vector2(720, 28), 12, Color(1, 1, 1, 0.35))

func _build_game_background() -> void:
    var root := _solid_background(Color("071719"))
    var panel := ColorRect.new()
    panel.position = Vector2(68, 286)
    panel.size = Vector2(584, 584)
    panel.color = Color("15363a")
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(panel)

    var inner := ColorRect.new()
    inner.position = Vector2(79, 297)
    inner.size = Vector2(562, 562)
    inner.color = Color("0b2022")
    inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(inner)

func _spawn_tile(cell: Vector2i, tile_type: int, drop := false) -> Node2D:
    var tile = Tile023.new()
    board.add_child(tile)
    tile.configure(tile_type, textures[tile_type], cell)
    var target := _cell_position(cell)
    tile.position = target
    if drop:
        tile.position.y -= STEP * 1.6
        tile.move_to(target, 0.095)
    return tile

func _resolve_board() -> void:
    var combo := 0
    var bonus_move_awarded := false

    while combo < 20:
        var matches := _find_matches()
        if matches.is_empty():
            return

        combo += 1
        var heart_gain := 0
        for tile in matches:
            if tile.tile_type == 0:
                heart_gain += 1
            tile.pop(0.075)

        hearts += heart_gain
        score += matches.size() * 100 * combo
        if matches.size() >= 4:
            score += 400 * combo

        var got_extra_move := false
        if matches.size() >= 5 and not bonus_move_awarded:
            moves += 1
            bonus_move_awarded = true
            got_extra_move = true

        _update_hud()
        Input.vibrate_handheld(45 if matches.size() >= 5 else 25)

        if combo > 1:
            message_label.text = "Каскад x%d!" % combo
        elif got_extra_move:
            message_label.text = "ФЕСТИВАЛИМ! 5+ — дополнительный ход!"
        elif matches.size() >= 4:
            message_label.text = "Супер! 4+ — бонус к очкам!"
        else:
            message_label.text = "Комбинация!"

        await get_tree().create_timer(0.085).timeout
        for tile in matches:
            var cell: Vector2i = tile.grid_pos
            if grid[cell.x][cell.y] == tile:
                grid[cell.x][cell.y] = null
            tile.queue_free()
        await _collapse_and_refill()

func _shuffle_board_023() -> void:
    if state != "game" or busy:
        return
    if shuffle_used_023:
        message_label.text = "Бесплатное перемешивание уже использовано."
        return

    shuffle_used_023 = true
    _clear_selection()
    _new_board()
    idle_seconds = 0.0
    message_label.text = "Поле перемешано. Это было бесплатно."
    if shuffle_button_023 != null:
        shuffle_button_023.text = "ПЕРЕМЕШАНО"
        shuffle_button_023.disabled = true

func _update_hud() -> void:
    if goal_label == null:
        return
    goal_label.text = "Сердца: %d/%d" % [min(hearts, HEART_GOAL), HEART_GOAL]
    moves_label.text = "Ходы: %d" % moves
    score_label.text = "Очки: %d" % score
    progress.value = min(hearts, HEART_GOAL)

    var move_color := Color.WHITE
    if moves <= 3:
        move_color = Color("ff6666")
    elif moves <= 5:
        move_color = Color("ffb347")
    moves_label.add_theme_color_override("font_color", move_color)

func _rating_for_result_023(win: bool) -> int:
    if not win:
        return 0
    if moves >= 8 or score >= 8500:
        return 3
    if moves >= 4 or score >= 5500:
        return 2
    return 1

func _rating_text_023(rating: int) -> String:
    if rating >= 3:
        return "★ ★ ★"
    if rating == 2:
        return "★ ★ ☆"
    if rating == 1:
        return "★ ☆ ☆"
    return "☆ ☆ ☆"

func _finish_level(win: bool) -> void:
    state = "end"
    busy = true

    var overlay := ColorRect.new()
    overlay.color = Color(0, 0, 0, 0.76)
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hud_layer.add_child(overlay)

    var panel := ColorRect.new()
    panel.position = Vector2(70, 365)
    panel.size = Vector2(580, 455)
    panel.color = Color("153538")
    overlay.add_child(panel)

    var title := "УРОВЕНЬ ПРОЙДЕН!" if win else "ХОДЫ ЗАКОНЧИЛИСЬ"
    var subtitle := "Пятница спасена. Романтик всё-таки решился." if win else "Почти получилось. Движ требует реванша."
    var rating := _rating_for_result_023(win)

    _label(overlay, title, Vector2(90, 400), Vector2(540, 60), 30, Color("8df0d5"))
    _label(overlay, _rating_text_023(rating), Vector2(90, 470), Vector2(540, 60), 35, Color("ffd83d"))
    _label(overlay, subtitle, Vector2(110, 535), Vector2(500, 75), 18)
    _label(overlay, "Очки: %d   •   Осталось ходов: %d" % [score, max(moves, 0)], Vector2(90, 620), Vector2(540, 45), 17, Color("d9eeee"))
    _button(overlay, "ЕЩЁ РАЗ", Vector2(105, 705), Vector2(240, 66), _start_game)
    _button(overlay, "МЕНЮ", Vector2(375, 705), Vector2(240, 66), _show_menu)
