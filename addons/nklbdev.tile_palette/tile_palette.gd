tool
extends Control

export var single_tile_border_color: Color = Color("fce844")
export var atlas_tile_border_color: Color = Color("c9cfd4")
export var atlas_subtile_border_color: Color = Color("4cb299")
export var auto_tile_border_color: Color = Color("4490fc")
export var auto_subtile_border_color: Color = Color("4cb299")
export var absent_tile_border_color: Color = Color(1, 0, 0)
export var absent_tile_fill_color: Color = Color(1, 0, 0.5)
export var tile_selection_color: Color = Color(0, 0, 1, 0.7)
export var tile_hint_label_font_color: Color = Color(0, 0, 0)
var _tile_list: ItemList
var _subtile_list: ItemList
var _disable_autotile_check_box: CheckBox
var _enable_priority_check_box: CheckBox
var _rotate_left_button: ToolButton
var _rotate_right_button: ToolButton
var _flip_horizontally_button: ToolButton
var _flip_vertically_button: ToolButton
var _clear_transform_button: ToolButton
onready var _texture_item_list: ItemList = $HSplitContainer/TextureListVBoxContainer/TextureItemList
onready var _sprite = $HSplitContainer/TextureVBoxContainer/Panel/ScalingHelper/Sprite
onready var _sprite_border = $HSplitContainer/TextureVBoxContainer/Panel/ScalingHelper/Sprite/SpriteBorder
onready var _scaling_helper = $HSplitContainer/TextureVBoxContainer/Panel/ScalingHelper
onready var _selection_rect: ColorRect = $HSplitContainer/TextureVBoxContainer/Panel/ScalingHelper/Sprite/SelectionRect
onready var _tools_container: HBoxContainer = $HSplitContainer/TextureVBoxContainer/HBoxContainer/ToolsHBoxContainer
onready var _panel: Panel = $HSplitContainer/TextureVBoxContainer/Panel
onready var _texture_list_scaler: HSlider = $HSplitContainer/TextureListVBoxContainer/ScaleHSlider
onready var _texture_scaler: HSlider = $HSplitContainer/TextureVBoxContainer/HBoxContainer/ScalingHBoxContainer/ScaleHSlider
onready var _transform_indicator: ToolButton = $HSplitContainer/TextureVBoxContainer/HBoxContainer/ToolsHBoxContainer/TransformationIndicatorPlaceholderMarginContainer/TransformationIndicatorPlaceholderToolButton
onready var _reset_scaling_button: ToolButton = $HSplitContainer/TextureVBoxContainer/HBoxContainer/ScalingHBoxContainer/ResetScalingToolButton
onready var _show_tile_hints_check_box: CheckBox = $HSplitContainer/TextureVBoxContainer/HBoxContainer/ScalingHBoxContainer/ShowTileHintsCheckBox
var _dragging: bool = false
var _editor_item_indices_by_tile_ids = {}
var _previous_selected_texture_index: int = -1
var _mouse_entered = false
var _last_selected_tile = -1
var _last_selected_subtile = -1
var _tile_map_editor: Control

var _tileset: TileSet
var tilemap: TileMap setget _set_tilemap
func _set_tilemap(value):
	tilemap = value
	if tilemap:
		_clear()
		_fill()
	else:
		_clear()

func set_lists(tile_list: ItemList, subtile_list: ItemList):
	_tile_list = tile_list
	_subtile_list = subtile_list

