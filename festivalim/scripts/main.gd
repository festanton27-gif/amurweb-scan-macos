extends Control

const ROWS := 8
const COLS := 7
const TILE_TYPES := 6
const START_MOVES := 20
const HEART_GOAL := 15
const SWIPE_THRESHOLD := 24.0
const MAX_CASCADES := 30

var board: Array = []
var buttons: Array = []
var selected := Vector2i(-1, -1)
var moves := START_MOVES
var hearts := 0
var score := 0
var busy := false

var pointer_start_cell := Vector2i(-1, -1)
var pointer_start_pos := Vector2.ZERO
var pointer_dragged := false
var mouse_down := false

var moves_label: Label
var score_label: Label
var goal_label: Label
var status_label: Label
var party_bar: ProgressBar
var grid: GridContainer
var restart_button: Button

var tile_style: StyleBoxFlat
var tile_selected_style: StyleBoxFlat

const ICONS := ["♥", "♫", "☺", "★", "●", "✦"]
const NAMES := ["Знакомство", "Музыка", "Юмор", "Фото", "Напитки", "Танцы"]
const COLORS := [
    Color("e94873"), Color("438cff"), Color("9f65ff"),
    Color("ffad33"), Color("49b85a"), Color("ff5dba")
]

func _ready() -> void:
    randomize()
    _make_tile_styles()
    _build_ui()
    _new_game()

func _make_tile_styles() -> void:
    tile_style = StyleBoxFlat.new()
    tile_style.bg_color = Color("18213b")
    tile_style.border_color = Color("2b385d")
    tile_style.set_border_width_all(2)
    tile_style.corner_radius_top_left = 14
    tile_style.corner_radius_top_right = 14
    tile_style.corner_radius_bottom_left = 14
    tile_style.corner_radius_bottom_right = 14

    tile_selected_style = tile_style.duplicate()
    tile_selected_style.bg_color = Color("303a5c")
    tile_selected_style.border_color = Color("ffd166")
    tile_selected_style.set_border_width_all(5)

func _build_ui() -> void:
    var bg := ColorRect.new()
    bg.color = Color("091126")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)

    var root := VBoxContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_theme_constant_override("separation", 9)
    root.offset_left = 18
    root.offset_right = -18
    root.offset_top = 20
    root.offset_bottom = -16
    root.mouse_filter = Control.MOUSE_FILTER_PASS
    add_child(root)

    var title := Label.new()
    title.text = "ФЕСТИВАЛИМ: СОБЕРИ ДВИЖ!"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 27)
    root.add_child(title)

    var event_label := Label.new()
    event_label.text = "Пятница на набережной  •  Позитивный фестивальщик"
    event_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    event_label.modulate = Color("ffd166")
    event_label.add_theme_font_size_override("font_size", 16)
    root.add_child(event_label)

    var party_title := Label.new()
    party_title.text = "ДВИЖ ВЕЧЕРИНКИ"
    party_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    root.add_child(party_title)

    party_bar = ProgressBar.new()
    party_bar.min_value = 0
    party_bar.max_value = 100
    party_bar.value = 20
    party_bar.show_percentage = true
    party_bar.custom_minimum_size = Vector2(0, 32)
    root.add_child(party_bar)

    var characters := HBoxContainer.new()
    characters.alignment = BoxContainer.ALIGNMENT_CENTER
    characters.add_theme_constant_override("separation", 8)
    root.add_child(characters)
    for text in ["♥ Романтик", "♫ Диджей", "☺ Радио", "✦ Танцор"]:
        var chip := Label.new()
        chip.text = text
        chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        chip.add_theme_font_size_override("font_size", 14)
        chip.custom_minimum_size = Vector2(145, 32)
        characters.add_child(chip)

    var mission := PanelContainer.new()
    root.add_child(mission)
    var mission_box := VBoxContainer.new()
    mission_box.add_theme_constant_override("separation", 3)
    mission.add_child(mission_box)

    var mission_head := Label.new()
    mission_head.text = "СИТУАЦИЯ: Романтик наконец решился подойти к девушке!"
    mission_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    mission_head.add_theme_font_size_override("font_size", 17)
    mission_box.add_child(mission_head)

    goal_label = Label.new()
    goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    goal_label.add_theme_font_size_override("font_size", 16)
    mission_box.add_child(goal_label)

    status_label = Label.new()
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    status_label.add_theme_font_size_override("font_size", 16)
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.custom_minimum_size = Vector2(0, 44)
    root.add_child(status_label)

    grid = GridContainer.new()
    grid.columns = COLS
    grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation", 5)
    grid.add_theme_constant_override("v_separation", 5)
    grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(grid)

    var footer := HBoxContainer.new()
    footer.alignment = BoxContainer.ALIGNMENT_CENTER
    footer.add_theme_constant_override("separation", 18)
    root.add_child(footer)

    moves_label = Label.new()
    moves_label.add_theme_font_size_override("font_size", 20)
    footer.add_child(moves_label)

    score_label = Label.new()
    score_label.add_theme_font_size_override("font_size", 20)
    footer.add_child(score_label)

    restart_button = Button.new()
    restart_button.text = "Заново"
    restart_button.pressed.connect(_new_game)
    footer.add_child(restart_button)

    var version_label := Label.new()
    version_label.text = "DEV 0.1.3"
    version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    version_label.modulate = Color(1, 1, 1, 0.45)
    version_label.add_theme_font_size_override("font_size", 12)
    root.add_child(version_label)

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed:
            _pointer_press(touch.position)
        else:
            _pointer_release(touch.position)
        return

    if event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        _pointer_drag(drag.position)
        return

    if event is InputEventMouseButton:
        var mouse_button := event as InputEventMouseButton
        if mouse_button.device == InputEvent.DEVICE_ID_EMULATION:
            return
        if mouse_button.button_index == MOUSE_BUTTON_LEFT:
            mouse_down = mouse_button.pressed
            if mouse_button.pressed:
                _pointer_press(mouse_button.position)
            else:
                _pointer_release(mouse_button.position)
        return

    if event is InputEventMouseMotion and mouse_down:
        var mouse_motion := event as InputEventMouseMotion
        if mouse_motion.device != InputEvent.DEVICE_ID_EMULATION:
            _pointer_drag(mouse_motion.position)

