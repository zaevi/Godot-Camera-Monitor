tool
extends Control

const CameraPreview = preload("CameraPreview.gd")

var editor_interface : EditorInterface
var spatial_editor_cameras = []

var btn_add_camera : Button
var preview_box : BoxContainer

var added_cameras = {}
var previews = []

var current_scene_id : int
var selected_camera : Camera

var scenes_state = {} # scene-objid: int -> state: []


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
    plugin.connect("scene_closed", self, "_scene_closed")
    
    editor_interface = plugin.get_editor_interface()
    var theme : Control = editor_interface.get_base_control()
    
    name = "Camera"

    var box = VBoxContainer.new()
    box.set_anchors_and_margins_preset(PRESET_WIDE)
    box.rect_clip_content = true
    self.add_child(box)

    var btns_box = HBoxContainer.new()
    box.add_child(btns_box)
    
    self.btn_add_camera = Button.new()
    btn_add_camera.icon = theme.get_icon("Camera", "EditorIcons")
    btn_add_camera.hint_tooltip = "Add Camera"
    btn_add_camera.connect("pressed",self,"_add_camera_pressed")
    btns_box.add_child(btn_add_camera)
    
    var btn_add_view = Button.new()
    btn_add_view.icon = theme.get_icon("Viewport", "EditorIcons")
    btn_add_view.hint_tooltip = "Add View"
    btn_add_view.connect("pressed", self, "_add_view_pressed")
    btns_box.add_child(btn_add_view)
    
    btns_box.add_spacer(false)

    var btn_clear = Button.new()
    # btn_clear.size_flags_horizontal = SIZE_EXPAND | SIZE_SHRINK_END
    btn_clear.icon = theme.get_icon("Clear", "EditorIcons")
    btn_clear.hint_tooltip = "Clear"
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

    self.connect("resized", self, "_resize_button", [[btn_add_camera, btn_add_view, btn_clear]])

    var selected_nodes = editor_interface.get_selection().get_selected_nodes()
    if len(selected_nodes) == 1 and selected_nodes[0] is Camera:
        edit(selected_nodes[0])
    else:
        edit(null)


func _resize_button(btns):
    var expand = rect_size.x > 290
    for btn in btns:
        btn.text = btn.hint_tooltip if expand else ""


func attach(camera : Camera, follow : bool) -> CameraPreview:
    _ensure_current_scene()
    if follow and added_cameras.has(camera):
        return null
    var preview = add_preview()
    if follow:
        preview.attach(camera, true)
        preview.set_text_icon(camera.name, get_icon(camera.get_class(), "EditorIcons"))
        added_cameras[camera] = preview
        camera.connect("tree_entered", self, "_camera_entered_tree", [camera])
        camera.connect("tree_exited", self, "_camera_exited_tree", [camera])
    else:
        preview.attach(camera, false)
        preview.set_text_icon("View", get_icon("Viewport", "EditorIcons"))
    
    return preview


func detach(preview : CameraPreview):
    if preview.follow:
        preview.source.disconnect("tree_entered", self, "_camera_entered_tree")
        preview.source.disconnect("tree_exited", self, "_camera_exited_tree")
        added_cameras.erase(preview.source)
    previews.erase(preview)
    preview.queue_free()


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
    for preview in previews.duplicate():
        detach(preview)
    assert(len(previews)==0)
    added_cameras.clear()


func edit(camera : Camera):
    selected_camera = camera
    btn_add_camera.disabled = not camera is Camera


var _camera_really_exited : bool
func _camera_exited_tree(camera : Camera):
    if not camera.owner and added_cameras.has(camera):
        _camera_really_exited = true
        call_deferred("_camera_exited_tree_handle", added_cameras[camera])
    else:
        pass # scene changed / root type changed / non-scene camera


func _camera_exited_tree_handle(preview : CameraPreview):
    if _camera_really_exited:
        detach(preview) # removed
    else:
        pass # moved / parent type changed


func _camera_entered_tree(camera : Camera):
    _camera_really_exited = false


func _ensure_current_scene():
    var scene = editor_interface.get_edited_scene_root()
    if scene:
        current_scene_id = scene.get_instance_id()
    else:
        current_scene_id = 0


var _just_closed : bool
func _scene_closed(filepath : String):
    _just_closed = true
    set_deferred("_just_closed", false)
    call_deferred("_try_clear_scene_state")


func _scene_changed(scene : Node):
    if current_scene_id != 0 and not _just_closed and len(previews) > 0:
        var states = []
        for preview in previews:
            states.append(preview.get_state())
        scenes_state[current_scene_id] = states
    
    _clear_pressed()

    _ensure_current_scene() # now it's new scene's id
    if current_scene_id != 0: 
        var states = scenes_state.get(current_scene_id)
        if states:
            scenes_state.erase(current_scene_id)
            for state in states:
                if state.follow:
                    attach(state.source, true)
                else:
                    add_child(state.camera)
                    var preview = attach(state.camera, false)
                    preview.source = state.source
                    remove_child(state.camera)


func _try_clear_scene_state():
    for id in scenes_state.keys():
        if not instance_from_id(id):
            scenes_state.erase(id)