func set_tools(
	tile_map_editor: Control,
	disable_autotile_check_box: CheckBox,
	enable_priority_check_box: CheckBox,
	rotate_left_button: ToolButton,
	rotate_right_button: ToolButton,
	flip_horizontally_button: ToolButton,
	flip_vertically_button: ToolButton,
	clear_transform_button: ToolButton,
	interface_display_scale: float = 1):
	
	_tile_map_editor = tile_map_editor
	
	_disable_autotile_check_box = disable_autotile_check_box
	_enable_priority_check_box = enable_priority_check_box
	_rotate_left_button = rotate_left_button
	_rotate_right_button = rotate_right_button
	_flip_horizontally_button = flip_horizontally_button
	_flip_vertically_button = flip_vertically_button
	_clear_transform_button = clear_transform_button
	
	var tools = [
		_rotate_left_button,
		_rotate_right_button,
		_flip_horizontally_button,
		_flip_vertically_button,
		_clear_transform_button,
		_disable_autotile_check_box,
		_enable_priority_check_box
	]
	for t in tools:
		t.get_parent().remove_child(t)
		_tools_container.add_child(t)
	
	_disable_autotile_check_box.connect("toggled", self, "_on_disable_autotile_check_box_toggled")
	_enable_priority_check_box.connect("toggled", self, "_on_enable_priority_check_box_toggled")
	
	_on_clear_transform()
	_tile_map_editor._clear_transform()
	
	_rotate_left_button.connect("pressed", self, "_on_rotate_counterclockwise")
	_rotate_right_button.connect("pressed", self, "_on_rotate_clockwise")
	_flip_horizontally_button.connect("pressed", self, "_on_flip_horizontally")
	_flip_vertically_button.connect("pressed", self, "_on_flip_vertically")
	_clear_transform_button.connect("pressed", self, "_on_clear_transform")
	
	_reset_scaling_button.icon = _resize_button_texture(_reset_scaling_button.icon, interface_display_scale / 4)
	_transform_indicator.icon = _resize_button_texture(_transform_indicator.icon, interface_display_scale / 4)

func _resize_button_texture(texture: Texture, scale: float):
	var image = texture.get_data() as Image
	var new_size = image.get_size() * scale
	image.resize(round(new_size.x), round(new_size.y))
	var new_texture = ImageTexture.new()
	new_texture.create_from_image(image)
	return new_texture

func _on_rotate_counterclockwise():
	_transform_indicator.rect_pivot_offset = _transform_indicator.rect_size / 2
	_transform_indicator.rect_rotation -= 90
	if _transform_indicator.rect_rotation < 0:
		_transform_indicator.rect_rotation += 360

func _on_rotate_clockwise():
	_transform_indicator.rect_pivot_offset = _transform_indicator.rect_size / 2
	_transform_indicator.rect_rotation += 90
	if _transform_indicator.rect_rotation >= 360:
		_transform_indicator.rect_rotation -= 360

func _on_flip_horizontally():
	_transform_indicator.rect_pivot_offset = _transform_indicator.rect_size / 2
	if _transform_indicator.rect_rotation == 0 or _transform_indicator.rect_rotation == 180:
		_transform_indicator.rect_scale.x *= -1
	else:
		_transform_indicator.rect_scale.y *= -1

func _on_flip_vertically():
	_transform_indicator.rect_pivot_offset = _transform_indicator.rect_size / 2
	if _transform_indicator.rect_rotation == 0 or _transform_indicator.rect_rotation == 180:
		_transform_indicator.rect_scale.y *= -1
	else:
		_transform_indicator.rect_scale.x *= -1

func _on_clear_transform():
	_transform_indicator.rect_pivot_offset = _transform_indicator.rect_size / 2
	_transform_indicator.rect_rotation = 0
	_transform_indicator.rect_scale = Vector2.ONE

func _on_disable_autotile_check_box_toggled(pressed: bool):
	var selected_items = _texture_item_list.get_selected_items()
	if selected_items.size() > 0:
		_on_TextureItemList_item_selected(selected_items[0])

func _on_enable_priority_check_box_toggled(pressed: bool):
	var selected_items = _texture_item_list.get_selected_items()
	if selected_items.size() > 0:
		_on_TextureItemList_item_selected(selected_items[0])

func _update_buttons_mouse_filter():
	if _panel:
		var rect = _panel.get_global_rect()
		var mouse_position = _panel.get_global_mouse_position()
		if rect.has_point(mouse_position):
			_on_mouse_entered()
		else:
			_on_mouse_exited()

func _ready():
	_update_buttons_mouse_filter()
	_texture_list_scaler.value = 0.5
	_texture_scaler.value = 1

