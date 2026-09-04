extends Node2D

const Tile = preload("res://scripts/tile.gd")
const ATLAS: Texture2D = preload("res://assets/tiles_atlas.webp")
const COLS := 7
const ROWS := 7
const STEP := 82.0
const MOVES_MAX := 18
const GOAL := 12
const SWIPE := 26.0
const VERSION := "DEV 0.2.0"

var tex: Array[Texture2D] = []
var grid: Array = []
var board: Node2D
var ui: CanvasLayer
var screen: Control
var state := "boot"
var busy := false
var moves := MOVES_MAX
var hearts := 0
var score := 0
var selected := Vector2i(-1, -1)
var touch_cell := Vector2i(-1, -1)
var touch_pos := Vector2.ZERO
var dragged := false
var mouse_down := false
var idle := 0.0
var first_match := false
var goal_label: Label
var moves_label: Label
var score_label: Label
var message: Label
var tutorial: Label
var bar: ProgressBar

func _ready() -> void:
    randomize()
    for i in range(6):
        var a := AtlasTexture.new()
        a.atlas = ATLAS
        a.region = Rect2((i % 3) * 24, int(i / 3) * 24, 24, 24)
        tex.append(a)
    board = Node2D.new()
    add_child(board)
    ui = CanvasLayer.new()
    add_child(ui)
    _splash()
    await get_tree().create_timer(0.65).timeout
    _menu()

func _process(delta: float) -> void:
    if state == "game" and not busy:
        idle += delta
        if idle > 5.0:
            idle = 0.0
            _hint()

func _clear_ui() -> void:
    for n in ui.get_children():
        n.queue_free()

func _root() -> Control:
    var c := Control.new()
    c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.add_child(c)
    return c

func _label(parent: Node, text: String, pos: Vector2, size: Vector2, font_size: int) -> Label:
    var l := Label.new()
    l.text = text
    l.position = pos
    l.size = size
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.add_theme_font_size_override("font_size", font_size)
    parent.add_child(l)
    return l

func _button(parent: Node, text: String, pos: Vector2, size: Vector2, callback: Callable) -> Button:
    var b := Button.new()
    b.text = text
    b.position = pos
    b.size = size
    b.add_theme_font_size_override("font_size", 22)
    b.pressed.connect(callback)
    parent.add_child(b)
    return b

func _brand_image(parent: Node) -> void:
    var bg := ColorRect.new()
    bg.color = Color("eefcf8")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    parent.add_child(bg)
    var pic := TextureRect.new()
    pic.texture = preload("res://assets/splash.jpg")
    pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(pic)

func _splash() -> void:
    state = "boot"
    board.visible = false
    _clear_ui()
    _brand_image(_root())

func _menu() -> void:
    state = "menu"
    board.visible = false
    _clear_ui()
    var r := _root()
    _brand_image(r)
    var shade := ColorRect.new()
    shade.color = Color(0.0, 0.10, 0.09, 0.42)
    shade.position = Vector2(45, 810)
    shade.size = Vector2(630, 390)
    r.add_child(shade)
    _label(r, "ФЕСТИВАЛИМ\nСОБЕРИ ДВИЖ!", Vector2(70, 835), Vector2(580, 115), 36)
    _label(r, "Свайпай соседние фишки.\nСобери 3 одинаковые в ряд.\nЦель: 12 сердец за 18 ходов.", Vector2(80, 955), Vector2(560, 125), 20)
    _button(r, "ИГРАТЬ", Vector2(170, 1090), Vector2(380, 72), _start)
    var v := _label(r, VERSION, Vector2(0, 1190), Vector2(720, 30), 13)
    v.modulate = Color(1, 1, 1, 0.65)

func _start() -> void:
    state = "game"
    busy = false
    moves = MOVES_MAX
    hearts = 0
    score = 0
    selected = Vector2i(-1, -1)
    first_match = false
    idle = 0.0
    _clear_ui()
    _build_game_ui()
    board.visible = true
    _new_board()
    _update_ui()
    message.text = "Свайпни фишку так, чтобы получилось 3 одинаковые."

func _build_game_ui() -> void:
    screen = _root()
    var bg := ColorRect.new()
    bg.color = Color("071719")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    screen.add_child(bg)
    _label(screen, "ФЕСТИВАЛИМ — ПЯТНИЦА", Vector2(25, 22), Vector2(670, 48), 25)
    tutorial = _label(screen, "ОБУЧЕНИЕ: собери 3 одинаковые фишки в ряд", Vector2(45, 75), Vector2(630, 58), 18)
    goal_label = _label(screen, "", Vector2(25, 145), Vector2(230, 45), 19)
    moves_label = _label(screen, "", Vector2(245, 145), Vector2(230, 45), 19)
    score_label = _label(screen, "", Vector2(465, 145), Vector2(230, 45), 19)
    bar = ProgressBar.new()
    bar.position = Vector2(65, 200)
    bar.size = Vector2(590, 32)
    bar.max_value = GOAL
    bar.show_percentage = false
    screen.add_child(bar)
    message = _label(screen, "", Vector2(40, 245), Vector2(640, 70), 18)
    _button(screen, "ПОДСКАЗКА", Vector2(90, 1050), Vector2(250, 62), _hint)
    _button(screen, "ЗАНОВО", Vector2(380, 1050), Vector2(250, 62), _start)
    var v := _label(screen, VERSION, Vector2(0, 1130), Vector2(720, 28), 12)
    v.modulate = Color(1, 1, 1, 0.35)
    board.position = Vector2(114, 420)

