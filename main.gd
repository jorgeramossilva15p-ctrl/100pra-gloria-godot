extends Node2D

const VIEW := Vector2(1280, 720)
const FIELD := Rect2(150, 110, 980, 500)
const PLAYER_RADIUS := 17.0
const BALL_RADIUS := 9.0
const MATCH_LENGTH := 600.0
const TEAM_BLUE := Color("#27a7ff")
const TEAM_WHITE := Color("#f8fbff")
const DARK := Color("#07111f")
const PANEL := Color("#101f35")
const ACCENT := Color("#ffd447")

var screen := "menu"
var mode := "bot"
var match_time := 0.0
var score := [0, 0]
var rng := RandomNumberGenerator.new()
var ball := Vector2.ZERO
var ball_velocity := Vector2.ZERO
var players: Array[Dictionary] = []
var names := ["Neymar Jr", "Rafa Silva", "Ganso", "Pedrinho", "Soteldo", "Joaquim", "Giuliano", "Otero", "Marcos Leonardo", "Breno Lopes"]
var online_peer_id := ""
var online_state := "offline"

func _ready() -> void:
	rng.randomize()
	queue_redraw()

func _process(delta: float) -> void:
	if screen == "match":
		match_time += delta
		_update_match(delta)
		_poll_peerjs()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_handle_click(event.position)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and screen == "match":
		screen = "menu"

func _handle_click(pos: Vector2) -> void:
	if screen == "menu":
		if Rect2(360, 330, 250, 64).has_point(pos):
			_start_match("bot")
		elif Rect2(670, 330, 250, 64).has_point(pos):
			_start_match("local")
		elif Rect2(360, 420, 560, 54).has_point(pos):
			_start_match("online")
	elif screen == "match" and Rect2(1080, 24, 150, 44).has_point(pos):
		screen = "menu"

func _start_match(selected_mode: String) -> void:
	mode = selected_mode
	screen = "match"
	match_time = 0.0
	score = [0, 0]
	ball = FIELD.get_center()
	ball_velocity = Vector2.ZERO
	players.clear()
	players.append({"pos": Vector2(FIELD.position.x + 210, FIELD.get_center().y), "team": 0, "name": _random_name(), "number": rng.randi_range(1, 99), "human": true})
	players.append({"pos": Vector2(FIELD.position.x + 330, FIELD.get_center().y - 90), "team": 0, "name": _random_name(), "number": rng.randi_range(1, 99), "human": false})
	players.append({"pos": Vector2(FIELD.end.x - 210, FIELD.get_center().y), "team": 1, "name": _random_name(), "number": rng.randi_range(1, 99), "human": mode == "local"})
	players.append({"pos": Vector2(FIELD.end.x - 330, FIELD.get_center().y + 90), "team": 1, "name": _random_name(), "number": rng.randi_range(1, 99), "human": false})
	if mode == "online":
		_js_online_init()

func _random_name() -> String:
	return names[rng.randi_range(0, names.size() - 1)]

func _update_match(delta: float) -> void:
	if match_time >= MATCH_LENGTH:
		return
	var p1_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	players[0].pos += p1_input * 235.0 * delta
	if mode == "local":
		var p2_input := Input.get_vector("p2_left", "p2_right", "p2_up", "p2_down")
		players[2].pos += p2_input * 235.0 * delta
	else:
		_bot_move(players[2], delta, true)
	_bot_move(players[1], delta, false)
	_bot_move(players[3], delta, false)
	for p in players:
		p.pos.x = clamp(p.pos.x, FIELD.position.x + 30.0, FIELD.end.x - 30.0)
		p.pos.y = clamp(p.pos.y, FIELD.position.y + 30.0, FIELD.end.y - 30.0)
		if p.pos.distance_to(ball) < PLAYER_RADIUS + BALL_RADIUS + 3:
			var direction: Vector2 = (ball - p.pos).normalized()
			if direction == Vector2.ZERO:
				direction = Vector2.RIGHT if p.team == 0 else Vector2.LEFT
			ball_velocity = direction * 115.0
			if (p.human and Input.is_action_just_pressed("pass_shoot")) or (p.team == 1 and rng.randf() < 0.006):
				ball_velocity = Vector2.RIGHT * 520.0 if p.team == 0 else Vector2.LEFT * 520.0
	ball += ball_velocity * delta
	ball_velocity = ball_velocity.move_toward(Vector2.ZERO, 180.0 * delta)
	if ball.y < FIELD.position.y + 12 or ball.y > FIELD.end.y - 12:
		ball_velocity.y *= -1
		ball.y = clamp(ball.y, FIELD.position.y + 12, FIELD.end.y - 12)
	if ball.x < FIELD.position.x - 35:
		score[1] += 1
		_reset_after_goal()
	elif ball.x > FIELD.end.x + 35:
		score[0] += 1
		_reset_after_goal()
	if mode == "online":
		_js_online_send_state()