func _fill():
	if tilemap.tile_set:
		_tileset = tilemap.tile_set
		_previous_selected_texture_index = -1
		var textures = []
		_texture_item_list.clear()
		var texture_index = 0
		var tile_index = 0
		for tile_id in _tileset.get_tiles_ids():
			var tile_texture = _tileset.tile_get_texture(tile_id)
			if tile_texture:
				if tile_texture in textures:
					var ti = textures.find(tile_texture)
					var meta = _texture_item_list.get_item_metadata(ti)
					meta.tiles.append({"index": tile_index, "id": tile_id})
				else:
					textures.append(tile_texture)
					var text = tile_texture.resource_path.get_file() if tile_texture.resource_path else ""
					_texture_item_list.add_item(text, tile_texture)
					_texture_item_list.set_item_metadata(texture_index, {"texture": tile_texture, "tiles": [{"index": tile_index, "id": tile_id}]})
					texture_index += 1
			tile_index += 1
		
		for child in _sprite_border.get_children():
			_sprite_border.remove_child(child)
			child.queue_free()
		if not _tileset.is_connected("changed", self, "_on_tileset_changed"):
			_tileset.connect("changed", self, "_on_tileset_changed")
	if _texture_item_list.get_item_count() >= 0:
		_texture_item_list.select(0)
		_on_TextureItemList_item_selected(0)
		for child in _sprite_border.get_children():
			if child is ReferenceRect:
				_on_pressed_tile_button(child)
				break

func _clear():
	_previous_selected_texture_index = -1
	_texture_item_list.clear()
	_sprite.texture = null
	_sprite_border.rect_size = Vector2.ZERO
	for child in _sprite_border.get_children():
		_sprite_border.remove_child(child)
		child.queue_free()
	_selection_rect.rect_size = Vector2.ZERO
	_selection_rect.rect_position = Vector2.ZERO
	_tileset = null
	_last_selected_tile = -1
	_last_selected_subtile = -1
	for connection in get_incoming_connections():
		if connection.source is TileSet and connection.signal_name == "changed" and connection.method_name == "_on_tileset_changed":
			connection.source.disconnect("changed", self, "_on_tileset_changed")

func _refresh():
	_clear()
	_fill()

func _on_tileset_changed():
	_refresh()

func _create_tile_button(tile_id: int, tile_region: Rect2, subtile_index = -1, subtile_coord: Vector2 = Vector2.ZERO):
	var tile_button = ReferenceRect.new()
	_sprite_border.add_child(tile_button)
	tile_button.rect_size = tile_region.size
	tile_button.rect_position = tile_region.position
	if subtile_index == null:
		tile_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile_button.border_color = absent_tile_border_color
		var color_rect = ColorRect.new()
		color_rect.rect_size = tile_region.size
		color_rect.rect_position = tile_region.position
		color_rect.color = absent_tile_fill_color
	else:
		match _tileset.tile_get_tile_mode(tile_id):
			TileSet.SINGLE_TILE:
				tile_button.border_color = single_tile_border_color
			TileSet.AUTO_TILE:
				tile_button.border_color = auto_tile_border_color if subtile_index < 0 else auto_subtile_border_color
			TileSet.ATLAS_TILE:
				tile_button.border_color = atlas_tile_border_color if subtile_index < 0 else atlas_subtile_border_color
		tile_button.set_meta("tile_region", tile_region)
		tile_button.set_meta("tile_id", tile_id)
		tile_button.set_meta("subtile_index", subtile_index)
		tile_button.mouse_filter = Control.MOUSE_FILTER_PASS
		tile_button.connect("gui_input", self, "_on_ReferenceRect_gui_input", [tile_button])
		if _last_selected_tile == tile_id:
			if (_last_selected_subtile == subtile_index) or \
				(_last_selected_subtile == -1 and subtile_index == 0) or \
				(_last_selected_subtile >= 0 and subtile_index == -1):
				_selection_rect.rect_size = tile_button.rect_size
				_selection_rect.rect_position = tile_button.rect_position
				if subtile_index < 0:
					_last_selected_subtile = -1

func _create_single_tile_button(tile_id: int):
	_create_tile_button(tile_id, _tileset.tile_get_region(tile_id))

func _create_multiple_tile_button(tile_id: int, with_bitmask: bool = false):
	var tile_region = _tileset.tile_get_region(tile_id)
	var subtile_size = _tileset.autotile_get_size(tile_id)
	var subtile_spacing = _tileset.autotile_get_spacing(tile_id)
	var subtile_index = 0
	var x_coord = 0
	var y_coord = 0
	for y in range(0, tile_region.size.y, subtile_size.y + subtile_spacing):
		for x in range(0, tile_region.size.x, subtile_size.x + subtile_spacing):
			var subtile_coord = Vector2(x_coord, y_coord)
			x_coord += 1
			var subtile_position = Vector2(x, y)
			if with_bitmask:
				if _tileset.autotile_get_bitmask(tile_id, subtile_coord) <= 0:
					continue
			var subtile_region = Rect2(tile_region.position + subtile_position, subtile_size)
			_create_tile_button(tile_id, subtile_region, subtile_index, subtile_coord)
			subtile_index += 1
		y_coord += 1
		x_coord = 0

