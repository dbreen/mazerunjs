constants = {
    PLAYER_SPEED: 2,
    PLAYER_LINE_THICKNESS: 3,
    PLAYER_LINE_COLOR: [0, 255, 0],

    SCREEN_WIDTH: 800,
    SCREEN_HEIGHT: 600,
    FRAMERATE: 30,

    MAZE_WIDTH: 768,
    MAZE_HEIGHT: 576,
    WALL_THICKNESS: 3,
    START_COLOR: [0, 128, 0],
    END_COLOR: [128, 0, 0],
    POINT_MARKER_WIDTH: 16,

    keys: {
        ESCAPE: 27,
        LEFT: 37,
        RIGHT: 39,
        UP: 38,
        DOWN: 40
    },
}

[DERP, EASY, MEDIUM, HARD, IMPOSSIBRU] = [0..4]
DIFFICULTY_WIDTHS = [
    64, 48, 32, 24, 16
]
DIRECTIONS = [LEFT, TOP, RIGHT, DOWN] = [0..3]
DIRS = [[-1, 0], [0, -1], [1, 0], [0, 1]]

class Player
    constructor: (pos, dir) ->
        @x = pos[0]
        @y = pos[1]
        @dir = dir
        @speed = constants.PLAYER_SPEED
        @path = [pos]
        @dir_keys = {'left': DIRS[LEFT], 'up': DIRS[TOP], 'right': DIRS[RIGHT], 'down': DIRS[DOWN]}

    update: ->
        @x += @dir[0] * @speed
        @y += @dir[1] * @speed

    change_dir: (dir) ->
        dir = @dir_keys[dir]
        if dir != @dir
            @dir = dir
            @path.push([@x, @y])

    get_points: ->
        points = @path[0..@path.length]
        points.push([@x, @y])
        return points

    get_current: ->
        return [@x, @y]

