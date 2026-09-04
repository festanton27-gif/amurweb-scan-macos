extends Node2D

const Tile = preload("res://scripts/tile022.gd")
const TILE_SHEET: Texture2D = preload("res://assets/tiles_atlas.webp")
const APP_ICON: Texture2D = preload("res://assets/icon_021.jpg")

const COLS := 7
const ROWS := 7
const STEP := 82.0
const START_MOVES := 18
const HEART_GOAL := 12
const SWIPE_THRESHOLD := 26.0
const VERSION := "DEV 0.2.2"

var textures: Array[Texture2D] = []
var grid: Array = []
var board: Node2D
var background_layer: CanvasLayer
var hud_layer: CanvasLayer
var state := "menu"
var busy := false
var moves := START_MOVES
var hearts := 0
var score := 0
var selected := Vector2i(-1, -1)
var touch_cell := Vector2i(-1, -1)
var touch_pos := Vector2.ZERO
var dragged := false
var mouse_down := false
var idle_seconds := 0.0
var first_match := false
var goal_label: Label
var moves_label: Label
var score_label: Label
var message_label: Label
var tutorial_label: Label
var progress: ProgressBar

func _ready() -> void:
    randomize()
    _build_textures()

    board = Node2D.new()
    board.name = "Board"
    board.visible = false
    add_child(board)

    background_layer = CanvasLayer.new()
    background_layer.layer = -10
    add_child(background_layer)

    hud_layer = CanvasLayer.new()
    hud_layer.layer = 10
    add_child(hud_layer)

    _show_menu()

func _process(delta: float) -> void:
    if state == "game" and not busy:
        idle_seconds += delta
        if idle_seconds >= 6.0:
            idle_seconds = 0.0
            _show_hint()

func _build_textures() -> void:
    textures.clear()
    for i in range(6):
        var atlas := AtlasTexture.new()
        atlas.atlas = TILE_SHEET
        atlas.region = Rect2((i % 3) * 24, int(i / 3) * 24, 24, 24)
        textures.append(atlas)

func _clear_layer(layer: CanvasLayer) -> void:
    for child in layer.get_children():
        child.free()

func _clear_screen() -> void:
    _clear_layer(background_layer)
    _clear_layer(hud_layer)

func _root(layer: CanvasLayer) -> Control:
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(root)
    return root

func _solid_background(color: Color) -> Control:
    var root := _root(background_layer)
    var bg := ColorRect.new()
    bg.color = color
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(bg)
    return root

func _label(parent: Node, text_value: String, pos: Vector2, box_size: Vector2, font_size: int, color := Color.WHITE) -> Label:
    var label := Label.new()
    label.text = text_value
    label.position = pos
    label.size = box_size
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    parent.add_child(label)
    return label

func _button(parent: Node, text_value: String, pos: Vector2, box_size: Vector2, callback: Callable) -> Button:
    var button := Button.new()
    button.text = text_value
    button.position = pos
    button.size = box_size
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 22)
    button.pressed.connect(callback)
    parent.add_child(button)
    return button

func _show_menu() -> void:
    state = "menu"
    busy = false
    board.visible = false
    _clear_screen()
    _solid_background(Color("071c1c"))

    var ui := _root(hud_layer)
    var logo := TextureRect.new()
    logo.texture = APP_ICON
    logo.position = Vector2(230, 135)
    logo.size = Vector2(260, 260)
    logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui.add_child(logo)

    _label(ui, "ФЕСТИВАЛИМ", Vector2(60, 430), Vector2(600, 58), 38, Color("eafff8"))
    _label(ui, "СОБЕРИ ДВИЖ!", Vector2(60, 485), Vector2(600, 58), 33, Color("8df0d5"))
    _label(ui, "Свайпни фишку к соседней.\nСобери 3 одинаковые в ряд.\nЦель — 12 сердец за 18 ходов.", Vector2(75, 585), Vector2(570, 135), 20, Color("d9eeee"))
    _button(ui, "ИГРАТЬ", Vector2(170, 765), Vector2(380, 78), _start_game)
    _label(ui, VERSION, Vector2(0, 1165), Vector2(720, 30), 13, Color(1, 1, 1, 0.45))

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

    _clear_screen()
    _build_game_background()
    _build_game_hud()

    board.position = Vector2(114, 350)
    board.visible = true
    _new_board()
    _update_hud()
    message_label.text = "Свайпни фишку к соседней, чтобы собрать тройку."

