
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
