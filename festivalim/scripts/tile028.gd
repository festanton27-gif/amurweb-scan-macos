extends "res://scripts/tile027.gd"

func _draw() -> void:
    super._draw()

    if special_kind <= 0:
        return

    var frame_color := Color("63f0ff")
    var glow_color := Color(0.39, 0.94, 1.0, 0.20)

    if special_kind == 2:
        frame_color = Color("ffd83d")
        glow_color = Color(1.0, 0.85, 0.24, 0.22)
    elif special_kind == 3:
        frame_color = Color("8df0d5")
        glow_color = Color(0.35, 1.0, 0.72, 0.25)

    draw_rect(Rect2(-46, -46, 92, 92), glow_color, true)
    draw_rect(Rect2(-46, -46, 92, 92), frame_color, false, 5.0)
    draw_rect(Rect2(-41, -41, 82, 82), Color(1, 1, 1, 0.72), false, 2.0)

    var marker := 7.0
    draw_circle(Vector2(-38, -38), marker, frame_color, true)
    draw_circle(Vector2(38, -38), marker, frame_color, true)
    draw_circle(Vector2(-38, 38), marker, frame_color, true)
    draw_circle(Vector2(38, 38), marker, frame_color, true)
