extends SceneTree

func _init():
    print("=== Configuration Test ===")
    
    # Configをロード
    var config = load("res://scripts/autoload/Config.gd").new()
    config.load_config()
    
    # 値を確認
    print("Bird jump velocity: ", config.balance.bird.jump_velocity)
    print("Pipe speed: ", config.balance.pipes.speed)
    print("Screen size: ", config.balance.game.screen_width, "x", config.balance.game.screen_height)
    
    print("✅ Configuration test passed")
    quit()
