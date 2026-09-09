extends "res://scripts/main026.gd"

const Tile027 = preload("res://scripts/tile027.gd")
const VERSION_027 := "DEV 0.2.7"
const STEP_027 := 92.0
const CELL_027 := 96.0
const SPECIAL_FESTIVALIM := 3

var festival_booster_pending := false

func _build_textures() -> void:
    super._build_textures()

    var logo := AtlasTexture.new()
    logo.atlas = TILES_026
    logo.region = Rect2(2.0 * CELL_027, 2.0 * CELL_027, CELL_027, CELL_027)
    special_textures.append(logo)

func _show_menu() -> void:
    state = "menu"
    busy = false
    if board != null:
        board.visible = false
    _clear_screen()
    _solid_background(Color("071c1c"))

    var ui := _root(hud_layer)

    var logo := TextureRect.new()
    logo.texture = ICON_026
    logo.position = Vector2(210, 78)
    logo.size = Vector2(300, 300)
    logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui.add_child(logo)

    _label(ui, "ФЕСТИВАЛИМ", Vector2(40, 390), Vector2(640, 64), 44, Color("eafff8"))
    _label(ui, "СОБЕРИ ДВИЖ!", Vector2(40, 454), Vector2(640, 60), 36, Color("8df0d5"))
    _label(ui, "УРОВЕНЬ 1 · ПЯТНИЦА", Vector2(70, 525), Vector2(580, 42), 20, Color("ffd83d"))

    _label(ui, "Собирай 3 одинаковые фишки.\nЦель — 12 сердец за 18 ходов.", Vector2(65, 585), Vector2(590, 105), 23, Color("d9eeee"))

    var play := _button(ui, "ИГРАТЬ", Vector2(135, 720), Vector2(450, 88), _start_game)
    play.add_theme_font_size_override("font_size", 26)

    _label(ui, "4 в ряд → микрофон   •   5+ → звезда", Vector2(45, 830), Vector2(630, 42), 18, Color("9dc7c2"))
    _label(ui, "ДВИЖ 100% → фирменный бустер Фестивалим", Vector2(45, 874), Vector2(630, 50), 18, Color("8df0d5"))
    _label(ui, "Рекорд: %d   •   Лучший каскад: ×%d" % [best_score, best_combo_ever], Vector2(55, 955), Vector2(610, 44), 18, Color("d9eeee"))
    _label(ui, VERSION_027, Vector2(0, 1215), Vector2(720, 30), 14, Color(1, 1, 1, 0.48))

func _start_game() -> void:
    festival_booster_pending = false
    festival_boost_used = false
    super._start_game()
    board.position = Vector2(84, 325)

func _build_game_background() -> void:
    var root := _solid_background(Color("071719"))

    var panel := ColorRect.new()
    panel.position = Vector2(28, 272)
    panel.size = Vector2(664, 660)
    panel.color = Color("15363a")
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(panel)

    var inner := ColorRect.new()
    inner.position = Vector2(38, 282)
    inner.size = Vector2(644, 640)
    inner.color = Color("0b2022")
    inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(inner)

func _build_game_hud() -> void:
    var ui := _root(hud_layer)

    _label(ui, "ФЕСТИВАЛИМ — ПЯТНИЦА", Vector2(20, 8), Vector2(680, 52), 30, Color("eafff8"))
    tutorial_label = _label(ui, "Собери 3 одинаковые фишки в ряд", Vector2(35, 59), Vector2(650, 42), 20, Color("8df0d5"))

    goal_label = _label(ui, "", Vector2(15, 105), Vector2(230, 42), 22)
    moves_label = _label(ui, "", Vector2(245, 105), Vector2(230, 42), 22)
    score_label = _label(ui, "", Vector2(475, 105), Vector2(230, 42), 22)

    progress = ProgressBar.new()
    progress.position = Vector2(48, 151)
    progress.size = Vector2(624, 28)
    progress.min_value = 0
    progress.max_value = HEART_GOAL
    progress.show_percentage = false
    ui.add_child(progress)

    message_label = _label(ui, "", Vector2(35, 183), Vector2(650, 54), 20, Color("e0eeee"))
    combo_label = _label(ui, "КАСКАД: ×1", Vector2(45, 232), Vector2(470, 40), 19, Color("9dc7c2"))

    var pause_button := _button(ui, "ПАУЗА", Vector2(550, 229), Vector2(135, 44), _pause_game)
    pause_button.add_theme_font_size_override("font_size", 16)

    vibe_label = _label(ui, "ДВИЖ: 0%", Vector2(45, 936), Vector2(630, 34), 19, Color("8df0d5"))
    vibe_bar = ProgressBar.new()
    vibe_bar.position = Vector2(48, 972)
    vibe_bar.size = Vector2(624, 26)
    vibe_bar.min_value = 0
    vibe_bar.max_value = VIBE_MAX
    vibe_bar.show_percentage = false
    ui.add_child(vibe_bar)

    var hint := _button(ui, "ПОДСКАЗКА", Vector2(25, 1040), Vector2(205, 70), _show_hint)
    var shuffle := _button(ui, "ПЕРЕМЕШАТЬ", Vector2(257, 1040), Vector2(205, 70), _shuffle_board)
    var again := _button(ui, "ЗАНОВО", Vector2(489, 1040), Vector2(205, 70), _start_game)
    hint.add_theme_font_size_override("font_size", 19)
    shuffle.add_theme_font_size_override("font_size", 18)
    again.add_theme_font_size_override("font_size", 19)
    shuffle_button = shuffle

    _label(ui, VERSION_027, Vector2(0, 1215), Vector2(720, 28), 13, Color(1, 1, 1, 0.42))

