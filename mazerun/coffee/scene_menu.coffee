class Pipe
    constructor: (color) ->
        @color = color
        rpoint = [Math.random() * constants.SCREEN_WIDTH,
                  Math.random() * constants.SCREEN_HEIGHT]
        @pointlist = [rpoint]
        @current = rpoint
        @idir = random_choice(DIRECTIONS)
        @speed = 1 + 1.5 * Math.random()
        @width = constants.PLAYER_LINE_THICKNESS
        @dead = false

    update: ->
        # don't run these forever if the user is just chillin on the menu screen
        return if @dead
        # 10% chance of changing direction
        if Math.random() <= 0.02
            idx = (4 + (DIRECTIONS.indexOf(@idir) + random_choice([-1, 1]))) % 4
            @idir = DIRECTIONS[idx]
            @pointlist.push(@current)
            # Once we've had enough turns, let's start removing first points
            if @pointlist.length > 50
                @dead = true

        dir = DIRS[@idir]
        @current = [@current[0] + @speed * dir[0],
                    @current[1] + @speed * dir[1]]

    draw: (p5) ->
        p5.stroke(@color...)
        p5.strokeWeight(4)
        draw_lines_from(p5, @pointlist, @current)

class MenuScene extends Scene
    load: (p5) ->
        @options = [
            ['Continue', => @continue_game()],
            ['Easy', => @start_game(EASY)],
            ['Medium', => @start_game(MEDIUM)],
            ['Hard', => @start_game(HARD)],
            ['Impossibru!', => @start_game(IMPOSSIBRU)],
            ['Derp', => @start_game(DERP)]
        ]
        @num_pipes = 50
        @font = p5.loadFont("arial")

    setup: ->
        @current_option = null
        @game_running = @manager.get_state('main', 'running')
        @pipes = (new Pipe(random_color()) for _ in [1..@num_pipes])
        return

    render: (p5) ->
        p5.background(0)
        i = 0
        p5.strokeCap(p5.SQUARE);
        for pipe in @pipes
            i += 1
            pipe.update()
            pipe.draw(p5)

        # Semi-transparent overlay
        p5.fill(0, 192)
        p5.noStroke()
        p5.rect(0, 0, constants.SCREEN_WIDTH, constants.SCREEN_HEIGHT)
        @render_options(p5)

    render_options: (p5) ->
        [x, y] = [30, 20]
        options = _.filter(@options, (option) => option[0] != 'Continue' or @game_running)
        p5.fill(255, 128)
        menuwidth = 300
        menuheight = options.length * 50 + 10
        ox = constants.SCREEN_WIDTH/2 - menuwidth/2
        oy = constants.SCREEN_HEIGHT/2 - menuheight/2
        p5.rect(ox, oy, menuwidth, menuheight)
        p5.textFont(@font, 32)
        scene = @
        _.each(options, (option, index) ->
            [name, func, show] = option
            rect = [ox + x - 10, oy + y - 10, 260, 40]
            active = point_in_rect([p5.mouseX, p5.mouseY], rect)
            if active
                scene.current_option = func
                p5.fill(192, 128)
            else
                p5.fill(255, 128)
            p5.rect(rect...)
            p5.fill(225)
            p5.text(name, ox + x + 1, oy + y + 20 + 1)
            p5.fill(64)
            p5.text(name, ox + x, oy + y + 20)
            y += 50
        )

    keypress: (letter) ->
        if letter == 'q'
            @manager.switch_scene('main')

    start_game: (difficulty) ->
        @manager.switch_scene('main', difficulty)

    continue_game: ->
        @manager.switch_scene('main')

    mouseclick: ->
        if @current_option
            @current_option()
