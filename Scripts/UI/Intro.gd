# Intro.gd - Oyun açılışında intro videosu, ardından ana menü
extends CanvasLayer

const NEXT_SCENE := "res://Scenes/MainMenu.tscn"

@onready var video: VideoStreamPlayer = $Video
@onready var title: Label = $Title
@onready var skip_label: Label = $SkipLabel
@onready var fade: ColorRect = $Fade

var _leaving := false

func _ready() -> void:
	title.modulate.a = 0.0
	skip_label.modulate.a = 0.0
	_fit_video()
	get_viewport().size_changed.connect(_fit_video)
	video.finished.connect(_on_video_finished)
	video.play()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(fade, "color:a", 0.0, 0.8)
	tw.tween_property(skip_label, "modulate:a", 1.0, 0.6).set_delay(1.5)

func _fit_video() -> void:
	# Dikey videoyu en-boy oranını koruyarak ortala
	var tex := video.get_video_texture()
	var ratio := 720.0 / 1280.0
	if tex and tex.get_height() > 0:
		ratio = float(tex.get_width()) / tex.get_height()
	var screen: Vector2 = get_viewport().get_visible_rect().size
	var w := screen.y * ratio
	video.offset_left = -w / 2
	video.offset_right = w / 2
	video.offset_top = 0
	video.offset_bottom = screen.y

func _on_video_finished() -> void:
	# Videonun sonunda başlığı göster, sonra menüye geç
	var tw := create_tween()
	tw.tween_property(title, "modulate:a", 1.0, 0.8)
	tw.tween_interval(1.2)
	await tw.finished
	_leave()

func _unhandled_input(event: InputEvent) -> void:
	if _leaving:
		return
	var pressed := (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton) \
		and event.is_pressed() and not event.is_echo()
	if pressed:
		get_viewport().set_input_as_handled()
		_leave()

func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.5)
	await tw.finished
	get_tree().change_scene_to_file(NEXT_SCENE)