func _build_game_background() -> void:
    var root := _solid_background(Color("071719"))

    var panel := ColorRect.new()
    panel.position = Vector2(68, 306)
    panel.size = Vector2(584, 584)
    panel.color = Color("15363a")
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(panel)

    var inner := ColorRect.new()
    inner.position = Vector2(79, 317)
    inner.size = Vector2(562, 562)
    inner.color = Color("0b2022")
    inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(inner)

func _build_game_hud() -> void:
    var ui := _root(hud_layer)
    _label(ui, "ФЕСТИВАЛИМ — ПЯТНИЦА", Vector2(25, 18), Vector2(670, 45), 25, Color("eafff8"))
    tutorial_label = _label(ui, "Собери 3 одинаковые фишки в ряд", Vector2(40, 67), Vector2(640, 42), 17, Color("8df0d5"))

    goal_label = _label(ui, "", Vector2(20, 116), Vector2(230, 38), 18)
    moves_label = _label(ui, "", Vector2(245, 116), Vector2(230, 38), 18)
    score_label = _label(ui, "", Vector2(470, 116), Vector2(230, 38), 18)

    progress = ProgressBar.new()
    progress.position = Vector2(72, 162)
    progress.size = Vector2(576, 27)
    progress.min_value = 0
    progress.max_value = HEART_GOAL
    progress.show_percentage = false
    ui.add_child(progress)

    message_label = _label(ui, "", Vector2(45, 205), Vector2(630, 66), 17, Color("e0eeee"))

    _button(ui, "ПОДСКАЗКА", Vector2(80, 970), Vector2(260, 64), _show_hint)
    _button(ui, "ЗАНОВО", Vector2(380, 970), Vector2(260, 64), _start_game)
    _label(ui, VERSION, Vector2(0, 1060), Vector2(720, 28), 12, Color(1, 1, 1, 0.35))

func _clear_board() -> void:
    for child in board.get_children():
        child.free()
    grid.clear()

func _new_board() -> void:
    _clear_board()

    for attempt in range(80):
        if attempt > 0:
            _clear_board()

        grid.resize(COLS)
        for x in range(COLS):
            grid[x] = []
            grid[x].resize(ROWS)
            for y in range(ROWS):
                var tile_type := randi_range(0, 5)
                while _would_make_initial_match(x, y, tile_type):
                    tile_type = randi_range(0, 5)
                grid[x][y] = _spawn_tile(Vector2i(x, y), tile_type, false)

        if not _find_hint().is_empty():
            return

func _would_make_initial_match(x: int, y: int, tile_type: int) -> bool:
    if x >= 2:
        var left1 = grid[x - 1][y]
        var left2 = grid[x - 2][y]
        if left1 != null and left2 != null and left1.tile_type == tile_type and left2.tile_type == tile_type:
            return true
    if y >= 2:
        var up1 = grid[x][y - 1]
        var up2 = grid[x][y - 2]
        if up1 != null and up2 != null and up1.tile_type == tile_type and up2.tile_type == tile_type:
            return true
    return false

func _spawn_tile(cell: Vector2i, tile_type: int, drop := false) -> Node2D:
    var tile = Tile.new()
    board.add_child(tile)
    tile.configure(tile_type, textures[tile_type], cell)

    var target := _cell_position(cell)
    tile.position = target
    if drop:
        tile.position.y -= STEP * 1.6
        tile.move_to(target, 0.10)
    return tile

func _cell_position(cell: Vector2i) -> Vector2:
    return Vector2(cell.x * STEP, cell.y * STEP)

func _cell_from_screen(screen_pos: Vector2) -> Vector2i:
    var local := board.to_local(screen_pos)
    var cell := Vector2i(int(round(local.x / STEP)), int(round(local.y / STEP)))
    if not _valid_cell(cell):
        return Vector2i(-1, -1)
    if local.distance_to(_cell_position(cell)) > STEP * 0.47:
        return Vector2i(-1, -1)
    return cell