class Maze
    constructor: (width, height, difficulty) ->
        @DEBUG = false
        @ticks = 0
        # initialize sizes and the grid representing our walls (or lack thereof)
        @width = width
        @height = height
        @wallwidth = DIFFICULTY_WIDTHS[difficulty]
        @screen_offsets = [(constants.SCREEN_WIDTH - width) / 2,
            (constants.SCREEN_HEIGHT - height) / 2]
        @gridsize = [width / @wallwidth, height / @wallwidth]
        # grid represents walls - True is a wall, left, top, right, down
        @grid = (([true, true, true, true] for y in [1..@gridsize[1]]) for x in [1..@gridsize[0]])

        # configure some defaults for this specific maze
        @wall_color = random_color()
        @player_color = _.map(@wall_color, (rgbv) -> 255 - rgbv)
        corners = [[0, 0], [0, @gridsize[1] - 1], [@gridsize[0] - 1, 0], [@gridsize[0] - 1, @gridsize[1] - 1]]
        @start = random_choice(corners)
        @end = random_choice(corners) until @end != @start
        while true
            @end = random_choice(corners)
            if @end != @start
                break
        # we will set this when generating the solution
        @start_dir = null

        @make_solution()

        @player = new Player(@grid_to_screen(@start), @start_dir)

    make_solution: ->
        [x, y] = @start
        stack = []
        visited = 1
        total = @gridsize[0] * @gridsize[1]
        while visited < total
            neighbors = @find_neighbors(x, y)
            unvisited = (dir for dir in neighbors when _.all(@grid[x+DIRS[dir][0]][y+DIRS[dir][1]], _.identity))
            if unvisited.length > 0
                idir = random_choice(unvisited)
                dir = DIRS[idir]
                if not @start_dir
                # this is the direction from the start point that leads to a solution
                    @start_dir = dir
                # break down the wall bordering this neighbor
                @grid[x][y][idir] = false
                [x, y] = [x+dir[0], y+dir[1]]
                # break down the wall of this neighbor towards our position
                @grid[x][y][(idir + 2) % 4] = false
                stack.push([x, y])
                visited += 1
            else
                [x, y] = stack.pop()
        return total

    find_neighbors: (x, y) ->
        """Find all x, y pairs in the up/down right/left directions that are still
                within the bounds of the grid. Return the directions towards each neighbor"""
        neighbors = []
        for idir in DIRECTIONS
            dir = DIRS[idir]
            [nx, ny] = [x + dir[0], y + dir[1]]
            if @gridsize[0] > nx >= 0 <= ny < @gridsize[1]
                neighbors.push(idir)
        return neighbors

    render: (p5) ->
    # We don't want rounded edges on our lines
        @ticks += 1
        # warp the background color... doesnt work that well but it does turn white eventually
        #if @ticks % 32 == 0
        #    @wall_color = _.map(@wall_color, (c) -> c + 50*(0.5 - p5.noise(c)))
        p5.background(255)
        p5.fill(@.wall_color..., 32)
        p5.rect(0, 0, constants.SCREEN_WIDTH, constants.SCREEN_HEIGHT)
        p5.strokeCap(p5.SQUARE);
        size = @wallwidth
        maze = @
        p5.fill(127, 127, 127)
        p5.stroke(maze.wall_color...)
        p5.strokeWeight(constants.WALL_THICKNESS)
        _.each(@grid, (row, x) ->
                _.each(row, (walls, y) ->
                        [dx, dy] = [x * size + maze.screen_offsets[0], y * size + maze.screen_offsets[1]]
                        if maze.DEBUG
                        # draw grids
                            p5.rect(dx+8, dy+8, size-16, size-16)
                        [left, top, right, bottom] = walls
                        #console.log("wall color " + maze.wall_color)
                        #console.log("done wall color")
                        if left
                            p5.line(dx, dy, dx, dy+size, constants.WALL_THICKNESS)
                        if top
                            p5.line(dx, dy, dx+size, dy, constants.WALL_THICKNESS)
                        if right
                            p5.line(dx+size, dy, dx+size, dy+size, constants.WALL_THICKNESS)
                        if bottom
                            p5.line(dx, dy+size, dx+size, dy+size, constants.WALL_THICKNESS)
                    #console.log("maze border" + [x1, y1, x2, y2])
                    #console.log("done maze border")
                )
        )
        @draw_marker(p5, @start, constants.START_COLOR, constants.POINT_MARKER_WIDTH)
        @draw_marker(p5, @end, constants.END_COLOR, constants.POINT_MARKER_WIDTH)
        @draw_player(p5)
    #console.log('Done drawing')

    draw_marker: (p5, point, color, radius) ->
        p5.noStroke()
        p5.fill(color...)
        [x, y] = @grid_to_screen(point)
        #console.log("Marker " + [x, y])
        p5.ellipse(x, y, radius, radius)
    #console.log("Done Marker" )

    draw_player: (p5) ->
        p5.stroke(@player_color...)
        p5.strokeWeight(constants.PLAYER_LINE_THICKNESS);
        points = @player.get_points()
        for i in [1..(points.length-1)]
            p = [points[i-1][0], points[i-1][1], points[i][0], points[i][1]]
            #console.log("player " + p)
            p5.line(p...)
        #console.log("done player")
        return

    grid_to_screen: (pos) ->
        """Convert grid coordinates to screen coordinates"""
        ww = @wallwidth
        return [(pos[0] + 1) * ww - ww / 2 + constants.WALL_THICKNESS / 2 + @screen_offsets[0],
            (pos[1] + 1) * ww - ww / 2 + constants.WALL_THICKNESS / 2 + @screen_offsets[1]]
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

    $(document).bind('keypress keyup', ((event) -> scene_manager.keyevent(event)))

    canvas = document.getElementById "maze"
    processing = new Processing(canvas, begin)
    $('#maze').focus();
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

    keypress: (letter) ->
        return false

    mouseclick: ->

class SceneManager
    constructor: (p5) ->
        @p5 = p5
        @scenes = {}
        @active_scene = null
        @special_keys = [constants.keys.ESCAPE]

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
        if event.type == 'keyup'
            if charCode not in @special_keys
                return
            letter = charCode
        else
            letter = String.fromCharCode(charCode)
        @active_scene.keypress(letter)

    mouseclick: ->
        @active_scene.mouseclick()
