extends Node2D

var tile_type: int = 0
var grid_pos := Vector2i.ZERO
var sprite: Sprite2D
var selected_state: bool = false

const FALLBACK_COLORS := [
    Color("ff4f83"), Color("3e8cff"), Color("ff9e2f"),
    Color("8c52ff"), Color("35c759"), Color("ffd83d")
]

func _init() -> void:
    sprite = Sprite2D.new()
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    add_child(sprite)
    queue_redraw()

func configure(new_type: int, texture: Texture2D, new_grid_pos: Vector2i) -> void:
    tile_type = new_type
    grid_pos = new_grid_pos
    sprite.texture = texture
    var longest: float = max(float(texture.get_width()), float(texture.get_height()))
    var factor: float = 76.0 / longest if longest > 0.0 else 1.0
    sprite.scale = Vector2(factor, factor)
    scale = Vector2.ONE
    modulate = Color.WHITE
    selected_state = false
    queue_redraw()

func _draw() -> void:
    if sprite == null or sprite.texture == null:
        var c: Color = FALLBACK_COLORS[tile_type % FALLBACK_COLORS.size()]
        c.a = 0.55
        draw_rect(Rect2(-38, -38, 76, 76), c, true)

    if selected_state:
        draw_rect(Rect2(-40, -40, 80, 80), Color("8df0d5"), false, 4.0)
        draw_circle(Vector2.ZERO, 43.0, Color(0.55, 0.95, 0.84, 0.16), false, 3.0)
    else:
        draw_rect(Rect2(-39, -39, 78, 78), Color(1, 1, 1, 0.12), false, 1.5)

func move_to(target: Vector2, duration: float = 0.085) -> Tween:
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_QUAD)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "position", target, duration)
    return tween

func pop(duration: float = 0.075) -> void:
    var tween := create_tween().set_parallel(true)
    tween.tween_property(self, "scale", Vector2(0.10, 0.10), duration)
    tween.tween_property(self, "modulate:a", 0.0, duration)

func set_selected(value: bool) -> void:
    selected_state = value
    queue_redraw()
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_BACK)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "scale", Vector2(1.10, 1.10) if value else Vector2.ONE, 0.07)

func hint_pulse() -> void:
    var tween := create_tween()
    tween.set_loops(2)
    tween.set_trans(Tween.TRANS_SINE)
    tween.tween_property(self, "scale", Vector2(1.13, 1.13), 0.11)
    tween.tween_property(self, "scale", Vector2.ONE, 0.11)