func _input(event: InputEvent) -> void:
    if state != "game" or busy:
        return

    if event is InputEventScreenTouch:
        if event.pressed:
            _pointer_press(event.position)
        else:
            _pointer_release(event.position)
        return

    if event is InputEventScreenDrag:
        _pointer_drag(event.position)
        return

    if OS.get_name() != "Android":
        if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
            mouse_down = event.pressed
            if event.pressed:
                _pointer_press(event.position)
            else:
                _pointer_release(event.position)
            return

        if event is InputEventMouseMotion and mouse_down:
            _pointer_drag(event.position)

func _pointer_press(pos: Vector2) -> void:
    idle_seconds = 0.0
    touch_cell = _cell_from_screen(pos)
    touch_pos = pos
    dragged = false

func _pointer_drag(pos: Vector2) -> void:
    if dragged or touch_cell.x < 0:
        return

    var delta := pos - touch_pos
    if delta.length() < SWIPE_THRESHOLD:
        return

    var direction := Vector2i.ZERO
    if abs(delta.x) >= abs(delta.y):
        direction.x = 1 if delta.x > 0 else -1
    else:
        direction.y = 1 if delta.y > 0 else -1

    var other := touch_cell + direction
    if not _valid_cell(other):
        return

    dragged = true
    _clear_selection()
    _try_swap(touch_cell, other)

func _pointer_release(pos: Vector2) -> void:
    if touch_cell.x < 0:
        return

    if not dragged:
        var released := _cell_from_screen(pos)
        if released.x >= 0:
            _tap_tile(released)

    touch_cell = Vector2i(-1, -1)
    dragged = false

func _tap_tile(cell: Vector2i) -> void:
    idle_seconds = 0.0

    if selected.x < 0:
        selected = cell
        grid[cell.x][cell.y].set_selected(true)
        message_label.text = "Выбрано. Теперь тапни соседнюю фишку."
        return

    if selected == cell:
        _clear_selection()
        message_label.text = "Выбор снят."
        return

    if abs(selected.x - cell.x) + abs(selected.y - cell.y) == 1:
        var first := selected
        _clear_selection()
        _try_swap(first, cell)
        return

    grid[selected.x][selected.y].set_selected(false)
    selected = cell
    grid[cell.x][cell.y].set_selected(true)
    message_label.text = "Выбрана другая фишка."

func _clear_selection() -> void:
    if selected.x >= 0 and grid.size() == COLS:
        var tile = grid[selected.x][selected.y]
        if tile != null:
            tile.set_selected(false)
    selected = Vector2i(-1, -1)

func _valid_cell(cell: Vector2i) -> bool:
    return cell.x >= 0 and cell.x < COLS and cell.y >= 0 and cell.y < ROWS

func _swap_tiles(a: Vector2i, b: Vector2i, animate := true) -> void:
    var first = grid[a.x][a.y]
    var second = grid[b.x][b.y]

    grid[a.x][a.y] = second
    grid[b.x][b.y] = first
    first.grid_pos = b
    second.grid_pos = a

    if animate:
        first.move_to(_cell_position(b), 0.09)
        second.move_to(_cell_position(a), 0.09)

func _swap_refs(a: Vector2i, b: Vector2i) -> void:
    var first = grid[a.x][a.y]
    grid[a.x][a.y] = grid[b.x][b.y]
    grid[b.x][b.y] = first

func _try_swap(a: Vector2i, b: Vector2i) -> void:
    if busy:
        return

    busy = true
    idle_seconds = 0.0
    _swap_tiles(a, b, true)
    await get_tree().create_timer(0.10).timeout

    if _find_matches().is_empty():
        _swap_tiles(a, b, true)
        message_label.text = "Нет тройки — фишки вернулись назад."
        await get_tree().create_timer(0.10).timeout
        busy = false
        return

    moves -= 1
    await _resolve_board()
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

    if not first_match:
        first_match = true
        tutorial_label.text = "Отлично. Теперь собирай сердца и следи за ходами."

    busy = false

