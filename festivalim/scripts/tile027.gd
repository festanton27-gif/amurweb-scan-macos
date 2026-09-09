extends "res://scripts/tile025.gd"

const VISUAL_SIZE_027 := 88.0

func configure(new_type: int, texture: Texture2D, new_grid_pos: Vector2i) -> void:
    super.configure(new_type, texture, new_grid_pos)
    _apply_visual_size(texture)
    queue_redraw()

func set_special(kind: int, texture: Texture2D) -> void:
    super.set_special(kind, texture)
    _apply_visual_size(texture)
    queue_redraw()

func _apply_visual_size(texture: Texture2D) -> void:
    if texture == null:
        return
    var longest: float = maxf(float(texture.get_width()), float(texture.get_height()))
    var factor: float = VISUAL_SIZE_027 / longest if longest > 0.0 else 1.0
    sprite.scale = Vector2(factor, factor)

func _draw() -> void:
    if sprite == null or sprite.texture == null:
        var c: Color = FALLBACK_COLORS[tile_type % FALLBACK_COLORS.size()]
        c.a = 0.55
        draw_rect(Rect2(-44, -44, 88, 88), c, true)

    if selected_state:
        draw_rect(Rect2(-46, -46, 92, 92), Color("8df0d5"), false, 4.0)
        draw_circle(Vector2.ZERO, 49.0, Color(0.55, 0.95, 0.84, 0.18), false, 3.0)
    else:
        draw_rect(Rect2(-45, -45, 90, 90), Color(1, 1, 1, 0.12), false, 1.5)

    if special_kind == 1:
        draw_circle(Vector2.ZERO, 48.0, Color(0.55, 0.95, 0.84, 0.34), false, 3.0)
    elif special_kind == 2:
        draw_circle(Vector2.ZERO, 49.0, Color(1.0, 0.85, 0.24, 0.44), false, 4.0)
    elif special_kind == 3:
        draw_circle(Vector2.ZERO, 50.0, Color(0.30, 1.0, 0.68, 0.52), false, 5.0)
        draw_circle(Vector2.ZERO, 44.0, Color(1.0, 1.0, 1.0, 0.28), false, 2.0)
