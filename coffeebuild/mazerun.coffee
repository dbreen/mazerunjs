constants = {
    PLAYER_SPEED: 2
    PLAYER_LINE_THICKNESS: 3
    PLAYER_LINE_COLOR: [0, 255, 0]

    SCREEN_WIDTH: 800
    SCREEN_HEIGHT: 600
    FRAMERATE: 30

    MAZE_WIDTH: 768
    MAZE_HEIGHT: 576
    WALL_THICKNESS: 3
    START_COLOR: [0, 128, 0]
    END_COLOR: [128, 0, 0]
    POINT_MARKER_WIDTH: 16

    keys: {
        ESCAPE: 27
        LEFT: 37
        RIGHT: 39
        UP: 38
        DOWN: 40
        SHIFT: 16
    }

    LOSE_PHRASES: ["Dont hit walls!", "You're not very good at this", "NOPE", "So close! (maybe)"]
    WIN_PHRASES: ["That's how it's done!", "Impressive!", "WINNING!", "AWWW YYYYEAAHHH!!"]
}

[DERP, EASY, MEDIUM, HARD, IMPOSSIBRU] = [0..4]
DIFFICULTY_WIDTHS = [
    64, 48, 32, 24, 16
]
DIRECTIONS = [LEFT, TOP, RIGHT, DOWN] = [0..3]
DIRS = [[-1, 0], [0, -1], [1, 0], [0, 1]]

class Player
    constructor: (pos, dir) ->
        @init_pos = pos
        @init_dir = @dir = dir
        [@x, @y] = pos
        @path = [pos]
        @speed = constants.PLAYER_SPEED
        @last_path = null
        @dir_keys = {'left': DIRS[LEFT], 'up': DIRS[TOP], 'right': DIRS[RIGHT], 'down': DIRS[DOWN]}
        @speedboost = false

    update: ->
        speed = @speed * if @speedboost then 2 else 1
        @x += @dir[0] * speed
        @y += @dir[1] * speed

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

    set_last_path: ->
        # save the last attempt's path for reference and make sure ot add the latest position
        @last_path = @path
        @last_path.push([@x, @y])

    reset: ->
        @dir = @init_dir
        @set_last_path()
        @path = [@init_pos]
        [@x, @y] = @init_pos

class Particle
    constructor: (@pos, @vel, @color) ->
        @alpha = 255

    update: ->
        # If alive return true
        @pos[0] += @vel[0]
        @pos[1] += @vel[1]
        @alpha -= 3
        # While still visible, we're alive
        return @alpha > 0

    render: (p5) ->
        p5.set(@pos[0], @pos[1], p5.color(@color..., @alpha))
        return

class Marker
    constructor: (@maze, @position, @color, @radius) ->
        @exploding = false
        @done_exploding = false
        @p5 = @maze.p5

    explode: ->
        @exploding = true
        center = @maze.grid_to_screen(@position)
        @particles = []
        for i in [0...360]
            factor = 0.5 + 5 * Math.random()
            vx = Math.sin(i / 360 * Math.PI * 2) * factor
            vy = Math.cos(i / 360 * Math.PI * 2) * factor
            @particles.push(new Particle([center[0], center[1]], [vx, vy], @color))
        return

    do_explode: ->
        any_alive = false
        for particle in @particles
            alive = particle.update()
            if alive
                any_alive = true
                particle.render(@p5)
        if not any_alive
            @done_exploding = true
        return

    render: ->
        if @exploding
            if not @done_exploding
                @do_explode()
        @p5.noStroke()
        @p5.fill(@color..., if @exploding then 32 else 255)
        [x, y] = @maze.grid_to_screen(@position)
        @p5.ellipse(x, y, @radius, @radius)
        return

