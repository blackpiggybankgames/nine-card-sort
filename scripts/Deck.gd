extends Node
class_name Deck

# 山札を管理するクラス
# index 0 = 一番上、index 8 = 一番下

signal deck_changed  # 山札が変更されたときに発火
signal game_won      # 勝利条件を満たしたときに発火

# 山札の配列（1〜9の数字）
var cards: Array[int] = []

# 勝利条件
const WIN_CONDITION: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9]

# 9枚の真ん中のインデックス（常に5番目 = index 4）
const MIDDLE_INDEX_9CARDS: int = 4

# 発動カード除外後の真ん中のインデックス
# 発動カードは常にindex 0から除外されるので、9枚のindex 4 → 8枚のindex 3
const MIDDLE_INDEX_8CARDS: int = 3


func _ready() -> void:
	# 初期化時にシャッフルして山札を作成
	shuffle_deck()


# 山札をシャッフルする
func shuffle_deck() -> void:
	cards = [1, 2, 3, 4, 5, 6, 7, 8, 9]
	cards.shuffle()
	deck_changed.emit()


# 勝利判定（循環ソートに対応）
# [1,2,3,4,5,6,7,8,9]だけでなく、[2,3,4,5,6,7,8,9,1]や[5,6,7,8,9,1,2,3,4]もクリア
func check_win() -> bool:
	if is_cyclic_sorted():
		game_won.emit()
		return true
	return false


# 循環ソートのチェック
# 各カードの次のカードが+1（9の次は1）になっていればソート済み
func is_cyclic_sorted() -> bool:
	for i in range(cards.size()):
		var current = cards[i]
		var next_index = (i + 1) % cards.size()
		var next_card = cards[next_index]

		# 次のカードが現在+1（9の次は1）かチェック
		var expected_next = current % 9 + 1  # 1→2, 2→3, ..., 9→1
		if next_card != expected_next:
			return false

	return true


# 一番上のカードを取得
func get_top_card() -> int:
	return cards[0]


# 次のカード（一番上の1つ下）を取得
func get_next_card() -> int:
	return cards[1]


# 一番下のカードを取得
func get_bottom_card() -> int:
	return cards[8]


# 真ん中のカードを取得（9枚の状態用）
func get_middle_card() -> int:
	return cards[MIDDLE_INDEX_9CARDS]


# 一番上のカードを一番下に移動（毎手番必ず実行）
func move_top_to_bottom() -> void:
	var top_card = cards.pop_front()
	cards.push_back(top_card)
	deck_changed.emit()
	check_win()


# 指定したカードを一番下に移動（能力発動後に使用）
func move_card_to_bottom(card_number: int) -> void:
	var index = cards.find(card_number)
	if index != -1:
		cards.remove_at(index)
		cards.push_back(card_number)
		deck_changed.emit()
		check_win()


# カードを山札から取り除く（能力発動前に使用）
func remove_card(card_number: int) -> bool:
	var index = cards.find(card_number)
	if index != -1:
		cards.remove_at(index)
		return true
	return false


# カードを一番下に追加する（能力発動後に使用）
func add_card_to_bottom(card_number: int) -> void:
	cards.push_back(card_number)
	deck_changed.emit()
	check_win()


# === 能力の実装 ===
# 注意: 全ての能力は発動カード除外後の8枚に対して適用される

# 能力1: 任意の1枚を一番上へ移動
func ability_move_to_top(card_number: int) -> void:
	var index = cards.find(card_number)
	if index != -1 and index != 0:
		cards.remove_at(index)
		cards.insert(0, card_number)
		deck_changed.emit()


# 能力2: 任意の1枚を一番下へ移動
func ability_move_to_bottom(card_number: int) -> void:
	var index = cards.find(card_number)
	if index != -1 and index != cards.size() - 1:
		cards.remove_at(index)
		cards.push_back(card_number)
		deck_changed.emit()


# 能力3: 選択したカードの両隣を入れ替え、選択カードを一番下へ移動
# 発動カード除外後の8枚の状態で操作
# 例: [A,B,C,D,E,F,G,H] で C を選択 → B と D を入れ替え → [A,D,B,E,F,G,H,C]
# 注意: 端のカード（index 0 と index 7）は両隣がないため選択不可
func ability_swap_neighbors(selected_card: int) -> bool:
	var index = cards.find(selected_card)

	# カードが見つからない、または端の場合は失敗
	if index == -1 or index == 0 or index == cards.size() - 1:
		return false

	# 両隣のカードを入れ替え
	var left_card = cards[index - 1]
	var right_card = cards[index + 1]
	cards[index - 1] = right_card
	cards[index + 1] = left_card

	# 選択したカードを一番下へ移動
	cards.remove_at(index)
	cards.push_back(selected_card)

	deck_changed.emit()
	return true


# 旧能力3: 一番上のカードを真ん中へ移動（削除予定）
func ability_top_to_middle() -> void:
	if cards.size() < 2:
		return
	var top_card = cards.pop_front()
	cards.insert(MIDDLE_INDEX_8CARDS, top_card)
	deck_changed.emit()


# 能力4: 2番目のカードを一番下へ移動
# [A, B, C, D, E, F, G, H] → [A, C, D, E, F, G, H, B]
func ability_drop_second() -> void:
	if cards.size() < 2:
		return
	var second_card = cards[1]
	cards.remove_at(1)
	cards.push_back(second_card)
	deck_changed.emit()


# 能力5: 3番目（index 2）を一番上へ移動
# [A,B,C,D,E,F,G,H] → [C,A,B,D,E,F,G,H]
func ability_third_to_top() -> void:
	if cards.size() < 3:
		return
	var third_card = cards[2]
	cards.remove_at(2)
	cards.insert(0, third_card)
	deck_changed.emit()


