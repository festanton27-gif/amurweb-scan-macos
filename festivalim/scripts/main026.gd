extends "res://scripts/main025.gd"

const TILES_026: Texture2D = preload("res://assets/tiles_026.jpg")
const SPLASH_026: Texture2D = preload("res://assets/splash_026.jpg")
const ICON_026: Texture2D = preload("res://assets/icon_026.png")
const VERSION_026 := "DEV 0.2.6"
const CELL_026 := 96.0

func _ready() -> void:
    super._ready()
    await _show_startup_splash()

func _build_textures() -> void:
    textures.clear()
    for i in range(6):
        var atlas := AtlasTexture.new()
        atlas.atlas = TILES_026
        atlas.region = Rect2(
            float(i % 3) * CELL_026,
            float(int(i / 3)) * CELL_026,
            CELL_026,
            CELL_026
        )
        textures.append(atlas)

    special_textures.clear()
    for i in [6, 7]:
        var atlas := AtlasTexture.new()
        atlas.atlas = TILES_026
        atlas.region = Rect2(
            float(i % 3) * CELL_026,
            float(int(i / 3)) * CELL_026,
            CELL_026,
            CELL_026
        )
        special_textures.append(atlas)

func _show_startup_splash() -> void:
    var layer := CanvasLayer.new()
    layer.layer = 100
    add_child(layer)

    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_STOP
    layer.add_child(root)

    var bg := ColorRect.new()
    bg.color = Color("eafbf5")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(bg)

    var pic := TextureRect.new()
    pic.texture = SPLASH_026
    pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(pic)

    await get_tree().create_timer(1.15).timeout
    var tween := create_tween()
    tween.tween_property(root, "modulate:a", 0.0, 0.18)
    await tween.finished
    layer.queue_free()

func _show_menu() -> void:
    super._show_menu()

    # Replace the old menu icon with the user-provided Festivalim icon.
    for root_child in hud_layer.get_children():
        if root_child is Control:
            for child in root_child.get_children():
                if child is TextureRect:
                    child.texture = ICON_026
                    break

    var patch := ColorRect.new()
    patch.position = Vector2(0, 1148)
    patch.size = Vector2(720, 52)
    patch.color = Color("071c1c")
    patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud_layer.add_child(patch)
    _label(hud_layer, VERSION_026, Vector2(0, 1162), Vector2(720, 28), 13, Color(1, 1, 1, 0.48))

func _build_game_hud() -> void:
    super._build_game_hud()

    var patch := ColorRect.new()
    patch.position = Vector2(0, 1008)
    patch.size = Vector2(720, 48)
    patch.color = Color("071719")
    patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud_layer.add_child(patch)
    _label(hud_layer, VERSION_026, Vector2(0, 1018), Vector2(720, 26), 12, Color(1, 1, 1, 0.40))
