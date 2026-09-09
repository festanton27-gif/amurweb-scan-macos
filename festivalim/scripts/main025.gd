extends "res://scripts/main024.gd"

const Tile025 = preload("res://scripts/tile025.gd")
const SPECIAL_SHEET: Texture2D = preload("res://assets/tiles_023.webp")
const VERSION_025 := "DEV 0.2.5"
const SPECIAL_MIC := 1
const SPECIAL_STAR := 2
const SPECIAL_SOURCE_SIZE := 96.0

var special_textures: Array[Texture2D] = []
var combo_label: Label
var round_best_combo: int = 0
var best_combo_ever: int = 0
var specials_created: int = 0
var specials_triggered: int = 0

func _load_progress() -> void:
    super._load_progress()
    var cfg := ConfigFile.new()
    if cfg.load("user://festivalim.cfg") == OK:
        best_combo_ever = int(cfg.get_value("progress", "best_combo", 0))

func _save_progress() -> void:
    super._save_progress()
    var cfg := ConfigFile.new()
    cfg.load("user://festivalim.cfg")
    cfg.set_value("progress", "best_score", best_score)
    cfg.set_value("progress", "best_rating", best_rating)
    cfg.set_value("progress", "best_combo", best_combo_ever)
    cfg.save("user://festivalim.cfg")

func _build_textures() -> void:
    super._build_textures()
    special_textures.clear()
    for index in [6, 7]:
        var atlas := AtlasTexture.new()
        atlas.atlas = SPECIAL_SHEET
        atlas.region = Rect2(
            float(index % 3) * SPECIAL_SOURCE_SIZE,
            float(int(index / 3)) * SPECIAL_SOURCE_SIZE,
            SPECIAL_SOURCE_SIZE,
            SPECIAL_SOURCE_SIZE
        )
        special_textures.append(atlas)

func _show_menu() -> void:
    super._show_menu()

    var patch := ColorRect.new()
    patch.position = Vector2(0, 1010)
    patch.size = Vector2(720, 190)
    patch.color = Color("071c1c")
    patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud_layer.add_child(patch)

    _label(hud_layer, "4 в ряд → микрофон: сносит линию", Vector2(65, 1015), Vector2(590, 32), 15, Color("9dc7c2"))
    _label(hud_layer, "5+ → звезда: взрывает область 3×3", Vector2(65, 1047), Vector2(590, 32), 15, Color("ffd86a"))
    _label(hud_layer, "Лучший каскад: ×%d" % best_combo_ever, Vector2(65, 1085), Vector2(590, 34), 15, Color("8df0d5"))
    _label(hud_layer, VERSION_025, Vector2(0, 1162), Vector2(720, 28), 13, Color(1, 1, 1, 0.48))

func _start_game() -> void:
    round_best_combo = 0
    specials_created = 0
    specials_triggered = 0
    super._start_game()

func _build_game_hud() -> void:
    super._build_game_hud()

    combo_label = _label(hud_layer, "КАСКАД: ×1", Vector2(70, 246), Vector2(450, 36), 15, Color("9dc7c2"))

    var patch := ColorRect.new()
    patch.position = Vector2(0, 1008)
    patch.size = Vector2(720, 48)
    patch.color = Color("071719")
    patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud_layer.add_child(patch)
    _label(hud_layer, VERSION_025, Vector2(0, 1018), Vector2(720, 26), 12, Color(1, 1, 1, 0.38))

func _spawn_tile(cell: Vector2i, tile_type: int, drop := false) -> Node2D:
    var tile = Tile025.new()
    board.add_child(tile)
    tile.configure(tile_type, textures[tile_type], cell)

    var target := _cell_position(cell)
    tile.position = target
    if drop:
        tile.position.y -= STEP * 1.6
        tile.move_to(target, 0.095)
    return tile

