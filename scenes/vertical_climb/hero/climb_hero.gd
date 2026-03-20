extends Node2D
## Climbing hero for vertical mode — SVG sprite, gender-aware.
## Enhanced: arc jump, squash & stretch, rotation tilt, landing dust, ghost trail.

var target_pos: Vector2 = Vector2.ZERO
var speed: float = 600.0
var is_jumping: bool = false
var _anim_time: float = 0.0
var dress_color: Color = ThemeManager.MINT_SAGE

var _start_pos: Vector2 = Vector2.ZERO
var _jump_progress: float = 0.0
var _jump_duration: float = 0.0

var _idle_tex: Texture2D
var _jump_tex: Texture2D
var _sprite: Sprite2D

const BASE_SCALE := 1.2  # SVG is 120x200 now; 1.2 → ~144x240px
var _squash_time: float = 0.0

# Ghost trail during jump
var _trail_sprites: Array[Sprite2D] = []
const TRAIL_COUNT := 3
var _trail_timer: float = 0.0

# Landing dust particles
var _dust_particles: GPUParticles2D = null


func _ready() -> void:
	target_pos = position
	dress_color = ThemeManager.get_dress_color(GameState.current_day)

	if GameState.gender == "male":
		_idle_tex = load("res://assets/hero/climb/hero_climb_idle_male.svg")
		_jump_tex = load("res://assets/hero/climb/hero_climb_jump_male.svg")
	else:
		_idle_tex = load("res://assets/hero/climb/hero_climb_idle.svg")
		_jump_tex = load("res://assets/hero/climb/hero_climb_jump.svg")

	_sprite = Sprite2D.new()
	_sprite.texture = _idle_tex
	_sprite.scale = Vector2(BASE_SCALE, BASE_SCALE)
	_sprite.self_modulate = dress_color
	_sprite.position = Vector2(0, -50)
	add_child(_sprite)

	# Pre-create ghost trail sprites (hidden)
	for i in range(TRAIL_COUNT):
		var ghost := Sprite2D.new()
		ghost.texture = _jump_tex
		ghost.scale = Vector2(BASE_SCALE, BASE_SCALE)
		ghost.self_modulate = Color(dress_color.r, dress_color.g, dress_color.b, 0.0)
		ghost.position = Vector2(0, -50)
		ghost.z_index = -1
		add_child(ghost)
		_trail_sprites.append(ghost)

	# Landing dust
	_setup_dust_particles()


func _setup_dust_particles() -> void:
	_dust_particles = GPUParticles2D.new()
	_dust_particles.emitting = false
	_dust_particles.one_shot = true
	_dust_particles.amount = 12
	_dust_particles.lifetime = 0.6
	_dust_particles.explosiveness = 0.9
	_dust_particles.z_index = -1

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 75.0
	mat.initial_velocity_min = 40.0
	mat.initial_velocity_max = 100.0
	mat.gravity = Vector3(0, 200, 0)
	mat.scale_min = 0.8
	mat.scale_max = 2.0
	var ramp := Gradient.new()
	ramp.set_offset(0, 0.0)
	ramp.set_color(0, Color(0.85, 0.78, 0.65, 0.7))
	ramp.set_offset(ramp.get_point_count() - 1, 1.0)
	ramp.set_color(ramp.get_point_count() - 1, Color(0.9, 0.85, 0.75, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = ramp
	mat.color_ramp = tex
	_dust_particles.process_material = mat

	# Soft circle texture for dust
	var size := 8
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(4, 4)
	for y in range(size):
		for x in range(size):
			var dist := Vector2(x, y).distance_to(center)
			var alpha := clampf(1.0 - dist / 4.0, 0.0, 1.0)
			alpha *= alpha
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	_dust_particles.texture = ImageTexture.create_from_image(img)
	add_child(_dust_particles)


func jump_to(pos: Vector2) -> void:
	_start_pos = position
	target_pos = pos
	_jump_progress = 0.0
	_jump_duration = maxf(0.15, _start_pos.distance_to(pos) / speed)
	_trail_timer = 0.0
	is_jumping = true
	if _sprite:
		_sprite.texture = _jump_tex
	# Reset trail
	for ghost in _trail_sprites:
		ghost.modulate.a = 0.0


func _process(delta: float) -> void:
	_anim_time += delta
	if is_jumping:
		_jump_progress += delta / _jump_duration
		if _jump_progress >= 1.0:
			position = target_pos
			is_jumping = false
			_squash_time = 0.3
			if _sprite:
				_sprite.texture = _idle_tex
				_sprite.rotation = 0.0
			# Emit landing dust
			if _dust_particles:
				_dust_particles.position = Vector2(0, 0)
				_dust_particles.restart()
				_dust_particles.emitting = true
			# Hide trail
			for ghost in _trail_sprites:
				ghost.modulate.a = 0.0
		else:
			# Quadratic bezier arc
			var t := _jump_progress
			var mid := (_start_pos + target_pos) * 0.5
			mid.y -= 120.0
			position = _start_pos.lerp(mid, t).lerp(mid.lerp(target_pos, t), t)

			# Rotation tilt toward movement direction
			if _sprite:
				var dir_x := target_pos.x - _start_pos.x
				var tilt := clampf(dir_x / 300.0, -1.0, 1.0) * 0.2  # max ±0.2 rad (~11°)
				_sprite.rotation = tilt * sin(t * PI)  # peaks at midpoint, returns to 0

			# Ghost trail — spawn one every ~0.06s
			_trail_timer += delta
			if _trail_timer > 0.06:
				_trail_timer = 0.0
				# Shift trail positions: oldest gets current, others age
				for i in range(TRAIL_COUNT - 1, 0, -1):
					_trail_sprites[i].global_position = _trail_sprites[i - 1].global_position
					_trail_sprites[i].modulate.a = _trail_sprites[i - 1].modulate.a * 0.5
					_trail_sprites[i].rotation = _trail_sprites[i - 1].rotation
				if _trail_sprites.size() > 0:
					_trail_sprites[0].global_position = global_position + Vector2(0, -50)
					_trail_sprites[0].modulate.a = 0.25
					_trail_sprites[0].rotation = _sprite.rotation if _sprite else 0.0

	# Fade out trail when not jumping
	if not is_jumping:
		for ghost in _trail_sprites:
			if ghost.modulate.a > 0.01:
				ghost.modulate.a *= 0.85

	# Squash & stretch animations
	if _sprite:
		var sx: float = BASE_SCALE
		var sy: float = BASE_SCALE
		if is_jumping:
			# Stretch vertically while jumping
			sy = BASE_SCALE * (1.0 + sin(_anim_time * 10.0) * 0.08)
			sx = BASE_SCALE * (1.0 - sin(_anim_time * 10.0) * 0.04)
		elif _squash_time > 0.0:
			# Landing squash (wide + short) then bounce back
			_squash_time -= delta
			var t := _squash_time / 0.3
			var squash := sin(t * PI) * 0.12
			sx = BASE_SCALE * (1.0 + squash)
			sy = BASE_SCALE * (1.0 - squash)
		else:
			# Gentle idle bobbing
			var bob := sin(_anim_time * 2.5) * 0.015
			sy = BASE_SCALE * (1.0 + bob)
			# Return rotation to 0
			if _sprite.rotation != 0.0:
				_sprite.rotation = lerpf(_sprite.rotation, 0.0, delta * 8.0)
		_sprite.scale = Vector2(sx, sy)
