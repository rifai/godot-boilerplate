extends Node


@onready var scene = preload("res://scenes/stats.tscn")


var _content_label:Label
var _content = {}

var _dots = {}
var _dot_objects = []
var _master_dot:MeshInstance3D

var _lines = {}
var _line_objects = []
var _master_line:MeshInstance3D

const FRAME_COUNT_LIMIT = 5

const MAX_PRINT_LINE = 30
var _content_log:PackedStringArray = []

var _log_label:Label
var _log_timer:Timer


var _active_camera:Camera3D
var _text_objects = []
var _texts = {}

func _ready():

	var root = scene.instantiate()
	
	add_child(root)
	_content_label = root.get_node("Content")
	
	_master_dot = root.get_node("Dot")
	_master_dot.visible = false
	
	_master_line = root.get_node("Lines")
	_master_line.visible = false
	
	_log_label = root.get_node("PrintContent")
	
	
	_log_timer = Timer.new()
	add_child(_log_timer)
	_log_timer.timeout.connect(_delete_log)
	_log_timer.start(1)
#	_line_mesh = _lines.mesh
#
#	_line_mesh.clear_surfaces()
#	_line_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
#	_line_mesh.surface_add_vertex(Vector3.ZERO)
#	_line_mesh.surface_add_vertex(Vector3(1,1,1))
#	_line_mesh.surface_end()
	
func _delete_log():
	if !_content_log.is_empty():
		_content_log.remove_at(_content_log.size() - 1)

func clear_texts():
	_texts.clear()
	for dt in _text_objects:
		dt.visible = false
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var fps:float = 1 / delta
	_content_label.text = str(fps)+"\n"
	
	for key in _content.keys():
		_content_label.text += key+ " : " +_content[key]["message"]+"\n"
		
	_log_label.text = ""
	for key in _content_log:
		_log_label.text += key +"\n"
		
	# Remove text lines after some time
	for key in _content.keys():
		var t = _content[key]
		if t.frame <= Engine.get_frames_drawn():
			_content.erase(key)
	
	_draw_spheres()
	_draw_lines()
	_draw_texts()

func setup_camera(new_cam:Camera3D):
	_active_camera = new_cam
	
func add_text(key:String, message:String, position:Vector3):
	if !_camera_ok():
		return
			
		
	_texts[key] = {
		"position" : position,
		"message" : message,
		"frame" : Engine.get_frames_drawn() + FRAME_COUNT_LIMIT
	}

func set_stats(key:String, new_content:String, color:Color = Color.RED):
	_content[key] = {
		"message" : new_content,
		"color":color,
		"frame" : Engine.get_frames_drawn() + FRAME_COUNT_LIMIT
	}

func add_sphere(key:String, position:Vector3, color:Color = Color.YELLOW):

	_dots[key] = {
		"position" : position,
		"color" : color,
		"frame" : Engine.get_frames_drawn() + FRAME_COUNT_LIMIT
	}

func add_line(key:String, points:PackedVector3Array, color:Color = Color.BLUE):
	if points.size() <= 1:
		return
	_lines[key] = {
		"points" : points,
		"color" : color,
		"frame" : Engine.get_frames_drawn() + FRAME_COUNT_LIMIT
	}

func draw_direction(key:String, global_pos:Vector3, arah:Vector3, warna:Color, height:float = 1):
	var base_pos = global_pos + Vector3(0,height,0)
	set_stats(key, str(arah))

	var ar_nrm = arah.normalized()

	add_line("TAG"+key, [base_pos, base_pos + ar_nrm], warna)
	add_sphere("TAG"+key, base_pos + ar_nrm, warna)

func logd(content:String):
	_content_log.insert(0, content)
	if _content_log.size() > MAX_PRINT_LINE:
		_content_log = _content_log.slice(0, MAX_PRINT_LINE)
	_log_timer.stop()
	_log_timer.start()
	print(content)
	
func _draw_texts():
	if !_camera_ok():
		return
	# clear
	for dt in _text_objects:
		dt.visible = false

	var idx:int = 0
	for key in _texts.keys():
		var teks:Label
		if _text_objects.size() <= idx:
			teks = _content_label.duplicate()
			add_child(teks)
			_text_objects.append(teks)
		else:
			teks = _text_objects[idx]
		teks.visible = true
		teks.text = _texts[key]["message"]
		var pos_global = _texts[key]["position"]
		var pos = _active_camera.unproject_position(pos_global)
		var show = !_active_camera.is_position_behind (pos_global)
		teks.position = pos
		teks.visible = show
		idx += 1
		
	# Remove text lines after some time
	for key in _texts.keys():
		var t = _texts[key]
		if t.frame <= Engine.get_frames_drawn():
			_texts.erase(key)
			
func _draw_spheres():
	# clear
	for dt in _dot_objects:
		dt.visible = false

	var idx:int = 0
	for key in _dots.keys():
		var titik:MeshInstance3D
		if _dot_objects.size() <= idx:
			titik = _master_dot.duplicate()
			add_child(titik)
			_dot_objects.append(titik)
			titik.set_surface_override_material(0, StandardMaterial3D.new())
		else:
			titik = _dot_objects[idx]
		titik.visible = true
		var mat = titik.get_surface_override_material(0)
		mat.albedo_color =  _dots[key]["color"]
#		titik.set_surface_override_material(0, mat)
		titik.global_transform.origin = _dots[key]["position"]
		idx += 1
		
	# Remove text lines after some time
	for key in _dots.keys():
		var t = _dots[key]
		if t.frame <= Engine.get_frames_drawn():
			_dots.erase(key)
			
func _draw_lines():
	
	# clear
	for dt in _line_objects:
		dt.visible = false

	var idx:int = 0
	for key in _lines.keys():
		var garis:MeshInstance3D
		if _line_objects.size() <= idx:
			garis = _master_line.duplicate()
			
			garis.mesh = ImmediateMesh.new()
			garis.material_override = StandardMaterial3D.new()
			
			add_child(garis)
			_line_objects.append(garis)
		else:
			garis = _line_objects[idx]
		garis.visible = true
		var list_garis = _lines[key]["points"]

		var msh:ImmediateMesh = garis.mesh
		
		var mat = garis.material_override
		mat.albedo_color =  _lines[key]["color"]


		msh.clear_surfaces()
		if !list_garis.is_empty():
			msh.surface_begin(Mesh.PRIMITIVE_LINES)

			var valid = false
			for i in range(0, list_garis.size() - 1):
				var grs = list_garis[i]
				var grs_nxt = list_garis[i+1]
				msh.surface_add_vertex(grs)
				msh.surface_add_vertex(grs_nxt)
				valid = true
			# print("COUNT "+str(msh.get_surface_count()))
			if valid:
				msh.surface_end()
	

		idx += 1
	
#	DBG.set_stats("gariss", str(_lines.size()))
	
	# Remove text lines after some time
	for key in _lines.keys():
		var t = _lines[key]
		if t.frame <= Engine.get_frames_drawn():
			_lines.erase(key)

func _camera_ok() -> bool:
	# if !Network.dedicated:
	if _active_camera == null || !is_instance_valid(_active_camera):
		return false
	return true
