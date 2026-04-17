extends GutTest

# 各カード能力のロジックテスト（8枚状態: 能力カード除外後を想定）

var deck: Deck

func before_each() -> void:
	deck = Deck.new()
	add_child_autofree(deck)

# === カード1: 数値±1入れ替え ===

func test_ability1_swaps_adjacent_values() -> void:
	# [1,2,3,4,5,6,7,8] で 2 と 3 を入れ替え（数値差=1）
	deck.cards.assign([1, 2, 3, 4, 5, 6, 7, 8])
	var result = deck.ability_swap_adjacent_value(2, 3)
	assert_true(result, "数値差1なら入れ替え成功")
	assert_eq(deck.cards[1], 3, "元の2の位置に3が来る")
	assert_eq(deck.cards[2], 2, "元の3の位置に2が来る")

func test_ability1_rejects_nonadjacent() -> void:
	deck.cards.assign([1, 2, 3, 4, 5, 6, 7, 8])
	var result = deck.ability_swap_adjacent_value(2, 4)
	assert_false(result, "数値差2はfalse")

# === カード2: 隣接3枚順繰り ===

func test_ability2_rotates_three() -> void:
	# [1,2,3,...] で 先頭カード=1 → [2,3,1,...]
	deck.cards.assign([1, 2, 3, 4, 5, 6, 7, 8])
	var result = deck.ability_rotate_three(1)
	assert_true(result, "有効な位置ならtrue")
	assert_eq(deck.cards[0], 2, "A→Bに")
	assert_eq(deck.cards[1], 3, "B→Cに")
	assert_eq(deck.cards[2], 1, "C→Aに（末尾へ）")

func test_ability2_rejects_near_end() -> void:
	# 8枚配列でindex 6は末尾から2枚以内（index > size-3=5）
	deck.cards.assign([1, 2, 3, 4, 5, 6, 7, 8])
	var result = deck.ability_rotate_three(7)  # index=6
	assert_false(result, "末尾から2枚以内の指定はfalse")

# === カード3: 全体リバース ===

func test_ability3_reverses_all() -> void:
	deck.cards.assign([1, 2, 3, 4, 5, 6, 7, 8])
	deck.ability_reverse_all()
	assert_eq(deck.cards[0], 8, "先頭が末尾カードになる")
	assert_eq(deck.cards[7], 1, "末尾が先頭カードになる")
	assert_eq(deck.cards[3], 5, "中央も逆転する")

# === カード4: どかす ===

func test_ability4_displaces_center() -> void:
	# [1,2,3,4,5,6,7,8] で 3（index=2）を指定
	# 両隣2と4が入れ替わり、3が末尾へ
	deck.cards.assign([1, 2, 3, 4, 5, 6, 7, 8])
	var result = deck.ability_displace(3)
	assert_true(result, "端以外の選択は成功")
	# 両隣スワップ後にselected_card(index=2)を除去するため、元index=3の値がindex=2にずれる
	assert_eq(deck.cards[1], 4, "右隣だった4が左隣の位置（index 1）へ")
	assert_eq(deck.cards[2], 2, "左隣だった2は選択カード除去後にindex 2へ")
	assert_eq(deck.cards[7], 3, "選択カード3が末尾へ")

func test_ability4_rejects_first_card() -> void:
	deck.cards.assign([1, 2, 3, 4, 5, 6, 7, 8])
	assert_false(deck.ability_displace(1), "先頭（index=0）はfalse")

func test_ability4_rejects_last_card() -> void:
	deck.cards.assign([1, 2, 3, 4, 5, 6, 7, 8])
	assert_false(deck.ability_displace(8), "末尾（index=7）はfalse")

# === カード5: 上下入れ替え ===

func test_ability5_swaps_halves() -> void:
	deck.cards.assign([1, 2, 3, 4, 5, 6, 7, 8])
	deck.ability_swap_halves()
	assert_eq(deck.cards[0], 5, "元の5番目が先頭に")
	assert_eq(deck.cards[3], 8, "元の8番目が4番目に")
	assert_eq(deck.cards[4], 1, "元の1番目が5番目に")
	assert_eq(deck.cards[7], 4, "元の4番目が末尾に")

# === カード6: 2セット下送り ===

