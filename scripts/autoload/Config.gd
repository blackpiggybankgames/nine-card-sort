extends Node

var balance: Dictionary
var config_path = "res://config/game_balance.json"

func _ready():
    load_config()
    if OS.is_debug_build():
        print("Config loaded. Press 'R' to reload during development.")

func load_config():
    var file = FileAccess.open(config_path, FileAccess.READ)
    if file:
        balance = JSON.parse_string(file.get_as_text())
        file.close()
        print("Configuration loaded successfully")
    else:
        push_error("Failed to load configuration file: " + config_path)

func _input(event):
    # 開発中のみ: Rキーで設定をリロード
    if OS.is_debug_build() and event is InputEventKey:
        if event.pressed and event.keycode == KEY_R:
            load_config()
            get_tree().call_group("reloadable", "on_config_reloaded")
            print("Configuration reloaded!")


# 能力名を取得
func get_ability_name(card: int) -> String:
    var abilities = balance.get("abilities", {})
    var ability = abilities.get(str(card), {})
    return ability.get("name", "")


# 能力の説明を取得
func get_ability_description(card: int) -> String:
    var abilities = balance.get("abilities", {})
    var ability = abilities.get(str(card), {})
    return ability.get("description", "")


# シェア用ゲームURLを取得（デバッグ時はdraftURL）
func get_share_url(is_debug: bool = false) -> String:
    var share = balance.get("share", {})
    if is_debug:
        return share.get("game_url_debug", "")
    return share.get("game_url", "")


# シェア用ハッシュタグを取得
func get_share_hashtag() -> String:
    var share = balance.get("share", {})
    return share.get("hashtag", "#NineCardSort")


# アンケートURLを取得（デバッグ時はsurvey_url_debug）
func get_survey_url(is_debug: bool = false) -> String:
    var share = balance.get("share", {})
    if is_debug:
        return share.get("survey_url_debug", "https://google.com")
    return share.get("survey_url", "https://google.com")