class Maze
    constructor: (@p5, @width, @height, difficulty) ->
        @DEBUG = false
        @ticks = 0
        @wallwidth = DIFFICULTY_WIDTHS[difficulty]
        @player_width = constants.PLAYER_LINE_THICKNESS
        @screen_offsets = [(constants.SCREEN_WIDTH - width) / 2,
                           (constants.SCREEN_HEIGHT - height) / 2]
        @gridsize = [width / @wallwidth, height / @wallwidth]
        # grid represents walls - True is a wall, left, top, right, down
        @grid = (([true, true, true, true] for y in [1..@gridsize[1]]) for x in [1..@gridsize[0]])

        # configure some defaults for this specific maze
        @wall_color = random_color()
        @player_color = _.map(@wall_color, (rgbv) -> 255 - rgbv)
        @player_alpha = 255
        corners = [[0, 0], [0, @gridsize[1] - 1], [@gridsize[0] - 1, 0], [@gridsize[0] - 1, @gridsize[1] - 1]]
        @start = random_choice(corners)
        while true
            @end = random_choice(corners)
            if @end != @start
                break

        # we will set this when generating the solution
        @start_dir = null
        @make_solution()
        @player = new Player(@grid_to_screen(@start), @start_dir)
        @start_marker = new Marker(@, @start, constants.START_COLOR, constants.POINT_MARKER_WIDTH)
        ####### DEBUG - to have end marker right next to start:
        ## @end = [@start[0]+@start_dir[0], @start[1]+@start_dir[1]]
        @end_marker = new Marker(@, @end, constants.END_COLOR, constants.POINT_MARKER_WIDTH)

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
        # Find all x, y pairs in the up/down right/left directions that are still
        # within the bounds of the grid. Return the directions towards each neighbor
        neighbors = []
        for idir in DIRECTIONS
            dir = DIRS[idir]
            [nx, ny] = [x + dir[0], y + dir[1]]
            if @gridsize[0] > nx >= 0 <= ny < @gridsize[1]
                neighbors.push(idir)
        return neighbors

    render: ->
        @ticks += 1
        if @winning
            @player_width += 2
            @player_alpha -= 10
        # warp the wall and background colors... ehhh not great
        #if @ticks % 2 == 0
        #    @wall_color = _.map(@wall_color, (c) -> (Math.random() - 0.5) * 20 + c)
        @p5.background(255)
        @p5.noStroke()
        @p5.fill(@wall_color..., 32)
        @p5.rect(0, 0, constants.SCREEN_WIDTH, constants.SCREEN_HEIGHT)

        # We don't want rounded edges on our lines
        @p5.strokeCap(@p5.SQUARE);
        size = @wallwidth
        @p5.fill(127, 127, 127)
        @p5.strokeWeight(constants.WALL_THICKNESS)
        _.each(@grid, (row, x) =>
            _.each(row, (walls, y) =>
                [dx, dy] = [x * size + @screen_offsets[0], y * size + @screen_offsets[1]]
                if @DEBUG
                    @p5.noStroke()
                    @p5.fill(@wall_color..., 64)
                    @p5.rect(dx+@wallwidth/2, dy+@wallwidth/2, size-8, size-8)
                @p5.stroke(@wall_color...)
                [left, top, right, bottom] = walls
                if left
                    @p5.line(dx, dy, dx, dy+size, constants.WALL_THICKNESS)
                if top
                    @p5.line(dx, dy, dx+size, dy, constants.WALL_THICKNESS)
                if right
                    @p5.line(dx+size, dy, dx+size, dy+size, constants.WALL_THICKNESS)
                if bottom
                    @p5.line(dx, dy+size, dx+size, dy+size, constants.WALL_THICKNESS)
            )
        )
        @draw_player()
        @start_marker.render()
        @end_marker.render()

    draw_player: ->
        @p5.stroke(@player_color..., @player_alpha)
        @p5.strokeWeight(@player_width);
        draw_lines(@p5, @player.get_points())
        if @player.last_path
            @p5.strokeWeight(constants.PLAYER_LINE_THICKNESS)
            @p5.stroke(@player_color..., 32)
            draw_lines(@p5, @player.last_path)
        return

    completed: ->
        @winning = true
        @player.set_last_path()
        @start_marker.explode()
        @end_marker.explode()

    grid_to_screen: (pos) ->
        # Convert grid coordinates to screen coordinates
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

    mouseclick: (x, y) ->
    mouseup: (x, y) ->
    mousedown: (x, y) ->
    mousemove: (x, y) ->

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

    mouseclick: (x, y) ->
        @active_scene.mouseclick(x, y)

    mouseup: (x, y) ->
        @active_scene.mouseup(x, y)

    mousedown: (x, y) ->
        @active_scene.mousedown(x, y)

    mousemove: (x, y) ->
        @active_scene.mousemove(x, y)
