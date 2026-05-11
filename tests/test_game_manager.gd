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

# === 必要選択数 ===

func test_required_target_count_cards() -> void:
	assert_eq(gm._required_target_count(1), 2, "カード1は2回選択")
	assert_eq(gm._required_target_count(2), 3, "カード2は3回選択")
	assert_eq(gm._required_target_count(4), 1, "カード4は1回選択")
	assert_eq(gm._required_target_count(6), 4, "カード6は4回選択")
	assert_eq(gm._required_target_count(7), 2, "カード7は2回選択")
	assert_eq(gm._required_target_count(9), 4, "カード9は4回選択")

func test_required_target_count_card8_flipped() -> void:
	gm.card8_flipped = true
	assert_eq(gm._required_target_count(8), 2, "カード8裏面は2回選択")

func test_required_target_count_card8_not_flipped() -> void:
	gm.card8_flipped = false
	assert_eq(gm._required_target_count(8), 0, "カード8表面は選択不要")

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

# === スキップ回数 ===

func test_skip_count_initializes_to_zero() -> void:
	assert_eq(gm.skip_count, 0, "start_game後のskip_countは0")

func test_skip_increments_skip_count() -> void:
	gm.skip_ability()
	assert_eq(gm.skip_count, 1, "skip_ability()でskip_countが1増える")

func test_multiple_skips_accumulate_count() -> void:
	gm.skip_ability()
	gm.skip_ability()
	gm.skip_ability()
	assert_eq(gm.skip_count, 3, "3回スキップでskip_countが3")

func test_get_skip_count_returns_value() -> void:
	gm.skip_ability()
	gm.skip_ability()
	assert_eq(gm.get_skip_count(), 2, "get_skip_count()がskip_countの値を返す")

# === 能力使用回数 ===

func test_ability_use_counts_initialize_all_zero() -> void:
	for i in range(1, 10):
		assert_eq(gm.ability_use_counts[i], 0, "start_game後カード%dの能力発動回数は0" % i)

func test_commit_increments_ability_use_count() -> void:
	gm.deck.cards.assign([3, 1, 2, 4, 5, 6, 7, 8, 9])
	gm.commit_ability_execution(3, -1, -1, 3)
	assert_eq(gm.ability_use_counts[3], 1, "カード3発動後にability_use_counts[3]が1")

func test_commit_only_increments_used_card() -> void:
	gm.deck.cards.assign([3, 1, 2, 4, 5, 6, 7, 8, 9])
	gm.commit_ability_execution(3, -1, -1, 3)
	for i in range(1, 10):
		if i == 3:
			continue
		assert_eq(gm.ability_use_counts[i], 0, "カード3のみ発動時、カード%dの回数は0のまま" % i)

func test_get_ability_use_counts_has_all_cards() -> void:
	var counts = gm.get_ability_use_counts()
	for i in range(1, 10):
		assert_true(counts.has(i), "get_ability_use_counts()にカード%dのキーが存在する" % i)

# === デイリーモード ===

func test_daily_mode_flag_set_when_started_with_daily() -> void:
	gm.start_game(true)
	assert_true(gm.is_daily_mode, "デイリーモードでstart_gameするとis_daily_modeがtrue")

func test_daily_mode_flag_false_when_started_normally() -> void:
	gm.start_game(false)
	assert_false(gm.is_daily_mode, "通常モードでstart_gameするとis_daily_modeがfalse")

func test_daily_seed_returns_yyyymmdd_format() -> void:
	var seed_val = gm.get_daily_seed()
	# YYYYMMDD形式: 20000101〜99991231 の範囲
	assert_true(seed_val >= 20000101, "デイリーシードが20000101以上")
	assert_true(seed_val <= 99991231, "デイリーシードが99991231以下")

func test_daily_seed_is_consistent_within_same_call() -> void:
	# 同じ瞬間に2回呼んでも同じ値を返す
	var seed1 = gm.get_daily_seed()
	var seed2 = gm.get_daily_seed()
	assert_eq(seed1, seed2, "同じタイミングのget_daily_seed()は同じ値を返す")

func test_daily_mode_produces_fixed_deck() -> void:
	# 同じシードで2回start_gameすると同じ初期配列になる
	gm.start_game(true)
	var deck1 = gm.get_deck().duplicate()
	gm.start_game(true)
	var deck2 = gm.get_deck().duplicate()
	assert_eq(deck1, deck2, "デイリーモードは同じシードで同じ初期配列になる")

func test_free_play_deck_can_differ_from_daily() -> void:
	# フリープレイは毎回シャッフルされる（確率的テスト: 10回試して1回でも違えばOK）
	gm.start_game(true)
	var daily_deck = gm.get_deck().duplicate()
	var found_difference = false
	for _i in range(10):
		gm.start_game(false)
		if gm.get_deck() != daily_deck:
			found_difference = true
			break
	assert_true(found_difference, "フリープレイはデイリーと異なる配列になりうる")
