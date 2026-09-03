extends Control

const ROWS := 8
const COLS := 7
const TILE_TYPES := 6
const START_MOVES := 20
const HEART_GOAL := 15

var board: Array = []
var buttons: Array = []
var selected := Vector2i(-1, -1)
var moves := START_MOVES
var hearts := 0
var score := 0
var busy := false

var moves_label: Label
var score_label: Label
var goal_label: Label
var status_label: Label
var party_bar: ProgressBar
var grid: GridContainer
var restart_button: Button

const ICONS := ["♥", "♫", "☺", "★", "●", "✦"]
const NAMES := ["Знакомство", "Музыка", "Юмор", "Фото", "Напитки", "Танцы"]
const COLORS := [
    Color("e94873"), Color("438cff"), Color("9f65ff"),
    Color("ffad33"), Color("49b85a"), Color("ff5dba")
]

func _ready() -> void:
    _build_ui()
    _new_game()

func _build_ui() -> void:
    var bg := ColorRect.new()
    bg.color = Color("091126")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var root := VBoxContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_theme_constant_override("separation", 12)
    root.offset_left = 18
    root.offset_right = -18
    root.offset_top = 24
    root.offset_bottom = -20
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
    party_bar.custom_minimum_size = Vector2(0, 34)
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
        chip.custom_minimum_size = Vector2(145, 34)
        characters.add_child(chip)

    var mission := PanelContainer.new()
    root.add_child(mission)
    var mission_box := VBoxContainer.new()
    mission_box.add_theme_constant_override("separation", 4)
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

    grid = GridContainer.new()
    grid.columns = COLS
    grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation", 5)
    grid.add_theme_constant_override("v_separation", 5)
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

    status_label = Label.new()
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.add_theme_font_size_override("font_size", 16)
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    root.add_child(status_label)

func _new_game() -> void:
    busy = false
    selected = Vector2i(-1, -1)
    moves = START_MOVES
    hearts = 0
    score = 0
    board.clear()
    buttons.clear()
    for child in grid.get_children():
        child.queue_free()

    for r in ROWS:
        var row: Array[int] = []
        for c in COLS:
            var t := randi_range(0, TILE_TYPES - 1)
            while (c >= 2 and row[c - 1] == t and row[c - 2] == t) or (r >= 2 and board[r - 1][c] == t and board[r - 2][c] == t):
                t = randi_range(0, TILE_TYPES - 1)
            row.append(t)
        board.append(row)

    for r in ROWS:
        var brow: Array[Button] = []
        for c in COLS:
            var b := Button.new()
            b.custom_minimum_size = Vector2(82, 82)
            b.add_theme_font_size_override("font_size", 34)
            b.pressed.connect(_on_tile_pressed.bind(r, c))
            grid.add_child(b)
            brow.append(b)
        buttons.append(brow)
    status_label.text = "Собери три одинаковых символа. Цель — помочь Романтику собрать сердца."
    _refresh()

func _on_tile_pressed(r: int, c: int) -> void:
    if busy or moves <= 0 or hearts >= HEART_GOAL:
        return
    var pos := Vector2i(c, r)
    if selected.x < 0:
        selected = pos
        _refresh()
        return
    if selected == pos:
        selected = Vector2i(-1, -1)
        _refresh()
        return
    if abs(selected.x - pos.x) + abs(selected.y - pos.y) != 1:
        selected = pos
        _refresh()
        return

    var a := selected
    var b := pos
    selected = Vector2i(-1, -1)
    _swap(a, b)
    var matches := _find_matches()
    if matches.is_empty():
        _swap(a, b)
        status_label.text = "Комбинации нет. Попробуй соседнюю фишку."
        _refresh()
        return

    moves -= 1
    status_label.text = "Движ пошёл!"
    await _resolve_board()

func _swap(a: Vector2i, b: Vector2i) -> void:
    var temp = board[a.y][a.x]
    board[a.y][a.x] = board[b.y][b.x]
    board[b.y][b.x] = temp

func _find_matches() -> Array[Vector2i]:
    var found := {}
    for r in ROWS:
        var run_start := 0
        for c in range(1, COLS + 1):
            if c == COLS or board[r][c] != board[r][run_start]:
                if c - run_start >= 3:
                    for x in range(run_start, c):
                        found[Vector2i(x, r)] = true
                run_start = c
    for c in COLS:
        var run_start := 0
        for r in range(1, ROWS + 1):
            if r == ROWS or board[r][c] != board[run_start][c]:
                if r - run_start >= 3:
                    for y in range(run_start, r):
                        found[Vector2i(c, y)] = true
                run_start = r
    return found.keys()

func _resolve_board() -> void:
    busy = true
    while true:
        var matches := _find_matches()
        if matches.is_empty():
            break
        var heart_count := 0
        for p in matches:
            if board[p.y][p.x] == 0:
                heart_count += 1
            board[p.y][p.x] = -1
        hearts += heart_count
        score += matches.size() * 100
        party_bar.value = min(100, party_bar.value + matches.size() * 1.7)
        _refresh()
        await get_tree().create_timer(0.14).timeout
        _collapse()
        _refresh()
        await get_tree().create_timer(0.12).timeout
    busy = false
    _refresh()
    _check_end()

func _collapse() -> void:
    for c in COLS:
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
        status_label.text = "♥ Романтик познакомился! Уровень пройден. Движ продолжается!"
        party_bar.value = min(100, party_bar.value + 15)
    elif moves <= 0:
        status_label.text = "Ходы закончились. Романтик опять сказал: «В следующий раз точно подойду»."

func _refresh() -> void:
    moves_label.text = "Ходы: %d" % moves
    score_label.text = "Очки: %d" % score
    goal_label.text = "Собери ♥  %d / %d" % [min(hearts, HEART_GOAL), HEART_GOAL]
    for r in ROWS:
        for c in COLS:
            if r >= buttons.size() or c >= buttons[r].size():
                continue
            var b: Button = buttons[r][c]
            var t: int = board[r][c]
            if t < 0:
                b.text = ""
                b.modulate = Color(1, 1, 1, 0.25)
            else:
                b.text = ICONS[t]
                b.tooltip_text = NAMES[t]
                b.modulate = COLORS[t]
            if selected == Vector2i(c, r):
                b.scale = Vector2(0.9, 0.9)
            else:
                b.scale = Vector2.ONE