func _expand_specials(seed_tiles: Array) -> Dictionary:
    var removal := {}
    var queue: Array = []
    var processed := {}

    for tile in seed_tiles:
        if tile != null and is_instance_valid(tile):
            removal[tile] = true
            queue.append(tile)

    var cursor: int = 0
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

    return removal

func _pick_special_candidate(matches: Array) -> Node2D:
    for tile in matches:
        if tile != null and is_instance_valid(tile) and int(tile.special_kind) == 0:
            return tile
    return null

func _resolve_board() -> void:
    var combo: int = 0
    var bonus_move_awarded := false

    while combo < 20:
        var matches: Array = _find_matches()
        if matches.is_empty():
            if combo_label != null:
                combo_label.text = "КАСКАД: ×%d" % maxi(combo, 1)
            return

        combo += 1
        round_best_combo = maxi(round_best_combo, combo)
        if combo_label != null:
            combo_label.text = "КАСКАД: ×%d" % combo
            combo_label.add_theme_color_override("font_color", Color("ffd83d") if combo >= 2 else Color("9dc7c2"))

        var original_count: int = matches.size()
        var special_to_create: int = 0
        if original_count >= 5:
            special_to_create = SPECIAL_STAR
        elif original_count >= 4:
            special_to_create = SPECIAL_MIC

        var preserve = null
        if special_to_create > 0:
            preserve = _pick_special_candidate(matches)

        var triggered_before: int = specials_triggered
        var removal_map: Dictionary = _expand_specials(matches)
        if preserve != null:
            removal_map.erase(preserve)

        var removal: Array = removal_map.keys()
        var heart_gain: int = 0
        for tile in removal:
            if tile.tile_type == 0:
                heart_gain += 1
            tile.pop(0.075)

        hearts += heart_gain
        score += removal.size() * 100 * combo

        if original_count >= 4:
            score += 400 * combo

        var got_extra_move := false
        if original_count >= 5 and not bonus_move_awarded:
            moves += 1
            bonus_move_awarded = true
            got_extra_move = true

        if preserve != null and special_to_create > 0:
            specials_created += 1

        _update_hud()
        Input.vibrate_handheld(70 if specials_triggered > triggered_before else (45 if original_count >= 5 else 25))

        var triggered_now: int = specials_triggered - triggered_before
        if triggered_now >= 2:
            message_label.text = "ЦЕПНАЯ РЕАКЦИЯ! Спецфишки сработали вместе!"
        elif triggered_now == 1:
            message_label.text = "БА-БАХ! Спецфишка сработала!"
        elif special_to_create == SPECIAL_STAR:
            message_label.text = "5+! Появилась звезда — взрыв 3×3!"
        elif special_to_create == SPECIAL_MIC:
            message_label.text = "4 в ряд! Появился микрофон — сносит линию!"
        elif combo > 1:
            message_label.text = "Каскад ×%d!" % combo
        elif got_extra_move:
            message_label.text = "ФЕСТИВАЛИМ! 5+ — дополнительный ход!"
        else:
            message_label.text = "Комбинация!"

        await get_tree().create_timer(0.085).timeout

        for tile in removal:
            if tile == null or not is_instance_valid(tile):
                continue
            var cell: Vector2i = tile.grid_pos
            if _valid_cell(cell) and grid[cell.x][cell.y] == tile:
                grid[cell.x][cell.y] = null
            tile.queue_free()

        if preserve != null and is_instance_valid(preserve) and special_to_create > 0:
            preserve.set_special(special_to_create, special_textures[special_to_create - 1])

        await _collapse_and_refill()

func _finish_level(win: bool) -> void:
    if round_best_combo > best_combo_ever:
        best_combo_ever = round_best_combo
    _save_progress()

    super._finish_level(win)

    _label(hud_layer, "Каскад ×%d   •   спецфишек: %d   •   сработало: %d" % [round_best_combo, specials_created, specials_triggered], Vector2(85, 676), Vector2(550, 28), 13, Color("9dc7c2"))