func _pointer_press(position: Vector2) -> void:
    if busy or moves <= 0 or hearts >= HEART_GOAL:
        return
    pointer_start_cell = _cell_at_position(position)
    pointer_start_pos = position
    pointer_dragged = false

func _pointer_drag(position: Vector2) -> void:
    if busy or pointer_dragged or pointer_start_cell.x < 0:
        return

    var delta := position - pointer_start_pos
    if delta.length() < SWIPE_THRESHOLD:
        return

    var direction := Vector2i.ZERO
    if abs(delta.x) >= abs(delta.y):
        direction.x = 1 if delta.x > 0 else -1
    else:
        direction.y = 1 if delta.y > 0 else -1

    var target := pointer_start_cell + direction
    if not _is_valid_cell(target):
        return

    pointer_dragged = true
    selected = Vector2i(-1, -1)
    _attempt_swap(pointer_start_cell, target)

func _pointer_release(position: Vector2) -> void:
    if pointer_start_cell.x < 0:
        return

    if not pointer_dragged:
        var released_cell := _cell_at_position(position)
        if released_cell.x < 0:
            released_cell = pointer_start_cell
        _handle_tap(released_cell)

    pointer_start_cell = Vector2i(-1, -1)
    pointer_dragged = false

func _cell_at_position(position: Vector2) -> Vector2i:
    for r in range(ROWS):
        for c in range(COLS):
            if r >= buttons.size() or c >= buttons[r].size():
                continue
            var button: Button = buttons[r][c]
            if Rect2(button.global_position, button.size).has_point(position):
                return Vector2i(c, r)
    return Vector2i(-1, -1)

func _is_valid_cell(cell: Vector2i) -> bool:
    return cell.x >= 0 and cell.x < COLS and cell.y >= 0 and cell.y < ROWS

func _handle_tap(pos: Vector2i) -> void:
    if busy or not _is_valid_cell(pos) or moves <= 0 or hearts >= HEART_GOAL:
        return

    if selected.x < 0:
        selected = pos
        status_label.text = "Выбрана «%s». Тапни соседнюю фишку." % NAMES[board[pos.y][pos.x]]
        _refresh()
        return

    if selected == pos:
        selected = Vector2i(-1, -1)
        status_label.text = "Выбор снят."
        _refresh()
        return

    if abs(selected.x - pos.x) + abs(selected.y - pos.y) != 1:
        selected = pos
        status_label.text = "Выбрана другая фишка. Для хода нужна соседняя."
        _refresh()
        return

    var first := selected
    selected = Vector2i(-1, -1)
    _attempt_swap(first, pos)

func _new_game() -> void:
    busy = false
    selected = Vector2i(-1, -1)
    pointer_start_cell = Vector2i(-1, -1)
    pointer_dragged = false
    mouse_down = false
    moves = START_MOVES
    hearts = 0
    score = 0
    board.clear()
    buttons.clear()
    party_bar.value = 20

    for child in grid.get_children():
        grid.remove_child(child)
        child.queue_free()

    _generate_playable_board()

    for r in range(ROWS):
        var brow: Array = []
        for c in range(COLS):
            var button := Button.new()
            button.custom_minimum_size = Vector2(82, 82)
            button.focus_mode = Control.FOCUS_NONE
            button.mouse_filter = Control.MOUSE_FILTER_IGNORE
            button.add_theme_font_size_override("font_size", 35)
            button.add_theme_stylebox_override("normal", tile_style)
            button.add_theme_stylebox_override("hover", tile_style)
            button.add_theme_stylebox_override("pressed", tile_selected_style)
            grid.add_child(button)
            brow.append(button)
        buttons.append(brow)

    status_label.text = "Свайпни фишку или тапни две соседние. Ход должен сработать сразу."
    _refresh()