func _find_matches() -> Array:
    var found := {}

    for y in range(ROWS):
        var run_start := 0
        for x in range(1, COLS):
            if grid[x][y].tile_type != grid[run_start][y].tile_type:
                if x - run_start >= 3:
                    for k in range(run_start, x):
                        found[grid[k][y]] = true
                run_start = x
        if COLS - run_start >= 3:
            for k in range(run_start, COLS):
                found[grid[k][y]] = true

    for x in range(COLS):
        var run_start := 0
        for y in range(1, ROWS):
            if grid[x][y].tile_type != grid[x][run_start].tile_type:
                if y - run_start >= 3:
                    for k in range(run_start, y):
                        found[grid[x][k]] = true
                run_start = y
        if ROWS - run_start >= 3:
            for k in range(run_start, ROWS):
                found[grid[x][k]] = true

    return found.keys()

func _resolve_board() -> void:
    var combo := 0

    while combo < 20:
        var matches := _find_matches()
        if matches.is_empty():
            return

        combo += 1
        var heart_gain := 0

        for tile in matches:
            if tile.tile_type == 0:
                heart_gain += 1
            tile.pop(0.07)

        hearts += heart_gain
        score += matches.size() * 100 * combo
        _update_hud()
        message_label.text = "Комбинация!" if combo == 1 else "Каскад x%d!" % combo

        await get_tree().create_timer(0.08).timeout

        for tile in matches:
            var cell: Vector2i = tile.grid_pos
            if grid[cell.x][cell.y] == tile:
                grid[cell.x][cell.y] = null
            tile.queue_free()

        await _collapse_and_refill()

func _collapse_and_refill() -> void:
    for x in range(COLS):
        var write_y := ROWS - 1

        for y in range(ROWS - 1, -1, -1):
            var tile = grid[x][y]
            if tile != null:
                if y != write_y:
                    grid[x][write_y] = tile
                    grid[x][y] = null
                    tile.grid_pos = Vector2i(x, write_y)
                    tile.move_to(_cell_position(Vector2i(x, write_y)), 0.10)
                write_y -= 1

        for y in range(write_y, -1, -1):
            grid[x][y] = _spawn_tile(Vector2i(x, y), randi_range(0, 5), true)

    await get_tree().create_timer(0.11).timeout

func _find_hint() -> Array:
    if grid.size() != COLS:
        return []

    for x in range(COLS):
        for y in range(ROWS):
            var here := Vector2i(x, y)

            if x + 1 < COLS:
                var right := Vector2i(x + 1, y)
                _swap_refs(here, right)
                var works_right := not _find_matches().is_empty()
                _swap_refs(here, right)
                if works_right:
                    return [here, right]

            if y + 1 < ROWS:
                var down := Vector2i(x, y + 1)
                _swap_refs(here, down)
                var works_down := not _find_matches().is_empty()
                _swap_refs(here, down)
                if works_down:
                    return [here, down]

    return []

func _show_hint() -> void:
    if state != "game" or busy:
        return

    idle_seconds = 0.0
    var hint := _find_hint()

    if hint.is_empty():
        _new_board()
        message_label.text = "Поле перемешано."
        return

    grid[hint[0].x][hint[0].y].hint_pulse()
    grid[hint[1].x][hint[1].y].hint_pulse()
    message_label.text = "Подсказка: поменяй эти две фишки местами."

func _update_hud() -> void:
    if goal_label == null:
        return

    goal_label.text = "Сердца: %d/%d" % [min(hearts, HEART_GOAL), HEART_GOAL]
    moves_label.text = "Ходы: %d" % moves
    score_label.text = "Очки: %d" % score
    progress.value = min(hearts, HEART_GOAL)

func _finish_level(win: bool) -> void:
    state = "end"
    busy = true

    var overlay := ColorRect.new()
    overlay.color = Color(0, 0, 0, 0.72)
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hud_layer.add_child(overlay)

    var panel := ColorRect.new()
    panel.position = Vector2(70, 440)
    panel.size = Vector2(580, 330)
    panel.color = Color("153538")
    overlay.add_child(panel)

    var title := "УРОВЕНЬ ПРОЙДЕН!" if win else "ХОДЫ ЗАКОНЧИЛИСЬ"
    var subtitle := "Романтик собрался с духом. Движ продолжается!" if win else "Почти получилось. Ещё одна попытка."

    _label(overlay, title, Vector2(90, 480), Vector2(540, 65), 30, Color("8df0d5"))
    _label(overlay, subtitle, Vector2(110, 560), Vector2(500, 80), 18)
    _button(overlay, "ЕЩЁ РАЗ", Vector2(190, 665), Vector2(340, 68), _start_game)