func _clear_board() -> void:
    for n in board.get_children():
        n.queue_free()
    grid.clear()

func _new_board() -> void:
    _clear_board()
    for attempt in range(60):
        for n in board.get_children():
            n.queue_free()
        grid.clear()
        grid.resize(COLS)
        for x in range(COLS):
            grid[x] = []
            grid[x].resize(ROWS)
            for y in range(ROWS):
                var t := randi_range(0, 5)
                while (x >= 2 and grid[x-1][y].tile_type == t and grid[x-2][y].tile_type == t) or (y >= 2 and grid[x][y-1].tile_type == t and grid[x][y-2].tile_type == t):
                    t = randi_range(0, 5)
                grid[x][y] = _spawn(Vector2i(x, y), t, false)
        if not _find_hint().is_empty():
            return

func _spawn(cell: Vector2i, t: int, drop: bool) -> Node2D:
    var n = Tile.new()
    board.add_child(n)
    n.configure(t, tex[t], cell)
    var p := _pixel(cell)
    n.position = p + (Vector2(0, -STEP * 1.5) if drop else Vector2.ZERO)
    if drop:
        n.move_to(p, 0.10)
    return n

func _pixel(c: Vector2i) -> Vector2:
    return Vector2(c.x * STEP, c.y * STEP)

func _cell(p: Vector2) -> Vector2i:
    var q := board.to_local(p)
    var c := Vector2i(int(round(q.x / STEP)), int(round(q.y / STEP)))
    if c.x < 0 or c.x >= COLS or c.y < 0 or c.y >= ROWS:
        return Vector2i(-1, -1)
    return c if q.distance_to(_pixel(c)) < STEP * 0.48 else Vector2i(-1, -1)

func _input(e: InputEvent) -> void:
    if state != "game" or busy:
        return
    if e is InputEventScreenTouch:
        if e.pressed: _press(e.position)
        else: _release(e.position)
    elif e is InputEventScreenDrag:
        _drag(e.position)
    elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
        mouse_down = e.pressed
        if e.pressed: _press(e.position)
        else: _release(e.position)
    elif e is InputEventMouseMotion and mouse_down:
        _drag(e.position)

func _press(p: Vector2) -> void:
    idle = 0.0
    touch_cell = _cell(p)
    touch_pos = p
    dragged = false

func _drag(p: Vector2) -> void:
    if dragged or touch_cell.x < 0:
        return
    var d := p - touch_pos
    if d.length() < SWIPE:
        return
    var dir := Vector2i.ZERO
    if abs(d.x) > abs(d.y): dir.x = 1 if d.x > 0 else -1
    else: dir.y = 1 if d.y > 0 else -1
    var b := touch_cell + dir
    if b.x < 0 or b.x >= COLS or b.y < 0 or b.y >= ROWS:
        return
    dragged = true
    _clear_selected()
    _try_swap(touch_cell, b)

func _release(p: Vector2) -> void:
    if not dragged and touch_cell.x >= 0:
        var c := _cell(p)
        if c.x >= 0: _tap(c)
    touch_cell = Vector2i(-1, -1)
    dragged = false

func _tap(c: Vector2i) -> void:
    if selected.x < 0:
        selected = c
        grid[c.x][c.y].set_selected(true)
        message.text = "Фишка выбрана. Теперь выбери соседнюю."
    elif selected == c:
        _clear_selected()
    elif abs(selected.x-c.x) + abs(selected.y-c.y) == 1:
        var a := selected
        _clear_selected()
        _try_swap(a, c)
    else:
        grid[selected.x][selected.y].set_selected(false)
        selected = c
        grid[c.x][c.y].set_selected(true)

func _clear_selected() -> void:
    if selected.x >= 0 and grid.size() == COLS and grid[selected.x][selected.y] != null:
        grid[selected.x][selected.y].set_selected(false)
    selected = Vector2i(-1, -1)

func _swap(a: Vector2i, b: Vector2i, animate := true) -> void:
    var one = grid[a.x][a.y]
    var two = grid[b.x][b.y]
    grid[a.x][a.y] = two
    grid[b.x][b.y] = one
    one.grid_pos = b
    two.grid_pos = a
    if animate:
        one.move_to(_pixel(b), 0.09)
        two.move_to(_pixel(a), 0.09)

