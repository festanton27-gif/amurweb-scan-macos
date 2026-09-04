extends Node2D

var tile_type: int = 0
var grid_pos := Vector2i.ZERO
var sprite: Sprite2D

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

    var texture_width: float = float(texture.get_width())
    var texture_height: float = float(texture.get_height())
    var longest: float = maxf(texture_width, texture_height)
    var factor: float = 1.0
    if longest > 0.0:
        factor = 74.0 / longest

    sprite.scale = Vector2(factor, factor)
    scale = Vector2.ONE
    modulate = Color.WHITE
    queue_redraw()

func _draw() -> void:
    var c: Color = FALLBACK_COLORS[tile_type % FALLBACK_COLORS.size()]
    c.a = 0.28
    draw_rect(Rect2(-38, -38, 76, 76), c, true)
    draw_rect(Rect2(-38, -38, 76, 76), Color(1, 1, 1, 0.22), false, 2.0)

func move_to(target: Vector2, duration: float = 0.09) -> Tween:
    var tween: Tween = create_tween()
    tween.set_trans(Tween.TRANS_QUAD)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "position", target, duration)
    return tween

func pop(duration: float = 0.08) -> void:
    var tween: Tween = create_tween().set_parallel(true)
    tween.tween_property(self, "scale", Vector2(0.12, 0.12), duration)
    tween.tween_property(self, "modulate:a", 0.0, duration)

func set_selected(value: bool) -> void:
    var tween: Tween = create_tween()
    tween.tween_property(self, "scale", Vector2(1.12, 1.12) if value else Vector2.ONE, 0.06)

func hint_pulse() -> void:
    var tween: Tween = create_tween()
    tween.set_loops(2)
    tween.tween_property(self, "scale", Vector2(1.14, 1.14), 0.11)
    tween.tween_property(self, "scale", Vector2.ONE, 0.11)
