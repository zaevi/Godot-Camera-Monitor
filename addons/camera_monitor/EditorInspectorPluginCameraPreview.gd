tool
extends EditorInspectorPlugin

const CameraPreview = preload("CameraPreview.gd")


func can_handle(object):
    return object is Camera


func parse_begin(camera):
    var preview = CameraPreview.new()
    preview.attach(camera, true)
    add_custom_control(preview)