class DesignerScene extends Scene
    load: (p5) ->
        @mouse_down = false

    setup: (grid) ->
        [@x, @y] = [24, 18]
        if grid
            @grid = grid
        else
            @grid = ((false for y in [0...@y]) for xy in [0...@x])
        @gridsize = 32
        [@offsetx, @offsety] = [13, 15]
        console.log(@grid)

    render: (p5) ->
        p5.background(255)
        p5.stroke(255, 255, 255)
        _.each(@grid, (row, x) =>
            _.each(row, (val, y) =>
                if val
                    p5.fill(128)
                else
                    p5.fill(0)
                p5.rect(@offsetx + @gridsize*x, @offsety + @gridsize*y, @gridsize, @gridsize)
            )
        )

    get_grid_coords: (x, y) ->
        gridx = Math.floor((x - @offsetx) / @gridsize)
        gridy = Math.floor((y - @offsety) / @gridsize)
        if 0 <= gridx < @x and 0 <= gridy < @y
            return [gridx, gridy]
        return null

    toggle_grid: (x, y) ->
        coords = @get_grid_coords(x, y)
        return if not coords
        @grid[coords[0]][coords[1]] = @toggle_on

    mouseclick: (x, y) ->
        @toggle_grid(x, y)

    mousedown: (x, y) ->
        coords = @get_grid_coords(x, y)
        if coords
            @toggle_on = not @grid[coords[0]][coords[1]]
        @mouse_down = true

    mouseup: (x, y) ->
        console.log('up')
        @mouse_down = false

    mousemove: (x, y) ->
        if @mouse_down
            @toggle_grid(x, y, true)
class MazeScene extends Scene
    load: (@p5) ->
        @set_state('running', true)
        @font = p5.loadFont("arial")

    setup: (difficulty) ->
        if difficulty? or not @maze
            @maze = new Maze(@p5, constants.MAZE_WIDTH, constants.MAZE_HEIGHT, difficulty)
            @reset_ticks()
            @lose_match_color = @p5.color(@maze.wall_color...)
            @win_match_color = @p5.color(constants.END_COLOR...)
            @set_state('status', 'starting')
        if @get_state('status') != 'dead'
            @set_state('status', 'starting')

    reset_ticks: ->
        @starting_ticks = 3 * (60 / (60 / constants.FRAMERATE)) # 3 seconds

    render: (p5) ->
        @maze.render(p5)
        status = @get_state('status')
        switch status
            when 'dead'
                p5.fill(0, 128)
                p5.textFont(@font, 64)
                center_text(p5, @dead_text)
                p5.textSize(32)
                center_text(p5, "Press spacebar to restart", 100)
                center_text(p5, "Escape for menu", 150)
                return
            when 'win'
                p5.fill(0, 128)
                p5.textFont(@font, 64)
                center_text(p5, @win_text)
                return
            when 'playing'
                @maze.player.update()
                curpos = @maze.player.get_current()
                cur_pixel = p5.get(curpos[0], curpos[1])
                if cur_pixel == @lose_match_color and not @maze.DEBUG
                    @set_state('status', 'dead')
                    @dead_text = random_choice(constants.LOSE_PHRASES)
                else if cur_pixel == @win_match_color
                    @maze.completed()
                    @set_state('status', 'win')
                    @win_text = random_choice(constants.WIN_PHRASES)
            when 'starting'
                @do_starting(p5)
                return

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

    keypress: (letter, event_type) ->
        switch event_type
            when 'keypress'
                switch letter
                    when 'a' then @maze.player.change_dir('left')
                    when 'w' then @maze.player.change_dir('up')
                    when 'd' then @maze.player.change_dir('right')
                    when 's' then @maze.player.change_dir('down')
                    when ' '
                        if @get_state('status') == 'dead'
                            @reset_ticks()
                            @maze.player.reset()
                            @set_state('status', 'starting')
                    when 'q' then @maze.DEBUG = not @maze.DEBUG
            when 'keydown'
                switch letter
                    when constants.keys.LEFT then @maze.player.change_dir('left')
                    when constants.keys.UP then @maze.player.change_dir('up')
                    when constants.keys.RIGHT then @maze.player.change_dir('right')
                    when constants.keys.DOWN then @maze.player.change_dir('down')
                    when constants.keys.ESCAPE then @manager.switch_scene('menu')
                    when constants.keys.SHIFT then @maze.player.speedboost = true
            when 'keyup'
                switch letter
                    when constants.keys.SHIFT then @maze.player.speedboost = false
class Pipe
    constructor: (@color) ->
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

center_text = (p5, text, y_offset) ->
    # Center the text horizontally based on size text will be, center
    # vertically plus y_offset (negative to be higher)
    y = constants.SCREEN_HEIGHT/2 + (y_offset or 0)
    width = p5.textWidth(text)
    p5.text(text, constants.SCREEN_WIDTH/2 - width/2, y)
