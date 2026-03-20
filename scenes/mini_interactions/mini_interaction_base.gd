class_name MiniInteractionBase
extends Control
## Base class for all mini-interactions.

signal completed
signal failed

var duration: float = 5.0
var elapsed: float = 0.0
var is_active: bool = false


func _ready() -> void:
	start_interaction()


func start_interaction() -> void:
	is_active = true
	elapsed = 0.0
	_setup()


func _setup() -> void:
	pass  # Override in subclasses


func _process(delta: float) -> void:
	if not is_active:
		return
	elapsed += delta
	_process_interaction(delta)
	if elapsed >= duration and is_active:
		fail()


func _process_interaction(_delta: float) -> void:
	pass  # Override in subclasses


func complete_interaction() -> void:
	if not is_active:
		return
	is_active = false
	completed.emit()


func fail() -> void:
	if not is_active:
		return
	is_active = false
	failed.emit()


func get_progress() -> float:
	return clampf(elapsed / duration, 0.0, 1.0) if duration > 0 else 1.0
