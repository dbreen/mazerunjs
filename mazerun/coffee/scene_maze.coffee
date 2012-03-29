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
