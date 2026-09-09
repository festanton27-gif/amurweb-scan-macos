extends "res://scripts/tile023.gd"

var special_kind: int = 0

func configure(new_type: int, texture: Texture2D, new_grid_pos: Vector2i) -> void:
    super.configure(new_type, texture, new_grid_pos)
    special_kind = 0
    queue_redraw()

func set_special(kind: int, texture: Texture2D) -> void:
    special_kind = kind
    if texture != null:
        sprite.texture = texture
        var longest: float = maxf(float(texture.get_width()), float(texture.get_height()))
        var factor: float = 76.0 / longest if longest > 0.0 else 1.0
        sprite.scale = Vector2(factor, factor)
    scale = Vector2.ONE
    modulate = Color.WHITE
    queue_redraw()

    var tween := create_tween()
    tween.set_trans(Tween.TRANS_BACK)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "scale", Vector2(1.18, 1.18), 0.10)
    tween.tween_property(self, "scale", Vector2.ONE, 0.10)

func _draw() -> void:
    super._draw()
    if special_kind == 1:
        draw_circle(Vector2.ZERO, 41.0, Color(0.55, 0.95, 0.84, 0.32), false, 3.0)
    elif special_kind == 2:
        draw_circle(Vector2.ZERO, 42.0, Color(1.0, 0.85, 0.24, 0.42), false, 4.0)