# 能力6: 下4枚の順序を逆転させる
# [A,B,C,D,E,F,G,H] → [A,B,C,D,H,G,F,E]
func ability_reverse_bottom4() -> void:
	if cards.size() < 4:
		return
	# 下4枚（index 4〜7）を逆順にする
	var bottom4 = [cards[4], cards[5], cards[6], cards[7]]
	bottom4.reverse()
	cards[4] = bottom4[0]
	cards[5] = bottom4[1]
	cards[6] = bottom4[2]
	cards[7] = bottom4[3]
	deck_changed.emit()


# 能力7: 上4枚と下4枚を入れ替える（各ブロック内の順序は維持）
# [A,B,C,D,E,F,G,H] → [E,F,G,H,A,B,C,D]
func ability_swap_blocks() -> void:
	if cards.size() != 8:
		return
	var top4 = [cards[0], cards[1], cards[2], cards[3]]
	var bottom4 = [cards[4], cards[5], cards[6], cards[7]]
	# 入れ替え
	cards[0] = bottom4[0]
	cards[1] = bottom4[1]
	cards[2] = bottom4[2]
	cards[3] = bottom4[3]
	cards[4] = top4[0]
	cards[5] = top4[1]
	cards[6] = top4[2]
	cards[7] = top4[3]
	deck_changed.emit()


# 能力8: 8枚全体の順序を逆転させる
# [A,B,C,D,E,F,G,H] → [H,G,F,E,D,C,B,A]
func ability_full_reverse() -> void:
	cards.reverse()
	deck_changed.emit()


# === 旧能力（参考用・削除予定） ===
# 以下の関数は互換性のために残していますが、新能力では使用しません

# 旧能力: 任意の1枚を真ん中へ移動（削除予定）
func ability_move_to_middle(card_number: int) -> void:
	var index = cards.find(card_number)
	if index != -1 and index != MIDDLE_INDEX_8CARDS:
		cards.remove_at(index)
		cards.insert(MIDDLE_INDEX_8CARDS, card_number)
		deck_changed.emit()


# 旧能力: 一番下を真ん中へ移動（削除予定）
func ability_bottom_to_middle() -> void:
	var bottom_card = cards.pop_back()
	cards.insert(MIDDLE_INDEX_8CARDS, bottom_card)
	deck_changed.emit()


# 旧能力: 一番下を一番上へ移動（削除予定）
func ability_bottom_to_top() -> void:
	if cards.size() < 2:
		return
	var bottom_card = cards.pop_back()
	cards.insert(0, bottom_card)
	deck_changed.emit()


# 旧能力: 上3枚を1つ回転させる（削除予定）
func ability_cycle_top3() -> void:
	if cards.size() < 3:
		return
	var a = cards[0]
	var b = cards[1]
	var c = cards[2]
	cards[0] = c
	cards[1] = a
	cards[2] = b
	deck_changed.emit()


# 能力9: 足して9になる2枚の組み合わせを一番下へ移動（順序を保つ）
# 選択された2枚を指定して実行
func ability_sum9_to_bottom(card1: int, card2: int) -> bool:
	# 足して9にならない場合は失敗
	if card1 + card2 != 9:
		return false

	var index1 = cards.find(card1)
	var index2 = cards.find(card2)

	if index1 == -1 or index2 == -1:
		return false

	# 順序を保つために、先に上にある方から処理
	var first_card: int
	var second_card: int

	if index1 < index2:
		first_card = card1
		second_card = card2
	else:
		first_card = card2
		second_card = card1

	# 先に上にある方を削除
	cards.remove_at(cards.find(first_card))
	# 次に下にある方を削除（インデックスがずれるので再検索）
	cards.remove_at(cards.find(second_card))

	# 順序を保って一番下に追加
	cards.push_back(first_card)
	cards.push_back(second_card)

	deck_changed.emit()
	return true


# 能力を使用する（カード番号を指定）
# target_card: 対象選択が必要な能力で使用（1, 2, 9）
# target_card2: 能力9で2枚目の対象として使用
func use_ability(card_number: int, target_card: int = -1, target_card2: int = -1) -> bool:
	match card_number:
		1:  # 引き上げ: 任意の1枚を一番上へ
			if target_card == -1:
				return false
			ability_move_to_top(target_card)
		2:  # 押し下げ: 任意の1枚を一番下へ
			if target_card == -1:
				return false
			ability_move_to_bottom(target_card)
		3:  # 隣接入替: 両隣を入れ替え、選択カードを底へ
			if target_card == -1:
				return false
			return ability_swap_neighbors(target_card)
		4:  # 2番目落とし: 2番目のカードを一番下へ
			ability_drop_second()
		5:  # 3番目引き出し: 3番目を一番上へ
			ability_third_to_top()
		6:  # 下半分リバース: 下4枚を逆順
			ability_reverse_bottom4()
		7:  # ブロック入れ替え: 上4枚⇔下4枚
			ability_swap_blocks()
		8:  # フルリバース: 8枚全体を逆順
			ability_full_reverse()
		9:  # 合計送り: 足して9になる2枚を一番下へ
			if target_card == -1 or target_card2 == -1:
				return false
			return ability_sum9_to_bottom(target_card, target_card2)
	return true


# デバッグ用: 山札の状態を表示
func print_deck() -> void:
	print("山札: ", cards)
	print("一番上: ", get_top_card(), " / 真ん中: ", get_middle_card(), " / 一番下: ", get_bottom_card())