func _generate_playable_board() -> void:
    var attempts := 0
    while attempts < 50:
        attempts += 1
        board.clear()
        for r in range(ROWS):
            var row: Array = []
            for c in range(COLS):
                var tile := randi_range(0, TILE_TYPES - 1)
                while (c >= 2 and row[c - 1] == tile and row[c - 2] == tile) or (r >= 2 and board[r - 1][c] == tile and board[r - 2][c] == tile):
                    tile = randi_range(0, TILE_TYPES - 1)
                row.append(tile)
            board.append(row)
        if _board_has_move():
            return

func _board_has_move() -> bool:
    for r in range(ROWS):
        for c in range(COLS):
            var here := Vector2i(c, r)
            if c + 1 < COLS:
                var right := Vector2i(c + 1, r)
                _swap(here, right)
                var right_works := not _find_matches().is_empty()
                _swap(here, right)
                if right_works:
                    return true
            if r + 1 < ROWS:
                var down := Vector2i(c, r + 1)
                _swap(here, down)
                var down_works := not _find_matches().is_empty()
                _swap(here, down)
                if down_works:
                    return true
    return false

func _attempt_swap(first: Vector2i, second: Vector2i) -> void:
    if busy or not _is_valid_cell(first) or not _is_valid_cell(second):
        return

    busy = true
    _swap(first, second)

    var matches := _find_matches()
    if matches.is_empty():
        _swap(first, second)
        status_label.text = "Нет комбинации — ход отменён."
        busy = false
        _refresh()
        return

    moves -= 1
    var cascades := _resolve_board()
    status_label.text = "Движ! Комбо x%d." % cascades if cascades > 1 else "Движ! Комбинация собрана."

    if moves > 0 and hearts < HEART_GOAL and not _board_has_move():
        _generate_playable_board()
        status_label.text = "Поле закончилось — перемешал фишки."

    busy = false
    _refresh()
    _check_end()

func _swap(a: Vector2i, b: Vector2i) -> void:
    var temp = board[a.y][a.x]
    board[a.y][a.x] = board[b.y][b.x]
    board[b.y][b.x] = temp

func _find_matches() -> Array:
    var found := {}

    for r in range(ROWS):
        var run_start := 0
        for c in range(1, COLS + 1):
            if c == COLS or board[r][c] != board[r][run_start]:
                if c - run_start >= 3:
                    for x in range(run_start, c):
                        found[Vector2i(x, r)] = true
                run_start = c

    for c in range(COLS):
        var run_start := 0
        for r in range(1, ROWS + 1):
            if r == ROWS or board[r][c] != board[run_start][c]:
                if r - run_start >= 3:
                    for y in range(run_start, r):
                        found[Vector2i(c, y)] = true
                run_start = r

    return found.keys()

func _resolve_board() -> int:
    var cascades := 0

    while cascades < MAX_CASCADES:
        var matches := _find_matches()
        if matches.is_empty():
            break

        cascades += 1
        var heart_count := 0

        for pos in matches:
            if board[pos.y][pos.x] == 0:
                heart_count += 1
            board[pos.y][pos.x] = -1

        hearts += heart_count
        score += matches.size() * 100 * cascades
        party_bar.value = min(100.0, party_bar.value + float(matches.size()) * 1.7)
        _collapse()

    return max(1, cascades)

func _collapse() -> void:
    for c in range(COLS):
        var write_row := ROWS - 1
        for r in range(ROWS - 1, -1, -1):
            if board[r][c] != -1:
                board[write_row][c] = board[r][c]
                write_row -= 1
        while write_row >= 0:
            board[write_row][c] = randi_range(0, TILE_TYPES - 1)
            write_row -= 1

func _check_end() -> void:
    if hearts >= HEART_GOAL:
        status_label.text = "♥ Романтик познакомился! Уровень пройден."
        party_bar.value = min(100.0, party_bar.value + 15.0)
    elif moves <= 0:
        status_label.text = "Ходы закончились. Романтик: «В следующий раз точно подойду»."

func _refresh() -> void:
    moves_label.text = "Ходы: %d" % moves
    score_label.text = "Очки: %d" % score
    goal_label.text = "Собери ♥  %d / %d" % [min(hearts, HEART_GOAL), HEART_GOAL]

    for r in range(ROWS):
        for c in range(COLS):
            if r >= buttons.size() or c >= buttons[r].size():
                continue

            var button: Button = buttons[r][c]
            var tile: int = board[r][c]

            if selected == Vector2i(c, r):
                button.add_theme_stylebox_override("normal", tile_selected_style)
                button.add_theme_stylebox_override("hover", tile_selected_style)
            else:
                button.add_theme_stylebox_override("normal", tile_style)
                button.add_theme_stylebox_override("hover", tile_style)

            if tile < 0:
                button.text = ""
                button.modulate = Color(1, 1, 1, 0.35)
            else:
                button.text = ICONS[tile]
                button.tooltip_text = NAMES[tile]
                button.modulate = COLORS[tile]
