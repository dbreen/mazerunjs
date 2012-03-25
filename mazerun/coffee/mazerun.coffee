$(document).ready ->
    scene_manager = null

    begin = (p5) ->
        p5.setup = () ->
            p5.size constants.SCREEN_WIDTH, constants.SCREEN_HEIGHT
            p5.frameRate(constants.FRAMERATE)
            scene_manager = new SceneManager(p5)
            scene_manager.register_scene('main', MazeScene)
            scene_manager.register_scene('menu', MenuScene)
            scene_manager.switch_scene('menu')

        p5.draw = () ->
            scene_manager.run(p5)

        p5.mouseClicked = ->
            scene_manager.mouseclick()

    $(document).bind('keypress keyup keydown', (event) -> scene_manager.keyevent(event))

    canvas = document.getElementById "maze"
    processing = new Processing(canvas, begin)
    $('#maze').focus();
