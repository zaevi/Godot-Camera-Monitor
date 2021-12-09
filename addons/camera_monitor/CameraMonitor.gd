tool
extends Control

const CameraPreview = preload("CameraPreview.gd")

var editor_interface : EditorInterface
var spatial_editor_cameras = []

var btn_add_camera : Button
var preview_box : BoxContainer

var added_cameras = {}
var previews = []

var current_scene : Node
var selected_camera : Camera


func _init(plugin : EditorPlugin):
    # get 3d editor's cameras
    var _control = Control.new()
    plugin.add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_BOTTOM, _control)
    for sev in _control.get_parent().get_child(0).get_children():
        assert(sev.get_class()=="SpatialEditorViewport")
        var camera : Camera = sev.get_child(0).get_child(0).get_child(0)
        assert(camera is Camera)
        spatial_editor_cameras.append(camera)
    plugin.remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_BOTTOM, _control)
    _control.queue_free()
    
    plugin.connect("scene_changed", self, "_scene_changed")
    
    editor_interface = plugin.get_editor_interface()
    var theme : Control = editor_interface.get_base_control()
    
    var box = VBoxContainer.new()
    box.set_anchors_and_margins_preset(PRESET_WIDE)
    box.rect_clip_content = true
    self.add_child(box)

    var btns_box = HBoxContainer.new()
    box.add_child(btns_box)
    
    name = "Camera"
    
    self.btn_add_camera = Button.new()
    btn_add_camera.icon = theme.get_icon("Camera", "EditorIcons")
    btn_add_camera.text = "Add Camera"
    btn_add_camera.connect("pressed",self,"_add_camera_pressed")
    btns_box.add_child(btn_add_camera)
    
    var btn_add_view = Button.new()
    btn_add_view.icon = theme.get_icon("Viewport", "EditorIcons")
    btn_add_view.text = "Add View"
    btn_add_view.connect("pressed", self, "_add_view_pressed")
    btns_box.add_child(btn_add_view)
    
    var btn_clear = Button.new()
    btn_clear.size_flags_horizontal = SIZE_EXPAND | SIZE_SHRINK_END
    btn_clear.icon = theme.get_icon("Clear", "EditorIcons")
    btn_clear.text = "Clear"
    btn_clear.connect("pressed", self, "_clear_pressed")
    btns_box.add_child(btn_clear)
    
    var preview_scroll = ScrollContainer.new()
    preview_scroll.set_anchors_and_margins_preset(PRESET_WIDE)
    preview_scroll.size_flags_vertical = SIZE_EXPAND_FILL
    box.add_child(preview_scroll)
    
    self.preview_box = VBoxContainer.new()
    preview_box.set_anchors_and_margins_preset(PRESET_WIDE)
    preview_box.size_flags_horizontal = SIZE_EXPAND_FILL
    preview_box.size_flags_vertical = SIZE_EXPAND_FILL
    preview_box.add_constant_override("separation", 5)
    preview_scroll.add_child(preview_box)


func attach(camera : Camera, follow : bool):
    var preview = add_preview()
    if follow:
        if added_cameras.has(selected_camera):
            return
        preview.attach(camera, true)
        preview.set_text_icon(camera.name, get_icon(camera.get_class(), "EditorIcons"))
        added_cameras[camera] = preview
        camera.connect("tree_exited", self, "_camera_exited_tree", [camera])
    else:
        preview.attach(camera, false)
        preview.set_text_icon("View", get_icon("Viewport", "EditorIcons"))


func add_preview() -> CameraPreview:
    var preview = CameraPreview.new(editor_interface)
    preview_box.add_child(preview)
    previews.append(preview)
    return preview


func _add_camera_pressed():
    if not selected_camera:
        return
    attach(selected_camera, true)


func _add_view_pressed():
    assert(len(spatial_editor_cameras) > 0)
    var camera : Camera = spatial_editor_cameras[0]
    attach(camera, false)


func _clear_pressed():
    for preview in previews:
        preview.queue_free()
    previews.clear()
    added_cameras.clear()


func edit(camera : Camera):
    selected_camera = camera
    btn_add_camera.disabled = not camera is Camera


func _camera_exited_tree(camera : Camera):
    if not camera.owner:
        print_debug(camera, " removed") # or moved / or parent's type changed
    else:
        assert(not camera.owner.is_inside_tree())
        print_debug(camera, " scene changed")


func _scene_changed(scene : Node):
    # todo store state
    print_debug("scene changed to ", scene) 
    if scene:
        pass # todo restore state
