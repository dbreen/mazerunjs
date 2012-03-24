constants = {
    PLAYER_SPEED: 2,
    PLAYER_LINE_THICKNESS: 3,
    PLAYER_LINE_COLOR: [0, 255, 0],
    SCREEN_WIDTH: 800,
    SCREEN_HEIGHT: 600,
    WALL_THICKNESS: 3,
    START_COLOR: [0, 255, 0, 127],
    END_COLOR: [255, 0, 0, 127],
    POINT_MARKER_WIDTH: 16
}

random_choice = (array) ->
    array[Math.floor(Math.random() * array.length)]

random_color = () ->
    [Math.random() * 255, Math.random() * 255, Math.random() * 255]

WIDTHS = {
  'DERP': 128, 'EASY': 48, 'MEDIUM': 32, 'HARD': 24, 'IMPOSSIBRU': 16,
}
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
        console.log("change dir " + dir)
        dir = @dir_keys[dir]
        if dir != @dir
            @dir = dir
            @path.push([@x, @y])
        console.log(@path, @dir)

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
        @wallwidth = WIDTHS[difficulty]
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
        if @ticks % 32 == 0
            @wall_color = _.map(@wall_color, (c) -> c + 50*(0.5 - p5.noise(c)))
        p5.background @.wall_color..., 32
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
    maze = new Maze(768, 576, 'MEDIUM')
    begin = (p5) ->
        p5.setup = () ->
            console.log('Setup')
            p5.size 800, 600
            p5.frameRate(30)

        p5.draw = () ->
            console.log('Draw...')
            maze.player.update()
            maze.render p5

    $(document).keypress( (e) ->
        console.log('keypress ' + e.keyCode)
        if e.keyCode == 97
            maze.player.change_dir('left')
        else if e.keyCode == 119
            maze.player.change_dir('up')
        else if e.keyCode == 100
            maze.player.change_dir('right')
        else if e.keyCode == 115
            maze.player.change_dir('down')
    )

    canvas = document.getElementById "processing"
    processing = new Processing(canvas, begin)
