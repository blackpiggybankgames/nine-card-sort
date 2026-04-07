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


# 真ん中のカードを取得（9枚の状態用、index 4）
func get_middle_card() -> int:
	return cards[4]


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

# 能力1（能力E）: 数値±1のカードと位置を入れ替える
# source_card と target_card の数値差が1であること
func ability_swap_adjacent_value(source_card: int, target_card: int) -> bool:
	if abs(source_card - target_card) != 1:
		return false
	var idx1 = cards.find(source_card)
	var idx2 = cards.find(target_card)
	if idx1 == -1 or idx2 == -1:
		return false
	cards[idx1] = target_card
	cards[idx2] = source_card
	deck_changed.emit()
	return true


# 能力2（能力I）: 隣接3枚を順繰りに移動（左端→右端）
# top_card: 3枚グループの一番上のカード（index 0〜5 が有効）
# 例: [A,B,C,D,E] で B を指定 → [A,C,D,B,E]
func ability_rotate_three(top_card: int) -> bool:
	var index = cards.find(top_card)
	# 後ろに2枚必要なので index は cards.size()-3 以内
	if index == -1 or index > cards.size() - 3:
		return false
	var a = cards[index]
	var b = cards[index + 1]
	var c = cards[index + 2]
	cards[index] = b
	cards[index + 1] = c
	cards[index + 2] = a
	deck_changed.emit()
	return true


# 能力3（能力D）: 山札全体（8枚）を逆順にする
func ability_reverse_all() -> void:
	cards.reverse()
	deck_changed.emit()


# 能力4（能力A）: 選択カードの両隣を入れ替え、選択カードを一番下へ移動
# 端（index 0 と index 7）は選択不可
func ability_displace(selected_card: int) -> bool:
	var index = cards.find(selected_card)
	if index == -1 or index == 0 or index == cards.size() - 1:
		return false
	# 両隣を入れ替え
	var left_card = cards[index - 1]
	var right_card = cards[index + 1]
	cards[index - 1] = right_card
	cards[index + 1] = left_card
	# 選択カードを一番下へ
	cards.remove_at(index)
	cards.push_back(selected_card)
	deck_changed.emit()
	return true


# 能力5（能力H）: 上4枚と下4枚を入れ替える（各ブロック内の順序は維持）
# 例: [A,B,C,D,E,F,G,H] → [E,F,G,H,A,B,C,D]
func ability_swap_halves() -> void:
	if cards.size() != 8:
		return
	var top4 = [cards[0], cards[1], cards[2], cards[3]]
	var bottom4 = [cards[4], cards[5], cards[6], cards[7]]
	cards[0] = bottom4[0]
	cards[1] = bottom4[1]
	cards[2] = bottom4[2]
	cards[3] = bottom4[3]
	cards[4] = top4[0]
	cards[5] = top4[1]
	cards[6] = top4[2]
	cards[7] = top4[3]
	deck_changed.emit()


# 能力6（能力G）: 隣接2枚×2セットを一番下へ送る（インデックスが低い方のセットが先）
# pair1_top_card, pair2_top_card: 各セットの上側カード
func ability_send_pairs_to_bottom(pair1_top_card: int, pair2_top_card: int) -> bool:
	var idx1 = cards.find(pair1_top_card)
	var idx2 = cards.find(pair2_top_card)
	if idx1 == -1 or idx2 == -1:
		return false
	# 各セットの2枚目が範囲内か確認
	if idx1 >= cards.size() - 1 or idx2 >= cards.size() - 1:
		return false
	# 重複チェック: 2セットが重ならないこと（隣接もNG）
	if abs(idx1 - idx2) <= 1:
		return false

	# インデックスが低い（上側）のセットを先に送る
	var first_top: int = pair1_top_card if idx1 < idx2 else pair2_top_card
	var second_top: int = pair2_top_card if idx1 < idx2 else pair1_top_card

	# 1セット目を一番下へ
	var fi = cards.find(first_top)
	var fc1 = cards[fi]
	var fc2 = cards[fi + 1]
	cards.remove_at(fi + 1)
	cards.remove_at(fi)
	cards.push_back(fc1)
	cards.push_back(fc2)

	# 2セット目を一番下へ（インデックスが変わっているので再検索）
	var si = cards.find(second_top)
	var sc1 = cards[si]
	var sc2 = cards[si + 1]
	cards.remove_at(si + 1)
	cards.remove_at(si)
	cards.push_back(sc1)
	cards.push_back(sc2)

	deck_changed.emit()
	return true


