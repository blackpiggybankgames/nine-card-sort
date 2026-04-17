extends GutTest

# Deck.is_cyclic_sorted() の勝利判定テスト

var deck: Deck

func before_each() -> void:
	deck = Deck.new()
	add_child_autofree(deck)

func test_sorted_standard() -> void:
	deck.cards.assign([1, 2, 3, 4, 5, 6, 7, 8, 9])
	assert_true(deck.is_cyclic_sorted(), "標準順 [1..9] はtrue")

func test_sorted_cyclic_from_2() -> void:
	deck.cards.assign([2, 3, 4, 5, 6, 7, 8, 9, 1])
	assert_true(deck.is_cyclic_sorted(), "2始まりの循環ソートはtrue")

func test_sorted_cyclic_from_5() -> void:
	deck.cards.assign([5, 6, 7, 8, 9, 1, 2, 3, 4])
	assert_true(deck.is_cyclic_sorted(), "5始まりの循環ソートはtrue")

func test_sorted_cyclic_from_9() -> void:
	deck.cards.assign([9, 1, 2, 3, 4, 5, 6, 7, 8])
	assert_true(deck.is_cyclic_sorted(), "9始まりの循環ソートはtrue")

func test_not_sorted_random() -> void:
	deck.cards.assign([3, 7, 1, 5, 9, 2, 8, 4, 6])
	assert_false(deck.is_cyclic_sorted(), "バラバラはfalse")

func test_not_sorted_off_by_one() -> void:
	# 8と9だけ逆
	deck.cards.assign([1, 2, 3, 4, 5, 6, 7, 9, 8])
	assert_false(deck.is_cyclic_sorted(), "1枚だけ違うとfalse")
