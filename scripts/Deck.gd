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
	if index != -1 and index != 8:
		cards.remove_at(index)
		cards.push_back(card_number)
		deck_changed.emit()


# 能力3: 任意の1枚を真ん中（5番目）へ移動
# 発動カード除外後の8枚の状態で、9枚の真ん中の位置（index 3）に挿入
func ability_move_to_middle(card_number: int) -> void:
	var index = cards.find(card_number)
	if index != -1 and index != MIDDLE_INDEX_8CARDS:
		cards.remove_at(index)
		# 9枚の真ん中の位置（発動カード除外後はindex 3）に挿入
		cards.insert(MIDDLE_INDEX_8CARDS, card_number)
		deck_changed.emit()


# 能力4: 上から2枚をまとめて一番下へ移動（順序を保つ）
func ability_move_top2_to_bottom() -> void:
	var first = cards.pop_front()
	var second = cards.pop_front()
	cards.push_back(first)
	cards.push_back(second)
	deck_changed.emit()


# 能力5: 真ん中（5番目）のカードを一番上へ移動
# 発動カード除外後の8枚の状態で、9枚の真ん中の位置（index 3）のカードを移動
func ability_middle_to_top() -> void:
	var middle_card = cards[MIDDLE_INDEX_8CARDS]
	cards.remove_at(MIDDLE_INDEX_8CARDS)
	cards.insert(0, middle_card)
	deck_changed.emit()


# 能力6: 上から3枚をまとめて一番下へ移動（順序を保つ）
func ability_move_top3_to_bottom() -> void:
	var first = cards.pop_front()
	var second = cards.pop_front()
	var third = cards.pop_front()
	cards.push_back(first)
	cards.push_back(second)
	cards.push_back(third)
	deck_changed.emit()


# 能力7: 一番下のカードを真ん中（5番目）へ移動
# 発動カード除外後の8枚の状態で、9枚の真ん中の位置（index 3）に挿入
func ability_bottom_to_middle() -> void:
	var bottom_card = cards.pop_back()
	cards.insert(MIDDLE_INDEX_8CARDS, bottom_card)
	deck_changed.emit()


# 能力8: 次のカードの数字をXとして、上からX枚をまとめて一番下へ移動
func ability_ref_topX_to_bottom() -> void:
	var x = get_next_card()  # 次のカードの数字
	var moved_cards: Array[int] = []

	# X枚を取り出す
	for i in range(x):
		if cards.size() > 0:
			moved_cards.append(cards.pop_front())

	# 順序を保って一番下に追加
	for card in moved_cards:
		cards.push_back(card)

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
# target_card: 対象選択が必要な能力で使用
# target_card2: 能力9で2枚目の対象として使用
func use_ability(card_number: int, target_card: int = -1, target_card2: int = -1) -> bool:
	match card_number:
		1:
			if target_card == -1:
				return false
			ability_move_to_top(target_card)
		2:
			if target_card == -1:
				return false
			ability_move_to_bottom(target_card)
		3:
			if target_card == -1:
				return false
			ability_move_to_middle(target_card)
		4:
			ability_move_top2_to_bottom()
		5:
			ability_middle_to_top()
		6:
			ability_move_top3_to_bottom()
		7:
			ability_bottom_to_middle()
		8:
			ability_ref_topX_to_bottom()
		9:
			if target_card == -1 or target_card2 == -1:
				return false
			return ability_sum9_to_bottom(target_card, target_card2)
	return true


# デバッグ用: 山札の状態を表示
func print_deck() -> void:
	print("山札: ", cards)
	print("一番上: ", get_top_card(), " / 真ん中: ", get_middle_card(), " / 一番下: ", get_bottom_card())