class MazeScene extends Scene
    load: (p5) ->
        @p5 = p5
        @set_state('running', true)
        @font = p5.loadFont("arial")

    setup: (difficulty) ->
        if difficulty? or not @maze
            @maze = new Maze(constants.MAZE_WIDTH, constants.MAZE_HEIGHT, difficulty)
            @starting_ticks = 3 * (60 / (60 / constants.FRAMERATE)) # 3 seconds
            @lose_match_color = @p5.color(@maze.wall_color...)
            @win_match_color = @p5.color(constants.END_COLOR...)
            @set_state('status', 'starting')
        if @get_state('status') != 'dead'
            @set_state('status', 'starting')

    render: (p5) ->
        @maze.render(p5)
        status = @get_state('status')
        if status == 'dead'
            p5.fill(0, 128)
            p5.textFont(@font, 64)
            text = "You're dead, bro"
            center_text(p5, 64, text)
        else if status == 'win'
            p5.fill(0, 128)
            p5.textFont(@font, 64)
            text = "WINNING!!!"
            center_text(p5, 64, text)
        else if status == 'playing'
            @maze.player.update()
        else if status == 'starting'
            @do_starting(p5)

        curpos = @maze.player.get_current()
        cur_pixel = p5.get(curpos[0], curpos[1])
        if cur_pixel == @lose_match_color
            @set_state('status', 'dead')
        else if cur_pixel == @win_match_color
            #TODO: there's a 1 in 17 million chance for this to falsely win because
            # maze color matches winning marker color
            @set_state('status', 'win')

    do_starting: (p5) ->
        @starting_ticks -= 1
        if @starting_ticks <= 0
            @set_state('status', 'playing')
        seconds = Math.floor(@starting_ticks / constants.FRAMERATE + 1)
        p5.fill(0, Math.floor(255 / constants.FRAMERATE) * (@starting_ticks % constants.FRAMERATE))
        maxfontmult = Math.floor(constants.SCREEN_HEIGHT / constants.FRAMERATE)
        fontsize = constants.SCREEN_HEIGHT - maxfontmult * (@starting_ticks % constants.FRAMERATE)
        p5.textFont(@font, fontsize)
        fontwidth = p5.textWidth(seconds)
        p5.text(seconds, constants.SCREEN_WIDTH/2 - fontwidth/2, constants.SCREEN_HEIGHT/2 + fontsize/3)

    keypress: (letter) ->
        if letter in ['a', constants.keys.LEFT]
            @maze.player.change_dir('left')
        else if letter in ['w', constants.keys.UP]
            @maze.player.change_dir('up')
        else if letter in ['d', constants.keys.RIGHT]
            @maze.player.change_dir('right')
        else if letter in ['s', constants.keys.DOWN]
            @maze.player.change_dir('down')
        else if letter == constants.keys.ESCAPE
            @manager.switch_scene('menu')
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
random_choice = (array) ->
    array[Math.floor(Math.random() * array.length)]

random_color = () ->
    [Math.random() * 255, Math.random() * 255, Math.random() * 255]

draw_lines_from = (p5, pointlist, current) ->
    len = pointlist.length
    return if len == 0
    if len > 1
        for i in [1..(len-1)]
            p5.line(pointlist[i-1][0], pointlist[i-1][1], pointlist[i][0], pointlist[i][1])
    p5.line(pointlist[len-1][0], pointlist[len-1][1], current[0], current[1])
    return

draw_lines = (p5, pointlist) ->
    len = pointlist.length
    return if len < 2
    for i in [1..(len-1)]
        p5.line(pointlist[i-1][0], pointlist[i-1][1], pointlist[i][0], pointlist[i][1])
    return

point_in_rect = (point, rect) ->
    return point[0] >= rect[0] and point[0] <= rect[0] + rect[2] and
           point[1] >= rect[1] and point[1] <= rect[1] + rect[3]

center_text = (p5, fontsize, text) ->
    width = p5.textWidth(text)
    p5.text(text, constants.SCREEN_WIDTH/2 - width/2, constants.SCREEN_HEIGHT/2 - fontsize/2)
