class_name HopaPuzzleBase
extends MiniInteractionBase
## Base class for HOPA inter-level puzzles.
## Extends MiniInteractionBase to reuse completed/failed signal contract.

var puzzle_data: Dictionary = {}


func _setup() -> void:
	duration = 120.0  # 2 minutes for puzzles


func set_puzzle_data(data: Dictionary) -> void:
	puzzle_data = data
