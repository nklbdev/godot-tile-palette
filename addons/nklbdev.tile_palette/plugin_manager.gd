tool
extends EditorPlugin

#TileMapEditor structure:
#@@11844:[TileMapEditor:17202] name: @@11844, text: 
#  @@11814:[HBoxContainer:17209] name: @@11814, text: 
#    @@11839:[ToolButton:17246] name: @@11839, text: 
#    @@11840:[ToolButton:17249] name: @@11840, text: 
#    @@11841:[ToolButton:17252] name: @@11841, text: 
#    @@11842:[ToolButton:17255] name: @@11842, text: 
#    @@11843:[ToolButton:17258] name: @@11843, text: 
#  @@11815:[CheckBox:17210] name: @@11815, text: Disable Autotile
#  @@11816:[CheckBox:17211] name: @@11816, text: Enable Priority
#  @@11820:[LineEdit:17212] name: @@11820, text: 
#    @@11817:[Timer:17213] name: @@11817, text: 
#    @@11819:[PopupMenu:17214] name: @@11819, text: 
#      @@11818:[Timer:17215] name: @@11818, text: 
#  @@11821:[HSlider:17216] name: @@11821, text: 
#  @@11822:[VSplitContainer:17217] name: @@11822, text: 
#    @@11824:[ItemList:17218] name: @@11824, text: 
#      @@11823:[VScrollBar:17219] name: @@11823, text: 
#      @@11825:[Label:17220] name: @@11825, text: Give a TileSet resource to this TileMap to use its tiles.
#    @@11827:[ItemList:17221] name: @@11827, text: 
#      @@11826:[VScrollBar:17222] name: @@11826, text: 

var _selection: EditorSelection
var _tile_palette: Control
var _is_tile_palette_in_dock: bool = false
var _tilemap_editor: Control

var _first_adding: bool = true
var _checkboxes_parent: Control
var _disable_autotile_check_box: CheckBox
var _disable_autotile_check_box_position: int
var _enable_priority_check_box: CheckBox
var _enable_priority_check_box_position: int

var _tools_parent: Control
var _rotate_left_button: ToolButton
var _rotate_left_button_position: int
var _rotate_right_button: ToolButton
var _rotate_right_button_position: int
var _flip_horizontally_button: ToolButton
var _flip_horizontally_button_position: int
var _flip_vertically_button: ToolButton
var _flip_vertically_button_position: int
var _clear_transform_button: ToolButton
var _clear_transform_button_position: int

func _enter_tree():
	_tile_palette = load("res://addons/nklbdev.tile_palette/tile_palette.tscn").instance()
	_selection = get_editor_interface().get_selection()
	_selection.connect("selection_changed", self, "_on_selection_changed")
	_on_selection_changed()

func _exit_tree():
	_remove_tile_palette()
	if not _first_adding:
		_disable_autotile_check_box.get_parent().remove_child(_disable_autotile_check_box)
		_checkboxes_parent.add_child(_disable_autotile_check_box)
		_checkboxes_parent.move_child(_disable_autotile_check_box, _disable_autotile_check_box_position)
		_enable_priority_check_box.get_parent().remove_child(_enable_priority_check_box)
		_checkboxes_parent.add_child(_enable_priority_check_box)
		_checkboxes_parent.move_child(_enable_priority_check_box, _enable_priority_check_box_position)
		
		_rotate_left_button.get_parent().remove_child(_rotate_left_button)
		_tools_parent.add_child(_rotate_left_button)
		_tools_parent.move_child(_rotate_left_button, _rotate_left_button_position)
		_rotate_right_button.get_parent().remove_child(_rotate_right_button)
		_tools_parent.add_child(_rotate_right_button)
		_tools_parent.move_child(_rotate_right_button, _rotate_right_button_position)
		_flip_horizontally_button.get_parent().remove_child(_flip_horizontally_button)
		_tools_parent.add_child(_flip_horizontally_button)
		_tools_parent.move_child(_flip_horizontally_button, _flip_horizontally_button_position)
		_flip_vertically_button.get_parent().remove_child(_flip_vertically_button)
		_tools_parent.add_child(_flip_vertically_button)
		_tools_parent.move_child(_flip_vertically_button, _flip_vertically_button_position)
		_clear_transform_button.get_parent().remove_child(_clear_transform_button)
		_tools_parent.add_child(_clear_transform_button)
		_tools_parent.move_child(_clear_transform_button, _clear_transform_button_position)

	if _tile_palette:
		_tile_palette.queue_free()
	if _selection:
		_selection.disconnect("selection_changed", self, "_on_selection_changed")
		var selected_nodes = _selection.get_selected_nodes()
		if _tilemap_editor:
			_tilemap_editor.disconnect("visibility_changed", self, "_on_tilemap_editor_visibility_changed")
			if selected_nodes.size() == 1:
				var selected_node = selected_nodes[0]
				if selected_node is TileMap:
					_tilemap_editor.visible = true