func test_ability6_sends_pairs_to_bottom() -> void:
	# [1,2,3,4,5,6,7,8] で (1,2) と (5,6) を送る
	# インデックスが低い(1,2)が先に末尾へ → 結果: [3,4,7,8,1,2,5,6]
	deck.cards.assign([1, 2, 3, 4, 5, 6, 7, 8])
	var result = deck.ability_send_pairs_to_bottom(1, 5)
	assert_true(result, "重ならない2セットは成功")
	assert_eq(deck.cards[4], 1, "先に送られたセットの1枚目")
	assert_eq(deck.cards[5], 2, "先に送られたセットの2枚目")
	assert_eq(deck.cards[6], 5, "後に送られたセットの1枚目")
	assert_eq(deck.cards[7], 6, "後に送られたセットの2枚目")

func test_ability6_rejects_overlapping_pairs() -> void:
	# (1,2) と (2,3) は重なる（abs(0-1)=1 ≤ 1）
	deck.cards.assign([1, 2, 3, 4, 5, 6, 7, 8])
	assert_false(deck.ability_send_pairs_to_bottom(1, 2), "重なるセットはfalse")

# === カード7: 3枚ブロック差し込み ===

func test_ability7_inserts_block() -> void:
	# [1,2,3,4,5,6,7,8] でブロック中央=6（index=5）、ギャップ右側=2（index=1）
	# ブロック[5,6,7]を カード2の直前に挿入 → [1,5,6,7,2,3,4,8]
	deck.cards.assign([1, 2, 3, 4, 5, 6, 7, 8])
	var result = deck.ability_insert_block(2, 6)
	assert_true(result, "有効な差し込みは成功")
	assert_eq(deck.cards[1], 5, "ブロック左端が挿入位置に")
	assert_eq(deck.cards[2], 6, "ブロック中央が挿入位置+1に")
	assert_eq(deck.cards[3], 7, "ブロック右端が挿入位置+2に")
	assert_eq(deck.cards[4], 2, "gap_right_cardがブロックの直後に")

func test_ability7_rejects_block_containing_gap() -> void:
	# ブロック中央=3（index=2）、ギャップ右側=4（index=3）→ j==i-1 でNG
	deck.cards.assign([1, 2, 3, 4, 5, 6, 7, 8])
	assert_false(deck.ability_insert_block(4, 3), "ギャップがブロック内にある場合はfalse")

func test_ability7_rejects_front_insert() -> void:
	# ギャップ右側がindex=0（先頭前への挿入）はNG
	deck.cards.assign([1, 2, 3, 4, 5, 6, 7, 8])
	assert_false(deck.ability_insert_block(1, 5), "先頭前への挿入はfalse")

# === カード8裏面: 任意カードを指定カードの直前へ移動 ===

func test_ability8_moves_before() -> void:
	# [1,2,3,4,5,6,7,8] でカード6をカード3の直前へ → [1,2,6,3,4,5,7,8]
	deck.cards.assign([1, 2, 3, 4, 5, 6, 7, 8])
	var result = deck.ability_move_before(6, 3)
	assert_true(result, "有効な移動は成功")
	assert_eq(deck.cards[2], 6, "移動カードが挿入位置に")
	assert_eq(deck.cards[3], 3, "before_cardがその直後に")

func test_ability8_rejects_self_target() -> void:
	# card_to_move == before_card: 自身を除去後にbefore_cardが見つからない
	deck.cards.assign([1, 2, 3, 4, 5, 6, 7, 8])
	assert_false(deck.ability_move_before(5, 5), "自分自身を対象にするとfalse")

# === カード9: 外側含む4枚逆順 ===

func test_ability9_reverses_four() -> void:
	# [1,2,3,4,5,6,7,8] でペアトップ=3（index=2）
	# c0=cards[1]=2, c1=cards[2]=3, c2=cards[3]=4, c3=cards[4]=5
	# 逆順 → cards[1]=5, cards[2]=4, cards[3]=3, cards[4]=2
	deck.cards.assign([1, 2, 3, 4, 5, 6, 7, 8])
	var result = deck.ability_reverse_four(3)
	assert_true(result, "有効なペア指定は成功")
	assert_eq(deck.cards[1], 5, "最外左が最外右に")
	assert_eq(deck.cards[2], 4, "内左が内右に")
	assert_eq(deck.cards[3], 3, "内右が内左に")
	assert_eq(deck.cards[4], 2, "最外右が最外左に")

func test_ability9_rejects_first_card() -> void:
	deck.cards.assign([1, 2, 3, 4, 5, 6, 7, 8])
	assert_false(deck.ability_reverse_four(1), "先頭（外側が存在しない）はfalse")

func test_ability9_rejects_near_end() -> void:
	# ペアトップ=7（index=6）: j+2=8 > size-1=7 → false
	deck.cards.assign([1, 2, 3, 4, 5, 6, 7, 8])
	assert_false(deck.ability_reverse_four(7), "末尾から2枚以内はfalse")
