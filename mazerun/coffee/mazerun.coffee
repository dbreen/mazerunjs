$(document).ready ->
    scene_manager = null

    begin = (p5) ->
        p5.setup = () ->
            p5.size constants.SCREEN_WIDTH, constants.SCREEN_HEIGHT
            p5.frameRate(constants.FRAMERATE)
            scene_manager = new SceneManager(p5)
            scene_manager.register_scene('main', MazeScene)
            scene_manager.register_scene('menu', MenuScene)
            scene_manager.register_scene('designer', DesignerScene)
            if design_mode?
                scene_manager.switch_scene('designer')
            else
                scene_manager.switch_scene('menu')

        p5.draw = () ->
            scene_manager.run(p5)

        p5.mouseClicked = ->
            scene_manager.mouseclick(p5.mouseX, p5.mouseY)

        p5.mousePressed = ->
            scene_manager.mousedown(p5.mouseX, p5.mouseY)

        p5.mouseReleased = ->
            scene_manager.mouseup(p5.mouseX, p5.mouseY)

        p5.mouseMoved = ->
            scene_manager.mousemove(p5.mouseX, p5.mouseY)

        p5.mouseDragged = ->
            scene_manager.mousemove(p5.mouseX, p5.mouseY)

    $(document).bind('keypress keyup keydown', (event) -> scene_manager.keyevent(event))

    canvas = document.getElementById "maze"
    processing = new Processing(canvas, begin)
    $('#maze').focus();
