
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

    reset: ->
        @dir = @init_dir
        # save the last attempt's path for reference and make sure ot add the latest position
        @last_path = @path
        @last_path.push([@x, @y])
        @path = [@init_pos]
        [@x, @y] = @init_pos

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
        @ticks += 1
        # warp the background color... doesnt work that well but it does turn white eventually
        #if @ticks % 32 == 0
        #    @wall_color = _.map(@wall_color, (c) -> c + 50*(0.5 - p5.noise(c)))
        p5.background(255)
        p5.noStroke()
        p5.fill(@.wall_color..., 32)
        p5.rect(0, 0, constants.SCREEN_WIDTH, constants.SCREEN_HEIGHT)

        # We don't want rounded edges on our lines
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
                            p5.rect(dx+8, dy+8, size-16, size-16)
                        [left, top, right, bottom] = walls
                        if left
                            p5.line(dx, dy, dx, dy+size, constants.WALL_THICKNESS)
                        if top
                            p5.line(dx, dy, dx+size, dy, constants.WALL_THICKNESS)
                        if right
                            p5.line(dx+size, dy, dx+size, dy+size, constants.WALL_THICKNESS)
                        if bottom
                            p5.line(dx, dy+size, dx+size, dy+size, constants.WALL_THICKNESS)
                )
        )
        @draw_marker(p5, @start, constants.START_COLOR, constants.POINT_MARKER_WIDTH)
        @draw_marker(p5, @end, constants.END_COLOR, constants.POINT_MARKER_WIDTH)
        @draw_player(p5)

    draw_marker: (p5, point, color, radius) ->
        p5.noStroke()
        p5.fill(color...)
        [x, y] = @grid_to_screen(point)
        p5.ellipse(x, y, radius, radius)

    draw_player: (p5) ->
        p5.stroke(@player_color...)
        p5.strokeWeight(constants.PLAYER_LINE_THICKNESS);
        points = @player.get_points()
        for i in [1..(points.length-1)]
            p = [points[i-1][0], points[i-1][1], points[i][0], points[i][1]]
            p5.line(p...)
        if @player.last_path
            p5.stroke(@player_color..., 32)
            draw_lines(p5, @player.last_path)
        return

    grid_to_screen: (pos) ->
        """Convert grid coordinates to screen coordinates"""
        ww = @wallwidth
        return [(pos[0] + 1) * ww - ww / 2 + constants.WALL_THICKNESS / 2 + @screen_offsets[0],
            (pos[1] + 1) * ww - ww / 2 + constants.WALL_THICKNESS / 2 + @screen_offsets[1]]
