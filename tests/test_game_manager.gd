extends GutTest

# GameManager の状態ロジックテスト

var gm: GameManager

func before_each() -> void:
	gm = GameManager.new()
	add_child_autofree(gm)
	gm.start_game()

# === 対象選択が必要なカード ===

func test_requires_target_cards_1_2_4_6_7_9() -> void:
	for card in [1, 2, 4, 6, 7, 9]:
		assert_true(gm._requires_target_selection(card),
			"カード%dは対象選択が必要" % card)

func test_no_target_cards_3_5() -> void:
	for card in [3, 5]:
		assert_false(gm._requires_target_selection(card),
			"カード%dは対象選択不要" % card)

func test_card8_requires_target_when_flipped() -> void:
	gm.card8_flipped = true
	assert_true(gm._requires_target_selection(8), "カード8裏面は対象選択が必要")

func test_card8_no_target_when_not_flipped() -> void:
	gm.card8_flipped = false
	assert_false(gm._requires_target_selection(8), "カード8表面は対象選択不要")

# === 2段階選択が必要なカード ===

func test_two_steps_cards_1_6_7() -> void:
	for card in [1, 6, 7]:
		assert_true(gm._requires_two_steps(card),
			"カード%dは2段階選択が必要" % card)

func test_card8_two_steps_when_flipped() -> void:
	gm.card8_flipped = true
	assert_true(gm._requires_two_steps(8), "カード8裏面は2段階選択")

# === カード8のフリップ状態 ===

func test_card8_flipped_toggles_after_use() -> void:
	# 表面（false）で発動 → 裏面（true）になる
	gm.card8_flipped = false
	gm.deck.cards.assign([8, 1, 2, 3, 4, 5, 6, 7, 9])
	gm.commit_ability_execution(8, -1, -1, 8)
	assert_true(gm.card8_flipped, "表面発動後は裏面になる")

func test_card8_flipped_toggles_back_after_second_use() -> void:
	# 裏面（true）で発動 → 表面（false）に戻る
	gm.card8_flipped = true
	gm.deck.cards.assign([8, 1, 2, 3, 4, 5, 6, 7, 9])
	# 裏面: card_to_move=1, before_card=3
	gm.commit_ability_execution(8, 1, 3, 8)
	assert_false(gm.card8_flipped, "裏面発動後は表面に戻る")

# === スキップで手数増加 ===

func test_skip_increments_turn_count() -> void:
	var before = gm.get_turn_count()
	gm.skip_ability()
	assert_eq(gm.get_turn_count(), before + 1, "スキップで手数が1増える")

# === 能力発動後も山札が9枚 ===

func test_commit_execution_preserves_card_count() -> void:
	# カード3（全体リバース）は対象選択不要なので検証しやすい
	gm.deck.cards.assign([3, 1, 2, 4, 5, 6, 7, 8, 9])
	gm.commit_ability_execution(3, -1, -1, 3)
	assert_eq(gm.deck.cards.size(), 9, "能力発動後も山札は9枚")
