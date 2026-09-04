extends Node2D

var tile_type: int = 0
var grid_pos := Vector2i.ZERO
var sprite: Sprite2D

func _init() -> void:
    sprite = Sprite2D.new()
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    sprite.scale = Vector2(3.00, 3.00)
    add_child(sprite)

func configure(new_type: int, texture: Texture2D, new_grid_pos: Vector2i) -> void:
    tile_type = new_type
    grid_pos = new_grid_pos
    sprite.texture = texture
    scale = Vector2.ONE
    modulate = Color.WHITE

func move_to(target: Vector2, duration: float = 0.11) -> Tween:
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_QUAD)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "position", target, duration)
    return tween

func pop(duration: float = 0.10) -> void:
    var tween := create_tween().set_parallel(true)
    tween.tween_property(self, "scale", Vector2(0.08, 0.08), duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
    tween.tween_property(self, "modulate:a", 0.0, duration)

func set_selected(value: bool) -> void:
    var tween := create_tween()
    tween.tween_property(self, "scale", Vector2(1.08, 1.08) if value else Vector2.ONE, 0.07)

func hint_pulse() -> void:
    var tween := create_tween()
    tween.set_loops(2)
    tween.tween_property(self, "scale", Vector2(1.10, 1.10), 0.12)
    tween.tween_property(self, "scale", Vector2.ONE, 0.12)
