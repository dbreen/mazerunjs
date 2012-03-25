class Scene
    constructor: (manager) ->
        @manager = manager
        @state = {}
        @ran = false

    get_state: (key) ->
        # Scenes can maintain state variables such as "running" etc. that other scenes can access
        return @state[key]

    set_state: (key, val) ->
        @state[key] = val

    load: (p5) ->
        # The first time a scene is switched to, this method is called

    setup: (args...) ->
        # Any time a scene is switched to, this is called. If we are coming back to a scene that's
        # already been shown, first_time will be False"""

    render: (p5) ->
        # Draw the scene to the screen. Called every clock tick

    keypress: (letter, event_type) ->
        return false

    mouseclick: ->

class SceneManager
    constructor: (p5) ->
        @p5 = p5
        @scenes = {}
        @active_scene = null
        @special_keys = _.map(constants.keys, _.identity)

    register_scene: (scene_key, scene_class) ->
        scene = new scene_class(@)
        @scenes[scene_key] = scene

    switch_scene: (scene_key, args...) ->
        scene = @scenes[scene_key]
        if not scene.ran
            scene.load(@p5)
        scene.setup(args...)
        scene.ran = true
        @active_scene = scene

    is_loaded: (scene_key) ->
        return @scenes[scene_key]?

    get_state: (scene_key, key) ->
        if not @is_loaded(scene_key)
            return null
        return @scenes[scene_key].get_state(key)

    run: (p5) ->
        scene = @active_scene
        scene.render(p5)

    keyevent: (event) ->
        charCode = event.which or event.keyCode;
        # We need keyup to track special keys like Escape, but we don't want
        # do double-fire normal keypresses w/ keyup (keypress already does that)
        if event.type in ['keydown', 'keyup']
            if charCode not in @special_keys
                return
            letter = charCode
        else
            letter = String.fromCharCode(charCode)
        @active_scene.keypress(letter, event.type)

    mouseclick: ->
        @active_scene.mouseclick()
