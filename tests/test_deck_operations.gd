extends GutTest

# Deck の基本山札操作テスト

var deck: Deck

func before_each() -> void:
	deck = Deck.new()
	add_child_autofree(deck)

func test_move_top_to_bottom() -> void:
	deck.cards.assign([1, 2, 3, 4, 5, 6, 7, 8, 9])
	deck.move_top_to_bottom()
	assert_eq(deck.cards[0], 2, "2番目だったカードが先頭に")
	assert_eq(deck.cards[8], 1, "先頭だったカードが末尾に")
	assert_eq(deck.cards.size(), 9, "枚数は変わらない")

func test_move_card_to_bottom() -> void:
	deck.cards.assign([1, 2, 3, 4, 5, 6, 7, 8, 9])
	deck.move_card_to_bottom(5)
	assert_eq(deck.cards[8], 5, "指定カードが末尾に")
	assert_false(deck.cards.slice(0, 8).has(5), "元の位置からは消えている")
	assert_eq(deck.cards.size(), 9, "枚数は変わらない")

func test_remove_card_success() -> void:
	deck.cards.assign([1, 2, 3, 4, 5, 6, 7, 8, 9])
	var result = deck.remove_card(5)
	assert_true(result, "存在するカードの削除はtrue")
	assert_eq(deck.cards.size(), 8, "1枚減って8枚になる")
	assert_false(deck.cards.has(5), "削除したカードは山札にない")

func test_remove_card_not_found() -> void:
	deck.cards.assign([1, 2, 3, 4, 5, 6, 7, 8, 9])
	var result = deck.remove_card(10)
	assert_false(result, "存在しないカードの削除はfalse")
	assert_eq(deck.cards.size(), 9, "枚数は変わらない")

func test_add_card_to_bottom() -> void:
	# 8枚状態から1枚追加
	deck.cards.assign([1, 2, 3, 4, 5, 6, 7, 8])
	deck.add_card_to_bottom(9)
	assert_eq(deck.cards.size(), 9, "9枚になる")
	assert_eq(deck.cards[8], 9, "追加カードが末尾に")