# 能力7（能力B）: 指定位置に3枚ブロックを差し込む
# gap_right_card: 挿入ギャップの右側カード（ブロックはこのカードの直前に挿入）
# block_center_card: 3枚ブロックの中央カード（差し込み先の隣のカードは選択不可）
func ability_insert_block(gap_right_card: int, block_center_card: int) -> bool:
	var i = cards.find(gap_right_card)    # 挿入位置（このカードの前に挿入）
	var j = cards.find(block_center_card)  # ブロック中央

	if i == -1 or j == -1:
		return false
	# 先頭の前への挿入はギャップが存在しないのでNG（i >= 1 が必要）
	if i == 0:
		return false
	# ブロック中央は両端不可（前後1枚ずつ必要）
	if j == 0 or j == cards.size() - 1:
		return false
	# 差し込み先に隣接するカード（ギャップ左 = i-1、ギャップ右 = i）は選択不可
	if j == i - 1 or j == i:
		return false

	# ブロック（中央±1の3枚）を抽出
	var block_left = cards[j - 1]
	var block_center = cards[j]
	var block_right = cards[j + 1]

	# ブロックを除去（高いインデックスから削除して位置ずれを防ぐ）
	cards.remove_at(j + 1)
	cards.remove_at(j)
	cards.remove_at(j - 1)

	# gap_right_card の新しいインデックスを取得（除去後にずれる）
	var new_i = cards.find(gap_right_card)
	if new_i == -1:
		return false

	# ブロックを挿入（左から順に）
	cards.insert(new_i, block_right)
	cards.insert(new_i, block_center)
	cards.insert(new_i, block_left)

	deck_changed.emit()
	return true


# 能力8（能力F）裏面: 任意カードを指定カードの直前に移動する
# card_to_move: 移動するカード
# before_card: このカードの直前に挿入する
# ※ 表面時はデッキ操作なし（GameManager がフラグを管理）
func ability_move_before(card_to_move: int, before_card: int) -> bool:
	var move_idx = cards.find(card_to_move)
	if move_idx == -1:
		return false
	cards.remove_at(move_idx)
	var insert_idx = cards.find(before_card)
	if insert_idx == -1:
		# 挿入先が見つからない場合は元に戻す
		cards.insert(move_idx, card_to_move)
		return false
	cards.insert(insert_idx, card_to_move)
	deck_changed.emit()
	return true


# 能力9（能力C）: 隣接2枚とその外側2枚の計4枚を逆順にする
# pair_top_card: 選択した2枚ペアの上側カード
# 例: [A,B,C,D,E] で B-C を選んだ場合 → 外側は A と D → [D,C,B,A,E]
func ability_reverse_four(pair_top_card: int) -> bool:
	var j = cards.find(pair_top_card)  # ペア上側のインデックス
	if j == -1:
		return false
	# 外側4枚が存在する条件: j-1 >= 0 かつ j+2 <= size-1
	if j == 0 or j + 2 > cards.size() - 1:
		return false
	var c0 = cards[j - 1]
	var c1 = cards[j]
	var c2 = cards[j + 1]
	var c3 = cards[j + 2]
	# 4枚を逆順に並べ替え
	cards[j - 1] = c3
	cards[j] = c2
	cards[j + 1] = c1
	cards[j + 2] = c0
	deck_changed.emit()
	return true


# 能力を使用する（カード番号を指定）
# target_card: 1段階目の対象カード
# target_card2: 2段階目の対象カード（2段階選択の能力）
func use_ability(card_number: int, target_card: int = -1, target_card2: int = -1) -> bool:
	match card_number:
		1:  # ±1入れ替え: ソースカードと±1カードの2枚が必要
			if target_card == -1 or target_card2 == -1:
				return false
			return ability_swap_adjacent_value(target_card, target_card2)
		2:  # 3枚順繰り: 3枚グループの先頭カードを指定
			if target_card == -1:
				return false
			return ability_rotate_three(target_card)
		3:  # 全体リバース: 選択不要
			ability_reverse_all()
		4:  # どかす: 選択カードを指定（端以外）
			if target_card == -1:
				return false
			return ability_displace(target_card)
		5:  # 上下入れ替え: 選択不要
			ability_swap_halves()
		6:  # 2セット下送り: 各セットの上側カード2枚が必要
			if target_card == -1 or target_card2 == -1:
				return false
			return ability_send_pairs_to_bottom(target_card, target_card2)
		7:  # 3枚ブロック差し込み: ギャップ右側カードとブロック中央カードが必要
			if target_card == -1 or target_card2 == -1:
				return false
			return ability_insert_block(target_card, target_card2)
		8:  # 上下反転+任意移動
			# 表面（target_card == -1）: デッキ操作なし、GameManagerがフラグをトグル
			if target_card == -1:
				pass  # no-op
			else:
				# 裏面: カードを指定位置へ移動
				if target_card2 == -1:
					return false
				return ability_move_before(target_card, target_card2)
		9:  # 4枚逆順: ペアの上側カードを指定
			if target_card == -1:
				return false
			return ability_reverse_four(target_card)
	return true


# デバッグ用: 山札の状態を表示
func print_deck() -> void:
	print("山札: ", cards)
	print("一番上: ", get_top_card(), " / 真ん中: ", get_middle_card(), " / 一番下: ", get_bottom_card())
