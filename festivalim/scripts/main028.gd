extends "res://scripts/main027.gd"

const Tile028 = preload("res://scripts/tile028.gd")
const SPLASH_028: Texture2D = preload("res://assets/splash_028.png")
const VERSION_028 := "DEV 0.2.8"

func _show_startup_splash() -> void:
    var layer := CanvasLayer.new()
    layer.layer = 100
    add_child(layer)

    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_STOP
    layer.add_child(root)

    var bg := ColorRect.new()
    bg.color = Color("eafbf5")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(bg)

    var pic := TextureRect.new()
    pic.texture = SPLASH_028
    pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    pic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(pic)

    await get_tree().create_timer(1.15).timeout
    var tween := create_tween()
    tween.tween_property(root, "modulate:a", 0.0, 0.18)
    await tween.finished
    layer.queue_free()

func _show_menu() -> void:
    super._show_menu()
    _label(hud_layer, VERSION_028, Vector2(0, 1182), Vector2(720, 28), 13, Color(1, 1, 1, 0.42))

func _build_game_hud() -> void:
    super._build_game_hud()
    tutorial_label.text = "3 в ряд — обычная комбинация · суперфишку свайпни в любую сторону"
    _label(hud_layer, VERSION_028, Vector2(0, 1182), Vector2(720, 28), 13, Color(1, 1, 1, 0.42))

func _spawn_tile(cell: Vector2i, tile_type: int, drop := false) -> Node2D:
    var tile = Tile028.new()
    board.add_child(tile)
    tile.configure(tile_type, textures[tile_type], cell)

    var target := _cell_position(cell)
    tile.position = target
    if drop:
        tile.position.y -= STEP_027 * 1.6
        tile.move_to(target, 0.095)
    return tile

func _try_swap(a: Vector2i, b: Vector2i) -> void:
    if busy:
        return

    var first = grid[a.x][a.y]
    var second = grid[b.x][b.y]
    var first_special: int = int(first.special_kind)
    var second_special: int = int(second.special_kind)

    if first_special == 0 and second_special == 0:
        await super._try_swap(a, b)
        return

    busy = true
    idle_seconds = 0.0
    _clear_selection()
    _swap_tiles(a, b, true)
    await get_tree().create_timer(0.10).timeout

    moves -= 1
    var seeds: Array = []
    if first_special > 0 and is_instance_valid(first):
        seeds.append(first)
    if second_special > 0 and is_instance_valid(second) and second != first:
        seeds.append(second)

    await _activate_special_swap(seeds)
    _update_hud()

    if hearts >= HEART_GOAL:
        busy = false
        _finish_level(true)
        return

    if moves <= 0:
        busy = false
        _finish_level(false)
        return

    if _find_hint().is_empty():
        _new_board()
        message_label.text = "Ходов не осталось — поле перемешано."

    busy = false

func _activate_special_swap(seeds: Array) -> void:
    if seeds.is_empty():
        return

    var kinds: Array[int] = []
    for tile in seeds:
        if tile != null and is_instance_valid(tile):
            kinds.append(int(tile.special_kind))

    if kinds.size() >= 2:
        message_label.text = "КОМБО СУПЕРФИШЕК!"
        combo_label.text = "СПЕЦ-КОМБО!"
        combo_label.add_theme_color_override("font_color", Color("ffd83d"))
        Input.vibrate_handheld(150)
    elif kinds[0] == SPECIAL_MIC:
        message_label.text = "МИКРОФОН! Сносим весь ряд!"
        combo_label.text = "МИКРОФОН"
        combo_label.add_theme_color_override("font_color", Color("63f0ff"))
        Input.vibrate_handheld(100)
    elif kinds[0] == SPECIAL_STAR:
        message_label.text = "ЗВЕЗДА! Взрыв 3×3!"
        combo_label.text = "ЗВЕЗДА"
        combo_label.add_theme_color_override("font_color", Color("ffd83d"))
        Input.vibrate_handheld(120)
    elif kinds[0] == SPECIAL_FESTIVALIM:
        message_label.text = "ФЕСТИВАЛИМ! Сносим ряд и колонку!"
        combo_label.text = "ФЕСТИВАЛИМ!"
        combo_label.add_theme_color_override("font_color", Color("8df0d5"))
        _festival_flash()
        Input.vibrate_handheld(150)

    var removal_map: Dictionary = _expand_specials(seeds)
    var removal: Array = removal_map.keys()
    var heart_gain := 0

    for tile in removal:
        if tile != null and is_instance_valid(tile):
            if tile.tile_type == 0:
                heart_gain += 1
            tile.pop(0.10)

    hearts += heart_gain
    score += removal.size() * 160
    _update_hud()
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
