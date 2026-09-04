extends Node2D

var tile_type: int = 0
var grid_pos := Vector2i.ZERO
var sprite: Sprite2D
var base_scale := Vector2.ONE

const FALLBACK_COLORS := [
    Color("ff4f83"), Color("3e8cff"), Color("ff9e2f"),
    Color("8c52ff"), Color("35c759"), Color("ffd83d")
]

func _init() -> void:
    sprite = Sprite2D.new()
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    add_child(sprite)
    queue_redraw()

func configure(new_type: int, texture: Texture2D, new_grid_pos: Vector2i) -> void:
    tile_type = new_type
    grid_pos = new_grid_pos
    sprite.texture = texture
    var longest := max(float(texture.get_width()), float(texture.get_height()))
    var factor := 74.0 / longest if longest > 0.0 else 1.0
    base_scale = Vector2(factor, factor)
    sprite.scale = base_scale
    scale = Vector2.ONE
    modulate = Color.WHITE
    queue_redraw()

func _draw() -> void:
    var color := FALLBACK_COLORS[tile_type % FALLBACK_COLORS.size()]
    color.a = 0.22
    draw_rect(Rect2(-38, -38, 76, 76), color, true)
    draw_rect(Rect2(-38, -38, 76, 76), Color(1, 1, 1, 0.16), false, 2.0)

func move_to(target: Vector2, duration: float = 0.10) -> Tween:
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_QUAD)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "position", target, duration)
    return tween

func pop(duration: float = 0.08) -> void:
    var tween := create_tween().set_parallel(true)
    tween.tween_property(self, "scale", Vector2(0.12, 0.12), duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
    tween.tween_property(self, "modulate:a", 0.0, duration)

func set_selected(value: bool) -> void:
    var tween := create_tween()
    tween.tween_property(self, "scale", Vector2(1.12, 1.12) if value else Vector2.ONE, 0.07)

func hint_pulse() -> void:
    var tween := create_tween()
    tween.set_loops(2)
    tween.tween_property(self, "scale", Vector2(1.13, 1.13), 0.12)
    tween.tween_property(self, "scale", Vector2.ONE, 0.12)