func _reset_scale(new_scale: float = 1):
	_sprite_border.rect_size = _sprite.texture.get_size() if _sprite.texture else Vector2.ZERO
	_scaling_helper.rect_position = Vector2.ZERO
	_scaling_helper.rect_scale = Vector2.ONE * new_scale
	_sprite.rect_position = Vector2.ZERO
	_texture_scaler.value = new_scale

func _create_tile_hint(tile_index: int, tile_id: int):
	var tile_region = _tileset.tile_get_region(tile_id)
	var tile_name = _tileset.tile_get_name(tile_id)
	var tile_hint_label = Label.new()
	tile_hint_label.add_color_override("font_color", tile_hint_label_font_color)
	tile_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tile_hint_label_bg = ColorRect.new()
	tile_hint_label_bg.mouse_filter = Control.MOUSE_FILTER_PASS
	tile_hint_label.add_child(tile_hint_label_bg)
	tile_hint_label_bg.show_behind_parent = true
	match _tileset.tile_get_tile_mode(tile_id):
		TileSet.SINGLE_TILE:
			tile_hint_label.text = "%s:%s SINGLE %s" % [tile_index, tile_id, tile_name]
			tile_hint_label_bg.color = single_tile_border_color
		TileSet.AUTO_TILE:
			tile_hint_label.text = "%s:%s AUTO %s" % [tile_index, tile_id, tile_name]
			tile_hint_label_bg.color = auto_tile_border_color
		TileSet.ATLAS_TILE:
			tile_hint_label.text = "%s:%s ATLAS %s" % [tile_index, tile_id, tile_name]
			tile_hint_label_bg.color = atlas_tile_border_color
	_sprite_border.add_child(tile_hint_label)
	tile_hint_label.rect_position = tile_region.position
	tile_hint_label_bg.rect_size = tile_hint_label.rect_size
	tile_hint_label.hint_tooltip = "{tile index}:{tile id} {MODE} {name}"

func _on_TextureItemList_item_selected(index):
	var meta = _texture_item_list.get_item_metadata(index)
	
	if _previous_selected_texture_index != index:
		_sprite.texture = meta.texture
		_reset_scale(_texture_scaler.value)
		_previous_selected_texture_index = index
	
	for child in _sprite_border.get_children():
		_sprite_border.remove_child(child)
		child.queue_free()
	_selection_rect.rect_position = Vector2.ZERO
	_selection_rect.rect_size = Vector2.ZERO
	for tile in meta.tiles:
		match _tileset.tile_get_tile_mode(tile.id):
			TileSet.SINGLE_TILE:
				_create_single_tile_button(tile.id)
			TileSet.ATLAS_TILE:
				_create_single_tile_button(tile.id) \
				if _enable_priority_check_box.pressed else \
				_create_multiple_tile_button(tile.id)
			TileSet.AUTO_TILE:
				_create_multiple_tile_button(tile.id, true) \
				if _disable_autotile_check_box.pressed else \
				_create_single_tile_button(tile.id)
		_create_tile_hint(tile.index, tile.id)
	_update_tile_hints()

func _on_pressed_tile_button(tile_button: ReferenceRect):
	var tile_id = tile_button.get_meta("tile_id")
	var tile_index = -1
	for tile_item_index in range(_tile_list.get_item_count()):
		if tile_id == _tile_list.get_item_metadata(tile_item_index):
			tile_index = tile_item_index
	if tile_index >= 0:
		_tile_list.select(tile_index)
		_tile_map_editor._palette_selected(tile_index)
		_last_selected_subtile = -1
		match _tileset.tile_get_tile_mode(tile_id):
			TileSet.SINGLE_TILE:
				_enable_priority_check_box.visible = false
				_disable_autotile_check_box.visible = false
			TileSet.ATLAS_TILE:
				if not _enable_priority_check_box.pressed:
					var subtile_index = tile_button.get_meta("subtile_index")
					_last_selected_subtile = subtile_index
					_subtile_list.select(subtile_index)
				_enable_priority_check_box.visible = true
				_disable_autotile_check_box.visible = false
			TileSet.AUTO_TILE:
				if _disable_autotile_check_box.pressed:
					var subtile_index = tile_button.get_meta("subtile_index")
					_last_selected_subtile = subtile_index
					_subtile_list.select(subtile_index)
				_enable_priority_check_box.visible = false
				_disable_autotile_check_box.visible = true
		_selection_rect.rect_position = tile_button.rect_position
		_selection_rect.rect_size = tile_button.rect_size
		_last_selected_tile = tile_id