func _spawn_tile(cell: Vector2i, tile_type: int, drop := false) -> Node2D:
    var tile = Tile027.new()
    board.add_child(tile)
    tile.configure(tile_type, textures[tile_type], cell)

    var target := _cell_position(cell)
    tile.position = target
    if drop:
        tile.position.y -= STEP_027 * 1.6
        tile.move_to(target, 0.095)
    return tile

func _cell_position(cell: Vector2i) -> Vector2:
    return Vector2(cell.x * STEP_027, cell.y * STEP_027)

func _cell_from_screen(screen_pos: Vector2) -> Vector2i:
    var local := board.to_local(screen_pos)
    var cell := Vector2i(int(round(local.x / STEP_027)), int(round(local.y / STEP_027)))
    if not _valid_cell(cell):
        return Vector2i(-1, -1)
    if local.distance_to(_cell_position(cell)) > STEP_027 * 0.49:
        return Vector2i(-1, -1)
    return cell

func _update_hud() -> void:
    if goal_label == null:
        return

    goal_label.text = "❤️ %d/%d" % [mini(hearts, HEART_GOAL), HEART_GOAL]
    moves_label.text = "Ходы: %d" % moves
    score_label.text = "Очки: %d" % score
    progress.value = mini(hearts, HEART_GOAL)

    var move_color := Color.WHITE
    if moves <= 3:
        move_color = Color("ff6666")
    elif moves <= 5:
        move_color = Color("ffb347")
    moves_label.add_theme_color_override("font_color", move_color)

    var vibe: int = mini(VIBE_MAX, int(score / VIBE_SCORE_STEP))
    if state == "game" and vibe >= VIBE_MAX and not festival_boost_used:
        festival_boost_used = true
        festival_booster_pending = true
        Input.vibrate_handheld(90)

    if vibe_bar != null:
        vibe_bar.value = vibe
    if vibe_label != null:
        if festival_boost_used:
            vibe_label.text = "ДВИЖ: 100%   •   БУСТЕР ФЕСТИВАЛИМ!"
            vibe_label.add_theme_color_override("font_color", Color("ffd83d"))
        else:
            vibe_label.text = "ДВИЖ: %d%%   •   заполни шкалу" % vibe
            vibe_label.add_theme_color_override("font_color", Color("8df0d5"))

func _resolve_board() -> void:
    await super._resolve_board()
    if festival_booster_pending and state == "game":
        festival_booster_pending = false
        await _activate_festivalim_booster()

func _activate_festivalim_booster() -> void:
    var candidates: Array = []
    for x in range(COLS):
        for y in range(ROWS):
            var tile = grid[x][y]
            if tile != null and is_instance_valid(tile) and int(tile.special_kind) == 0:
                candidates.append(tile)

    if candidates.is_empty():
        return

    var booster = candidates[randi_range(0, candidates.size() - 1)]
    booster.set_special(SPECIAL_FESTIVALIM, special_textures[SPECIAL_FESTIVALIM - 1])
    specials_created += 1

    if combo_label != null:
        combo_label.text = "ФЕСТИВАЛИМ!"
        combo_label.add_theme_color_override("font_color", Color("ffd83d"))
    if message_label != null:
        message_label.text = "ДВИЖ 100%! Фирменный бустер выходит на поле!"

    _festival_flash()
    Input.vibrate_handheld(120)
    await get_tree().create_timer(0.38).timeout

    var removal_map: Dictionary = _expand_specials([booster])
    var removal: Array = removal_map.keys()
    var heart_gain := 0

    for tile in removal:
        if tile != null and is_instance_valid(tile):
            if tile.tile_type == 0:
                heart_gain += 1
            tile.pop(0.10)

    hearts += heart_gain
    score += removal.size() * 180
    if message_label != null:
        message_label.text = "ФЕСТИВАЛИМ! Бустер снёс ряд и колонку!"
    _update_hud()
    Input.vibrate_handheld(150)

    await get_tree().create_timer(0.12).timeout

    for tile in removal:
        if tile == null or not is_instance_valid(tile):
            continue
        var cell: Vector2i = tile.grid_pos
        if _valid_cell(cell) and grid[cell.x][cell.y] == tile:
            grid[cell.x][cell.y] = null
        tile.queue_free()

    await _collapse_and_refill()
    await super._resolve_board()
    _update_hud()