func _on_selection_changed():
	_remove_tile_palette()
	var selected_nodes = _selection.get_selected_nodes()
	if selected_nodes.size() == 1:
		var selected_node = selected_nodes[0]
		if selected_node is TileMap:
			_add_tile_palette(selected_node)

func _print_tree(node: Node, indent = 0):
	var prefix = ""
	for i in range(indent):
		prefix += "  "
	print("%s%s name: %s, text: %s" % [prefix, node, node.name, node.text if "text" in node else ""])
	for child in node.get_children():
		_print_tree(child, indent + 1)



func _add_tile_palette(tilemap: TileMap):
	if _is_tile_palette_in_dock:
		return
	add_control_to_bottom_panel(_tile_palette, "Tile Palette")
	make_bottom_panel_item_visible(_tile_palette)
	_is_tile_palette_in_dock = true
	
	_tilemap_editor = _find_tilemap_editor(get_tree().root)
#	_print_tree(_tilemap_editor)
#	var items = _tilemap_editor.get_node("@@11822/@@11824") as ItemList
	var items = _tilemap_editor.get_child(5).get_child(0) as ItemList
#	var atlas_tile_items = _tilemap_editor.get_node("@@11822/@@11827") as ItemList
	var atlas_tile_items = _tilemap_editor.get_child(5).get_child(1) as ItemList
	
	_tile_palette.set_lists(items, atlas_tile_items)

	if _first_adding:
		_tilemap_editor.visible = false
		_tilemap_editor.connect("visibility_changed", self, "_on_tilemap_editor_visibility_changed")
		_checkboxes_parent = _tilemap_editor
#		_disable_autotile_check_box = _tilemap_editor.get_node("@@11815") as CheckBox
		_disable_autotile_check_box = _tilemap_editor.get_child(1) as CheckBox
		_disable_autotile_check_box_position = 1 # _disable_autotile_check_box.get_position_in_parent()
#		_enable_priority_check_box = _tilemap_editor.get_node("@@11816") as CheckBox
		_enable_priority_check_box = _tilemap_editor.get_child(2) as CheckBox
		_enable_priority_check_box_position = 2 # _enable_priority_check_box.get_position_in_parent()
		
#		_tools_parent = _tilemap_editor.get_node("@@11814") as HBoxContainer
		_tools_parent = _tilemap_editor.get_child(0) as HBoxContainer

#		_rotate_left_button = _tilemap_editor.get_node("@@11814/@@11839") as ToolButton
		_rotate_left_button = _tools_parent.get_child(0) as ToolButton
		_rotate_left_button_position = 0 # _rotate_left_button.get_position_in_parent()

#		_rotate_right_button = _tilemap_editor.get_node("@@11814/@@11840") as ToolButton
		_rotate_right_button = _tools_parent.get_child(1) as ToolButton
		_rotate_right_button_position = 1 # _rotate_right_button.get_position_in_parent()

#		_flip_horizontally_button = _tilemap_editor.get_node("@@11814/@@11841") as ToolButton
		_flip_horizontally_button = _tools_parent.get_child(2) as ToolButton
		_flip_horizontally_button_position = 2 # _flip_horizontally_button.get_position_in_parent()

#		_flip_vertically_button = _tilemap_editor.get_node("@@11814/@@11842") as ToolButton
		_flip_vertically_button = _tools_parent.get_child(3) as ToolButton
		_flip_vertically_button_position = 3 # _flip_vertically_button.get_position_in_parent()

#		_clear_transform_button = _tilemap_editor.get_node("@@11814/@@11843") as ToolButton
		_clear_transform_button = _tools_parent.get_child(4) as ToolButton
		_clear_transform_button_position = 4 # _clear_transform_button.get_position_in_parent()

		_tile_palette.set_tools(
			_tilemap_editor,
			_disable_autotile_check_box,
			_enable_priority_check_box,
			_rotate_left_button,
			_rotate_right_button,
			_flip_horizontally_button,
			_flip_vertically_button,
			_clear_transform_button)

	_tile_palette.tilemap = tilemap
	_first_adding = false

func _on_tilemap_editor_visibility_changed():
	if _tilemap_editor.visible:
		_tilemap_editor.visible = false

func _find_tilemap_editor(node: Node) -> Node:
	if node.get_class() == "TileMapEditor":
		return node
	for child in node.get_children():
		var tilemap_editor = _find_tilemap_editor(child)
		if tilemap_editor:
			return tilemap_editor
	return null

func _remove_tile_palette():
	if _is_tile_palette_in_dock:
		remove_control_from_bottom_panel(_tile_palette)
		_tile_palette.tilemap = null
		_is_tile_palette_in_dock = false