func _on_ReferenceRect_gui_input(event: InputEvent, tile_button: ReferenceRect):
	var tile_id = tile_button.get_meta("tile_id")
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == BUTTON_LEFT:
			_on_pressed_tile_button(tile_button)

var _mouse_wrapped: bool = false
func _input(event: InputEvent):
	if _dragging:
		if event is InputEventMouseButton:
			if (not event.pressed) and event.button_index == BUTTON_MIDDLE:
				_dragging = false
		if event is InputEventMouseMotion:
			if _mouse_wrapped:
				_mouse_wrapped = false
			else:
				_scaling_helper.rect_position += event.relative
			var mouse_position = get_global_mouse_position()
			var new_mouse_position = mouse_position
			var rect = _panel.get_global_rect() as Rect2
			if new_mouse_position.x < rect.position.x:
				new_mouse_position.x = rect.end.x
			elif new_mouse_position.x > rect.end.x:
				new_mouse_position.x = rect.position.x
			if new_mouse_position.y < rect.position.y:
				new_mouse_position.y = rect.end.y
			elif new_mouse_position.y > rect.end.y:
				new_mouse_position.y = rect.position.y
			if new_mouse_position != mouse_position:
				_mouse_wrapped = true
				get_viewport().warp_mouse(new_mouse_position)

func _update_tile_hints():
	for child in _sprite_border.get_children():
		if child is Label:
			child.visible = _show_tile_hints_check_box.pressed
			child.rect_scale = Vector2.ONE / (_scaling_helper.rect_scale)

func _scale(factor: float):
	var sprite_global_position = _sprite.rect_global_position
	_scaling_helper.rect_global_position = get_global_mouse_position()
	_sprite.rect_global_position = sprite_global_position
	_scaling_helper.rect_scale *= factor
	_texture_scaler.value = _scaling_helper.rect_scale.x
	_update_tile_hints()

func _set_scale(value: float):
	var sprite_global_position = _sprite.rect_global_position
	_scaling_helper.rect_position = _panel.rect_size / 2
	_sprite.rect_global_position = sprite_global_position
	_scaling_helper.rect_scale = Vector2.ONE * value
	_update_tile_hints()

func _on_mouse_entered():
	if _mouse_entered:
		return
	_mouse_entered = true
	for button in _sprite_border.get_children():
		if button is ReferenceRect:
			button.mouse_filter = Control.MOUSE_FILTER_PASS

func _on_mouse_exited():
	if not _mouse_entered:
		return
	_mouse_entered = false
	for button in _sprite_border.get_children():
		if button is ReferenceRect:
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_Panel_gui_input(event):
	if event is InputEventMouse:
		_update_buttons_mouse_filter()
		if event is InputEventMouseButton:
			match event.button_index:
				BUTTON_MIDDLE:
					if event.pressed:
						_dragging = true
				BUTTON_WHEEL_UP:
					if event.pressed:
						_scale(1.5)
				BUTTON_WHEEL_DOWN:
					if event.pressed:
						_scale(1 / 1.5)

func _on_TextureListScaleHSlider_value_changed(value):
	_texture_item_list.icon_scale = value
	var _texture_item_list_rect_size = _texture_item_list.rect_size
	_texture_item_list.rect_size = Vector2.ZERO
	_texture_item_list.rect_size = _texture_item_list_rect_size

func _on_TextureScaleHSlider_value_changed(value):
	_set_scale(value)


func _on_ResetScalingToolButton_pressed():
	_reset_scale()


func _on_ShowTileHintsCheckBox_toggled(button_pressed):
	_update_tile_hints()
