tool
extends Control

var vc : ViewportContainer
var viewport : Viewport
var btn : Button

var advanced : bool
var editor : Control

var source : Camera

var follow : bool
var attached_camera : Camera
var attached_rid : RID


func _init(editor_interface : EditorInterface = null):
    self.advanced = editor_interface != null
    
    set_anchors_and_margins_preset(Control.PRESET_WIDE)
    rect_min_size = Vector2(0, 256)
    set_process(false)
    
    vc = ViewportContainer.new()
    vc.stretch = true
    vc.set_anchors_and_margins_preset(Control.PRESET_WIDE)
    add_child(vc)
    
    viewport = Viewport.new()
    # viewport.msaa = Viewport.MSAA_16X
    viewport.shadow_atlas_size = 2048
    viewport.shadow_atlas_quad_0 = Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_1
    viewport.handle_input_locally = false
    viewport.gui_disable_input = true
    vc.add_child(viewport)
  
    if advanced:
        self.editor = editor_interface.get_base_control()
        var stylebox = editor.get_stylebox("Information3dViewport","EditorStyles")
        btn = Button.new()
        btn.flat = false
        btn.add_stylebox_override("normal", stylebox)
        btn.add_stylebox_override("hover", stylebox)
        btn.add_stylebox_override("pressed", stylebox)
        btn.add_stylebox_override("focus", stylebox)
        btn.add_stylebox_override("disabled", stylebox)
        
        btn.rect_position = Vector2(10, 10)
        add_child(btn)


func set_text_icon(text : String, icon : Texture):
    if not btn:
        return
    btn.icon = icon
    btn.text = text


func detach():
    source = null
    if attached_camera:
        attached_camera.queue_free()
        attached_camera = null
    if attached_rid:
        VisualServer.viewport_attach_camera(viewport.get_viewport_rid(), RID())
        attached_rid = RID()


func attach(camera : Camera, follow : bool):
    detach()
    self.follow = follow
    self.source = camera
    if follow: 
        attached_rid = camera.get_camera_rid()
        VisualServer.viewport_attach_camera(viewport.get_viewport_rid(), attached_rid)
    else:
        # attached_camera = camera.duplicate()
        attached_camera = _duplicate_camera(camera)
        viewport.add_child(attached_camera)


func _duplicate_camera(from : Camera) -> Camera:
    var camera = Camera.new()
    camera.keep_aspect = from.keep_aspect
    # camera.cull_mask = from.cull_mask
    camera.h_offset = from.h_offset
    camera.v_offset = from.v_offset
    camera.projection = from.projection
    camera.fov = from.fov
    camera.size = from.size
    camera.frustum_offset = from.frustum_offset
    camera.near = from.near
    camera.far = from.far
    camera.global_transform = from.global_transform
    return camera


func get_state():
    return {
        source = source,
        follow = follow,
        camera = null if follow else _duplicate_camera(attached_camera)
    }