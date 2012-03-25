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
