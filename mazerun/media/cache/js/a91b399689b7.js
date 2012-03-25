(function() {
  var DIRECTIONS, DIRS, DOWN, LEFT, Maze, Player, RIGHT, TOP, WIDTHS, _ref,
    __slice = Array.prototype.slice;

  WIDTHS = {
    'DERP': 128,
    'EASY': 48,
    'MEDIUM': 32,
    'HARD': 24,
    'IMPOSSIBRU': 16
  };

  DIRECTIONS = (_ref = [0, 1, 2, 3], LEFT = _ref[0], TOP = _ref[1], RIGHT = _ref[2], DOWN = _ref[3], _ref);

  DIRS = [[-1, 0], [0, -1], [1, 0], [0, 1]];

  Player = (function() {

    function Player(pos, dir) {
      this.x = pos[0];
      this.y = pos[1];
      this.dir = dir;
      this.speed = constants.PLAYER_SPEED;
      this.path = [pos];
      this.dir_keys = {
        'left': DIRS[LEFT],
        'up': DIRS[TOP],
        'right': DIRS[RIGHT],
        'down': DIRS[DOWN]
      };
    }

    Player.prototype.update = function() {
      this.x += this.dir[0] * this.speed;
      return this.y += this.dir[1] * this.speed;
    };

    Player.prototype.change_dir = function(dir) {
      console.log("change dir " + dir);
      dir = this.dir_keys[dir];
      if (dir !== this.dir) {
        this.dir = dir;
        this.path.push([this.x, this.y]);
      }
      return console.log(this.path, this.dir);
    };

    Player.prototype.get_points = function() {
      var points;
      points = this.path.slice(0, this.path.length + 1 || 9e9);
      points.push([this.x, this.y]);
      return points;
    };

    Player.prototype.get_current = function() {
      return [this.x, this.y];
    };

    return Player;

  })();

  Maze = (function() {

    function Maze(width, height, difficulty) {
      var corners, x, y;
      this.DEBUG = false;
      this.ticks = 0;
      this.width = width;
      this.height = height;
      this.wallwidth = WIDTHS[difficulty];
      this.screen_offsets = [(constants.SCREEN_WIDTH - width) / 2, (constants.SCREEN_HEIGHT - height) / 2];
      this.gridsize = [width / this.wallwidth, height / this.wallwidth];
      this.grid = (function() {
        var _ref2, _results;
        _results = [];
        for (x = 1, _ref2 = this.gridsize[0]; 1 <= _ref2 ? x <= _ref2 : x >= _ref2; 1 <= _ref2 ? x++ : x--) {
          _results.push((function() {
            var _ref3, _results2;
            _results2 = [];
            for (y = 1, _ref3 = this.gridsize[1]; 1 <= _ref3 ? y <= _ref3 : y >= _ref3; 1 <= _ref3 ? y++ : y--) {
              _results2.push([true, true, true, true]);
            }
            return _results2;
          }).call(this));
        }
        return _results;
      }).call(this);
      this.wall_color = random_color();
      this.player_color = _.map(this.wall_color, function(rgbv) {
        return 255 - rgbv;
      });
      corners = [[0, 0], [0, this.gridsize[1] - 1], [this.gridsize[0] - 1, 0], [this.gridsize[0] - 1, this.gridsize[1] - 1]];
      this.start = random_choice(corners);
      while (this.end === this.start) {
        this.end = random_choice(corners);
      }
      while (true) {
        this.end = random_choice(corners);
        if (this.end !== this.start) break;
      }
      this.start_dir = null;
      this.make_solution();
      this.player = new Player(this.grid_to_screen(this.start), this.start_dir);
    }

    Maze.prototype.make_solution = function() {
      var dir, idir, neighbors, stack, total, unvisited, visited, x, y, _ref2, _ref3, _ref4;
      _ref2 = this.start, x = _ref2[0], y = _ref2[1];
      stack = [];
      visited = 1;
      total = this.gridsize[0] * this.gridsize[1];
      while (visited < total) {
        neighbors = this.find_neighbors(x, y);
        unvisited = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = neighbors.length; _i < _len; _i++) {
            dir = neighbors[_i];
            if (_.all(this.grid[x + DIRS[dir][0]][y + DIRS[dir][1]], _.identity)) {
              _results.push(dir);
            }
          }
          return _results;
        }).call(this);
        if (unvisited.length > 0) {
          idir = random_choice(unvisited);
          dir = DIRS[idir];
          if (!this.start_dir) this.start_dir = dir;
          this.grid[x][y][idir] = false;
          _ref3 = [x + dir[0], y + dir[1]], x = _ref3[0], y = _ref3[1];
          this.grid[x][y][(idir + 2) % 4] = false;
          stack.push([x, y]);
          visited += 1;
        } else {
          _ref4 = stack.pop(), x = _ref4[0], y = _ref4[1];
        }
      }
      return total;
    };

    Maze.prototype.find_neighbors = function(x, y) {
      "Find all x, y pairs in the up/down right/left directions that are still\nwithin the bounds of the grid. Return the directions towards each neighbor";
      var dir, idir, neighbors, nx, ny, _i, _len, _ref2;
      neighbors = [];
      for (_i = 0, _len = DIRECTIONS.length; _i < _len; _i++) {
        idir = DIRECTIONS[_i];
        dir = DIRS[idir];
        _ref2 = [x + dir[0], y + dir[1]], nx = _ref2[0], ny = _ref2[1];
        if ((((this.gridsize[0] > nx && nx >= 0) && 0 <= ny) && ny < this.gridsize[1])) {
          neighbors.push(idir);
        }
      }
      return neighbors;
    };

    Maze.prototype.render = function(p5) {
      var maze, size;
      this.ticks += 1;
      if (this.ticks % 32 === 0) {
        this.wall_color = _.map(this.wall_color, function(c) {
          return c + 50 * (0.5 - p5.noise(c));
        });
      }
      p5.background.apply(p5, __slice.call(this.wall_color).concat([32]));
      p5.strokeCap(p5.SQUARE);
      size = this.wallwidth;
      maze = this;
      p5.fill(127, 127, 127);
      p5.stroke.apply(p5, maze.wall_color);
      p5.strokeWeight(constants.WALL_THICKNESS);
      _.each(this.grid, function(row, x) {
        return _.each(row, function(walls, y) {
          var bottom, dx, dy, left, right, top, _ref2;
          _ref2 = [x * size + maze.screen_offsets[0], y * size + maze.screen_offsets[1]], dx = _ref2[0], dy = _ref2[1];
          if (maze.DEBUG) p5.rect(dx + 8, dy + 8, size - 16, size - 16);
          left = walls[0], top = walls[1], right = walls[2], bottom = walls[3];
          if (left) p5.line(dx, dy, dx, dy + size, constants.WALL_THICKNESS);
          if (top) p5.line(dx, dy, dx + size, dy, constants.WALL_THICKNESS);
          if (right) {
            p5.line(dx + size, dy, dx + size, dy + size, constants.WALL_THICKNESS);
          }
          if (bottom) {
            return p5.line(dx, dy + size, dx + size, dy + size, constants.WALL_THICKNESS);
          }
        });
      });
      this.draw_marker(p5, this.start, constants.START_COLOR, constants.POINT_MARKER_WIDTH);
      this.draw_marker(p5, this.end, constants.END_COLOR, constants.POINT_MARKER_WIDTH);
      return this.draw_player(p5);
    };

    Maze.prototype.draw_marker = function(p5, point, color, radius) {
      var x, y, _ref2;
      p5.noStroke();
      p5.fill.apply(p5, color);
      _ref2 = this.grid_to_screen(point), x = _ref2[0], y = _ref2[1];
      return p5.ellipse(x, y, radius, radius);
    };

    Maze.prototype.draw_player = function(p5) {
      var i, p, points, _ref2;
      p5.stroke.apply(p5, this.player_color);
      p5.strokeWeight(constants.PLAYER_LINE_THICKNESS);
      points = this.player.get_points();
      for (i = 1, _ref2 = points.length - 1; 1 <= _ref2 ? i <= _ref2 : i >= _ref2; 1 <= _ref2 ? i++ : i--) {
        p = [points[i - 1][0], points[i - 1][1], points[i][0], points[i][1]];
        p5.line.apply(p5, p);
      }
    };

    Maze.prototype.grid_to_screen = function(pos) {
      "Convert grid coordinates to screen coordinates";
      var ww;
      ww = this.wallwidth;
      return [(pos[0] + 1) * ww - ww / 2 + constants.WALL_THICKNESS / 2 + this.screen_offsets[0], (pos[1] + 1) * ww - ww / 2 + constants.WALL_THICKNESS / 2 + this.screen_offsets[1]];
    };

    return Maze;

  })();

  $(document).ready(function() {
    var begin, canvas, maze, processing;
    maze = new Maze(768, 576, 'MEDIUM');
    begin = function(p5) {
      p5.setup = function() {
        console.log('Setup');
        p5.size(800, 600);
        return p5.frameRate(30);
      };
      return p5.draw = function() {
        console.log('Draw...');
        maze.player.update();
        return maze.render(p5);
      };
    };
    $(document).keypress(function(e) {
      console.log('keypress ' + e.keyCode);
      if (e.keyCode === 97) {
        return maze.player.change_dir('left');
      } else if (e.keyCode === 119) {
        return maze.player.change_dir('up');
      } else if (e.keyCode === 100) {
        return maze.player.change_dir('right');
      } else if (e.keyCode === 115) {
        return maze.player.change_dir('down');
      }
    });
    canvas = document.getElementById("processing");
    return processing = new Processing(canvas, begin);
  });

}).call(this);
