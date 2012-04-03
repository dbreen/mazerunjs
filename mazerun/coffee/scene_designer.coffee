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