func _try_swap(a: Vector2i, b: Vector2i) -> void:
    if busy: return
    busy = true
    _swap(a, b)
    await get_tree().create_timer(0.10).timeout
    if _matches().is_empty():
        _swap(a, b)
        message.text = "Нет тройки — ход отменён."
        await get_tree().create_timer(0.10).timeout
        busy = false
        return
    moves -= 1
    await _resolve()
    _update_ui()
    if hearts >= GOAL:
        busy = false
        _end(true)
        return
    if moves <= 0:
        busy = false
        _end(false)
        return
    if _find_hint().is_empty():
        _new_board()
        message.text = "Ходов не осталось — поле перемешано."
    if not first_match:
        first_match = true
        tutorial.text = "Отлично! Теперь собирай сердца. Каскады тоже считаются."
    busy = false

func _matches() -> Array:
    var out := {}
    for y in range(ROWS):
        var s := 0
        for x in range(1, COLS + 1):
            if x == COLS or grid[x][y].tile_type != grid[s][y].tile_type:
                if x-s >= 3:
                    for k in range(s, x): out[grid[k][y]] = true
                s = x
    for x in range(COLS):
        var s := 0
        for y in range(1, ROWS + 1):
            if y == ROWS or grid[x][y].tile_type != grid[x][s].tile_type:
                if y-s >= 3:
                    for k in range(s, y): out[grid[x][k]] = true
                s = y
    return out.keys()

func _resolve() -> void:
    var combo := 0
    while combo < 15:
        var m := _matches()
        if m.is_empty(): return
        combo += 1
        var gain := 0
        for n in m:
            if n.tile_type == 0: gain += 1
            n.pop(0.07)
        hearts += gain
        score += m.size() * 100 * combo
        _update_ui()
        message.text = "Комбинация!" + ("  Каскад x%d" % combo if combo > 1 else "")
        await get_tree().create_timer(0.08).timeout
        for n in m:
            var c: Vector2i = n.grid_pos
            if grid[c.x][c.y] == n: grid[c.x][c.y] = null
            n.queue_free()
        await _fall()

func _fall() -> void:
    for x in range(COLS):
        var write := ROWS-1
        for y in range(ROWS-1, -1, -1):
            var n = grid[x][y]
            if n != null:
                if y != write:
                    grid[x][write] = n
                    grid[x][y] = null
                    n.grid_pos = Vector2i(x, write)
                    n.move_to(_pixel(Vector2i(x, write)), 0.10)
                write -= 1
        for y in range(write, -1, -1):
            grid[x][y] = _spawn(Vector2i(x, y), randi_range(0,5), true)
    await get_tree().create_timer(0.11).timeout

func _find_hint() -> Array:
    if grid.size() != COLS: return []
    for x in range(COLS):
        for y in range(ROWS):
            var a := Vector2i(x,y)
            if x+1 < COLS:
                var right := Vector2i(x+1,y)
                _swap(a,right,false)
                var right_ok := not _matches().is_empty()
                _swap(a,right,false)
                if right_ok: return [a,right]
            if y+1 < ROWS:
                var down := Vector2i(x,y+1)
                _swap(a,down,false)
                var down_ok := not _matches().is_empty()
                _swap(a,down,false)
                if down_ok: return [a,down]
    return []

func _hint() -> void:
    if state != "game" or busy: return
    idle = 0.0
    var h := _find_hint()
    if h.is_empty():
        _new_board()
        message.text = "Поле перемешано."
        return
    grid[h[0].x][h[0].y].hint_pulse()
    grid[h[1].x][h[1].y].hint_pulse()
    message.text = "Подсказка: смотри на две пульсирующие фишки."

func _update_ui() -> void:
    if goal_label == null: return
    goal_label.text = "Сердца: %d/%d" % [min(hearts,GOAL), GOAL]
    moves_label.text = "Ходы: %d" % moves
    score_label.text = "Очки: %d" % score
    bar.value = min(hearts, GOAL)

func _end(win: bool) -> void:
    state = "end"
    board.visible = false
    var dim := ColorRect.new()
    dim.color = Color(0.0,0.05,0.04,0.96)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    screen.add_child(dim)
    _label(dim, "ДВИЖ СОБРАН!" if win else "ХОДЫ ЗАКОНЧИЛИСЬ", Vector2(60,350), Vector2(600,100), 34)
    _label(dim, "Сердца: %d/%d\nОчки: %d" % [min(hearts,GOAL),GOAL,score], Vector2(100,480), Vector2(520,130), 24)
    _button(dim, "ЕЩЁ РАЗ", Vector2(170,660), Vector2(380,70), _start)
    _button(dim, "В МЕНЮ", Vector2(170,750), Vector2(380,62), _menu)