func _bot_move(p: Dictionary, delta: float, attack: bool) -> void:
	var target := ball
	if not attack:
		target = ball.lerp(FIELD.get_center(), 0.18)
	var direction: Vector2 = p.pos.direction_to(target)
	p.pos += direction * 125.0 * delta

func _reset_after_goal() -> void:
	ball = FIELD.get_center()
	ball_velocity = Vector2.ZERO
	for i in players.size():
		players[i].pos = Vector2(FIELD.position.x + 210, FIELD.get_center().y) if players[i].team == 0 else Vector2(FIELD.end.x - 210, FIELD.get_center().y)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), DARK)
	if screen == "menu":
		_draw_menu()
	else:
		_draw_match()

func _draw_menu() -> void:
	# Background gradient-like bands and stadium lights.
	for i in 8:
		draw_rect(Rect2(0, i * 90, VIEW.x, 90), Color(0.025 + i * 0.004, 0.055 + i * 0.006, 0.11 + i * 0.01))
	for x in [150, 420, 690, 960, 1230]:
		draw_circle(Vector2(x, 72), 25, Color(1, 0.86, 0.36, 0.12))
		draw_circle(Vector2(x, 72), 9, Color("#ffe69a"))
	draw_string(ThemeDB.fallback_font, Vector2(360, 190), "100 PRA GLÓRIA", HORIZONTAL_ALIGNMENT_LEFT, -1, 72, Color("#f4f7ff"))
	draw_string(ThemeDB.fallback_font, Vector2(450, 236), "VILA BELMIRO // PROTÓTIPO 0.01", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, ACCENT)
	_draw_card(Rect2(360, 300, 560, 220), Color(0.04, 0.1, 0.18, 0.92))
	draw_string(ThemeDB.fallback_font, Vector2(410, 305), "ESCOLHA O MODO DE PARTIDA", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#bcd1e8"))
	_draw_button(Rect2(360, 330, 250, 64), "JOGAR VS BOT", TEAM_BLUE)
	_draw_button(Rect2(670, 330, 250, 64), "2 JOGADORES", Color("#995cff"))
	_draw_button(Rect2(360, 420, 560, 54), "MULTIPLAYER ONLINE // PEERJS", Color("#18c99a"))
	draw_string(ThemeDB.fallback_font, Vector2(392, 505), "WASD / setas: mover    ESPAÇO: chutar    ESC: voltar", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#7690ad"))

func _draw_card(rect: Rect2, color: Color) -> void:
	draw_style_box(_box(color, 18, Color(1, 1, 1, 0.06), 1), rect)

func _draw_button(rect: Rect2, label: String, color: Color) -> void:
	draw_style_box(_box(Color(color, 0.17), 12, Color(color, 0.7), 1), rect)
	draw_string(ThemeDB.fallback_font, Vector2(rect.position.x + 22, rect.position.y + 40), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#f7fbff"))

func _draw_match() -> void:
	_draw_stadium()
	_draw_field()
	for p in players:
		_draw_player(p)
	_draw_ball()
	_draw_hud()

func _draw_stadium() -> void:
	draw_rect(Rect2(65, 50, 1150, 620), Color("#0b1523"))
	draw_rect(Rect2(85, 70, 1110, 580), Color("#14243a"))
	# Vila Belmiro-style compact stands.
	for y in range(82, 650, 34):
		for x in range(105, 1180, 35):
			var crowd := Color("#1b3552") if (x + y) % 3 else Color("#24486c")
			draw_circle(Vector2(x, y), 5, crowd)
	draw_rect(Rect2(90, 72, 1100, 34), Color("#0a1220"))
	draw_string(ThemeDB.fallback_font, Vector2(485, 96), "VILA BELMIRO 1916", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#d9e7f6"))
	# floodlights
	for x in [130, 1150]:
		draw_line(Vector2(x, 82), Vector2(x, 145), Color("#8fa6bf"), 4)
		draw_circle(Vector2(x, 76), 12, Color("#fff0b4"))

func _draw_field() -> void:
	draw_style_box(_box(Color("#176a4a"), 10, Color("#54d69b"), 3), FIELD)
	for i in range(1, 10):
		var stripe := Rect2(FIELD.position.x + FIELD.size.x * i / 10.0, FIELD.position.y, FIELD.size.x / 20.0, FIELD.size.y)
		draw_rect(stripe, Color(0.2, 0.55, 0.38, 0.16))
	var line := Color(0.82, 0.98, 0.9, 0.88)
	draw_line(Vector2(FIELD.get_center().x, FIELD.position.y), Vector2(FIELD.get_center().x, FIELD.end.y), line, 3)
	draw_arc(FIELD.get_center(), 72, 0, TAU, 64, line, 3)
	draw_circle(FIELD.get_center(), 4, line)
	draw_rect(Rect2(FIELD.position.x, FIELD.get_center().y - 125, 130, 250), Color(1, 1, 1, 0), false, 3)
	draw_rect(Rect2(FIELD.end.x - 130, FIELD.get_center().y - 125, 130, 250), Color(1, 1, 1, 0), false, 3)
	draw_rect(Rect2(FIELD.position.x - 18, FIELD.get_center().y - 70, 18, 140), Color("#f4f7ff"), false, 4)
	draw_rect(Rect2(FIELD.end.x, FIELD.get_center().y - 70, 18, 140), Color("#f4f7ff"), false, 4)

func _draw_player(p: Dictionary) -> void:
	var color := TEAM_BLUE if p.team == 0 else TEAM_WHITE
	draw_circle(p.pos + Vector2(0, 8), PLAYER_RADIUS + 5, Color(0, 0, 0, 0.24))
	draw_circle(p.pos, PLAYER_RADIUS + 3, Color("#06101d"))
	draw_circle(p.pos, PLAYER_RADIUS, color)
	draw_arc(p.pos, PLAYER_RADIUS, 0, TAU, 24, Color("#07111f"), 2)
	draw_circle(p.pos + Vector2(0, -5), 6, Color("#efb78c"))
	draw_string(ThemeDB.fallback_font, p.pos + Vector2(-9, 6), str(p.number), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, DARK if p.team == 1 else Color.WHITE)
	if p.human:
		draw_arc(p.pos, PLAYER_RADIUS + 9, 0, TAU, 32, ACCENT, 2)

func _draw_ball() -> void:
	draw_circle(ball + Vector2(2, 4), BALL_RADIUS + 3, Color(0, 0, 0, 0.28))
	draw_circle(ball, BALL_RADIUS, Color("#ffffff"))
	draw_circle(ball, 3, Color("#19243a"))

func _draw_hud() -> void:
	draw_style_box(_box(Color(0.02, 0.06, 0.11, 0.95), 12, Color(1, 1, 1, 0.12), 1), Rect2(340, 20, 600, 64))
	draw_string(ThemeDB.fallback_font, Vector2(372, 48), "SANTOS", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, TEAM_WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(560, 57), str(score[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, TEAM_BLUE)
	draw_string(ThemeDB.fallback_font, Vector2(630, 55), "-", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("#7690ad"))
	draw_string(ThemeDB.fallback_font, Vector2(692, 57), str(score[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color("#f0f5ff"))
	draw_string(ThemeDB.fallback_font, Vector2(760, 48), "VISITANTE", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#d8e6f4"))
	var time_left: int = maxi(0, int(MATCH_LENGTH - match_time))
	draw_string(ThemeDB.fallback_font, Vector2(585, 77), "%02d:%02d" % [time_left / 60, time_left % 60], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, ACCENT)
	draw_style_box(_box(Color(0.04, 0.1, 0.18, 0.95), 9, Color(1, 1, 1, 0.1), 1), Rect2(24, 24, 230, 92))
	draw_string(ThemeDB.fallback_font, Vector2(42, 52), "MODO: " + ("BOT" if mode == "bot" else "2 PLAYERS" if mode == "local" else "PEERJS"), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#dce8f5"))
	draw_string(ThemeDB.fallback_font, Vector2(42, 78), "ARENA 01 / VILA BELMIRO", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#7ea4c4"))
	_draw_button(Rect2(1080, 24, 150, 44), "SAIR", Color("#e75b71"))

func _box(bg: Color, radius: int, border: Color, width: int) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = bg
	b.corner_radius_top_left = radius
	b.corner_radius_top_right = radius
	b.corner_radius_bottom_left = radius
	b.corner_radius_bottom_right = radius
	b.border_color = border
	b.border_width_left = width
	b.border_width_right = width
	b.border_width_top = width
	b.border_width_bottom = width
	return b

# PeerJS bridge: active in HTML5 exports. The game polls a small JS mailbox so
# the same match simulation can later be synchronized without changing the UI.
func _js_online_init() -> void:
	if not OS.has_feature("web"):
		online_state = "web export required"
		return
	JavaScriptBridge.eval("""
window._100p = window._100p || {inbox:[], id:'', peer:null, conn:null};
if (!window._100p.peer) {
 const s=document.createElement('script'); s.src='https://unpkg.com/peerjs@1.5.4/dist/peerjs.min.js';
 s.onload=()=>{ window._100p.peer=new Peer(); window._100p.peer.on('open', id=>window._100p.id=id); window._100p.peer.on('connection', c=>{window._100p.conn=c;c.on('data',d=>window._100p.inbox.push(d));}); };
 document.head.appendChild(s);
}
""", true)
	online_state = "connecting"

func _js_online_send_state() -> void:
	if OS.has_feature("web"):
		var payload := JSON.stringify({"ball": [ball.x, ball.y], "score": score, "time": match_time})
		JavaScriptBridge.eval("window._100p?.conn?.send(" + payload + ");", true)

func _poll_peerjs() -> void:
	if not OS.has_feature("web"):
		return
	var received = JavaScriptBridge.eval("JSON.stringify(window._100p?.inbox?.splice(0) || [])", true)
	if received is String and received != "[]":
		online_state = "connected"
