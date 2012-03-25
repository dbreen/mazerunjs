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
