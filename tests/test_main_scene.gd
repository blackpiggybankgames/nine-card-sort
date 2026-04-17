extends GutTest

# Main シーンのボタン押下テスト
# 「ボタンを押してもゲームが始まらなくなる」回帰を防ぐ

var main_scene: Node

func before_each() -> void:
	main_scene = preload("res://scenes/Main.tscn").instantiate()
	add_child_autofree(main_scene)
	await get_tree().process_frame

func test_start_button_begins_game() -> void:
	main_scene.get_node("UILayer/TitleScreen/StartButton").pressed.emit()
	assert_eq(
		main_scene.game_manager.current_state,
		GameManager.GameState.PLAYING,
		"スタートボタン押下後は PLAYING 状態になる"
	)

func test_skip_button_increments_turn() -> void:
	# ゲーム開始後、スキップボタンで手数が増えることを確認
	main_scene.game_manager.start_game()
	var turn_before = main_scene.game_manager.get_turn_count()
	# アニメーション待ちをスキップするためボタンを強制有効化
	main_scene.get_node("UILayer/GameUI/SkipButton").disabled = false
	main_scene.get_node("UILayer/GameUI/SkipButton").pressed.emit()
	assert_eq(
		main_scene.game_manager.get_turn_count(),
		turn_before + 1,
		"スキップボタン押下で手数が1増える"
	)

func test_retry_button_restarts_game() -> void:
	# クリア状態からリトライ
	main_scene.game_manager.start_game()
	main_scene.game_manager.current_state = GameManager.GameState.CLEARED
	main_scene.get_node("UILayer/ClearScreen/RetryButton").pressed.emit()
	assert_eq(
		main_scene.game_manager.current_state,
		GameManager.GameState.PLAYING,
		"リトライボタン押下後は PLAYING 状態になる"
	)
	assert_eq(
		main_scene.game_manager.get_turn_count(),
		0,
		"リトライ後は手数が0にリセットされる"
	)

func test_title_button_returns_to_title() -> void:
	# クリア状態からタイトルへ
	main_scene.game_manager.start_game()
	main_scene.game_manager.current_state = GameManager.GameState.CLEARED
	main_scene.get_node("UILayer/ClearScreen/TitleButton").pressed.emit()
	assert_eq(
		main_scene.game_manager.current_state,
		GameManager.GameState.TITLE,
		"タイトルボタン押下後は TITLE 状態になる"
	)
