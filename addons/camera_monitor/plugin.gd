tool
extends EditorPlugin

const InspectorCameraPreview = preload("EditorInspectorPluginCameraPreview.gd")
const CameraMonitor = preload("CameraMonitor.gd")

var inspector_plugin : InspectorCameraPreview
var camera_monitor : CameraMonitor

func _enter_tree():
    inspector_plugin = InspectorCameraPreview.new()
    add_inspector_plugin(inspector_plugin)
    camera_monitor = CameraMonitor.new(self)
    add_control_to_dock(DOCK_SLOT_RIGHT_UL, camera_monitor)


func handles(object):
    return true

var _last_edit = null
func edit(object):
    if object == _last_edit:
        return
    elif object is Camera:
        camera_monitor.edit(object)
    else:
        camera_monitor.edit(null)


func _exit_tree():
    if inspector_plugin:
        remove_inspector_plugin(inspector_plugin)
        inspector_plugin = null
    if camera_monitor:
        remove_control_from_docks(camera_monitor)
        camera_monitor.queue_free()
        camera_monitor = null
