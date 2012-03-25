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
