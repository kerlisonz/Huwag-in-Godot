extends Control

# EndingCredits - Sequência Final e Créditos de Huwag (Fim do Ato 3)
# Conclusão emocionante e coerente com a continuidade narrativa
# Sem promessas fáceis de cura, mas com a dignidade da aceitação e da vida.

@onready var credits_label: Label = get_node_or_null("ScrollContainer/VBox/CreditsLabel")
@onready var title_label: Label = get_node_or_null("ScrollContainer/VBox/TitleLabel")
@onready var prompt_label: Label = get_node_or_null("PromptLabel")
@onready var scroll_container: Control = get_node_or_null("ScrollContainer")

var _scroll_pos: float = 0.0
var _can_skip: float = 2.0

func _ready() -> void:
	if has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		am.play_bgm("vhs_memory_bgm", 2.0)
		am.play_ambience("morning_ambience", 2.0)

	prompt_label.modulate.a = 0.0

func _process(delta: float) -> void:
	if _can_skip > 0.0:
		_can_skip -= delta

	_scroll_pos += delta * 22.0
	if scroll_container:
		scroll_container.position.y = 360.0 - _scroll_pos

	if _scroll_pos > 380.0:
		prompt_label.modulate.a = minf(1.0, prompt_label.modulate.a + delta * 2.0)

func _unhandled_input(event: InputEvent) -> void:
	if _can_skip <= 0.0 and (
		event.is_action_pressed("ui_accept")
		or (event is InputEventKey and event.pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE or event.keycode == KEY_ESCAPE))
		or (event is InputEventMouseButton and event.pressed)
	):
		_return_to_title()

func _return_to_title() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.8)
	tw.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/menu/TitleScreen.tscn")
	)