func _expand_specials(seed_tiles: Array) -> Dictionary:
    var removal := {}
    var queue: Array = []
    var processed := {}

    for tile in seed_tiles:
        if tile != null and is_instance_valid(tile):
            removal[tile] = true
            queue.append(tile)

    var cursor := 0
    while cursor < queue.size():
        var tile = queue[cursor]
        cursor += 1
        if tile == null or not is_instance_valid(tile):
            continue
        if processed.has(tile):
            continue
        processed[tile] = true

        var kind: int = int(tile.special_kind)
        if kind == 0:
            continue

        specials_triggered += 1
        var cell: Vector2i = tile.grid_pos

        if kind == SPECIAL_MIC:
            for x in range(COLS):
                var row_tile = grid[x][cell.y]
                if row_tile != null and not removal.has(row_tile):
                    removal[row_tile] = true
                    queue.append(row_tile)
        elif kind == SPECIAL_STAR:
            for dx in range(-1, 2):
                for dy in range(-1, 2):
                    var target := Vector2i(cell.x + dx, cell.y + dy)
                    if _valid_cell(target):
                        var area_tile = grid[target.x][target.y]
                        if area_tile != null and not removal.has(area_tile):
                            removal[area_tile] = true
                            queue.append(area_tile)
        elif kind == SPECIAL_FESTIVALIM:
            for x in range(COLS):
                var row_target = grid[x][cell.y]
                if row_target != null and not removal.has(row_target):
                    removal[row_target] = true
                    queue.append(row_target)
            for y in range(ROWS):
                var col_target = grid[cell.x][y]
                if col_target != null and not removal.has(col_target):
                    removal[col_target] = true
                    queue.append(col_target)

    return removal

func _festival_flash() -> void:
    var flash := ColorRect.new()
    flash.color = Color(0.35, 1.0, 0.72, 0.22)
    flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud_layer.add_child(flash)

    var tween := create_tween()
    tween.tween_property(flash, "modulate:a", 0.0, 0.30)
    tween.finished.connect(flash.queue_free)

func _finish_level(win: bool) -> void:
    if round_best_combo > best_combo_ever:
        best_combo_ever = round_best_combo

    var rating := _rating_for_result(win)
    if score > best_score:
        best_score = score
    if rating > best_rating:
        best_rating = rating
    _save_progress()

    state = "end"
    busy = true

    var overlay := ColorRect.new()
    overlay.color = Color(0, 0, 0, 0.80)
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hud_layer.add_child(overlay)

    var panel := ColorRect.new()
    panel.position = Vector2(45, 300)
    panel.size = Vector2(630, 650)
    panel.color = Color("153538")
    overlay.add_child(panel)

    var title := "УРОВЕНЬ ПРОЙДЕН!" if win else "ХОДЫ ЗАКОНЧИЛИСЬ"
    var subtitle := "Пятница спасена. Движ состоялся!" if win else "Почти получилось. Движ требует реванша."

    _label(overlay, title, Vector2(65, 335), Vector2(590, 70), 34, Color("8df0d5"))
    _label(overlay, _rating_text(rating), Vector2(65, 410), Vector2(590, 70), 42, Color("ffd83d"))
    _label(overlay, subtitle, Vector2(80, 490), Vector2(560, 70), 21, Color("eafff8"))
    _label(overlay, "Очки: %d" % score, Vector2(90, 570), Vector2(540, 44), 23, Color("d9eeee"))
    _label(overlay, "Каскад: ×%d   •   спецфишек: %d   •   сработало: %d" % [round_best_combo, specials_created, specials_triggered], Vector2(65, 620), Vector2(590, 55), 18, Color("9dc7c2"))
    _label(overlay, "Рекорд: %d" % best_score, Vector2(90, 682), Vector2(540, 42), 19, Color("ffd83d"))

    var again := _button(overlay, "ЕЩЁ РАЗ", Vector2(75, 780), Vector2(270, 80), _start_game)
    var menu := _button(overlay, "МЕНЮ", Vector2(375, 780), Vector2(270, 80), _show_menu)
    again.add_theme_font_size_override("font_size", 23)
    menu.add_theme_font_size_override("font_size", 23)
