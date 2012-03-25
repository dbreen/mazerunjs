(function() {
  var DERP, DIFFICULTY_WIDTHS, DIRECTIONS, DIRS, DOWN, EASY, HARD, IMPOSSIBRU, LEFT, MEDIUM, Maze, MazeScene, MenuScene, Pipe, Player, RIGHT, Scene, SceneManager, TOP, center_text, constants, draw_lines, draw_lines_from, point_in_rect, random_choice, random_color, _ref, _ref2,
    __slice = Array.prototype.slice,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

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
      ESCAPE: 27
    }
  };

  _ref = [0, 1, 2, 3, 4], DERP = _ref[0], EASY = _ref[1], MEDIUM = _ref[2], HARD = _ref[3], IMPOSSIBRU = _ref[4];

  DIFFICULTY_WIDTHS = [64, 48, 32, 24, 16];

  DIRECTIONS = (_ref2 = [0, 1, 2, 3], LEFT = _ref2[0], TOP = _ref2[1], RIGHT = _ref2[2], DOWN = _ref2[3], _ref2);

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
      dir = this.dir_keys[dir];
      if (dir !== this.dir) {
        this.dir = dir;
        return this.path.push([this.x, this.y]);
      }
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
      this.wallwidth = DIFFICULTY_WIDTHS[difficulty];
      this.screen_offsets = [(constants.SCREEN_WIDTH - width) / 2, (constants.SCREEN_HEIGHT - height) / 2];
      this.gridsize = [width / this.wallwidth, height / this.wallwidth];
      this.grid = (function() {
        var _ref3, _results;
        _results = [];
        for (x = 1, _ref3 = this.gridsize[0]; 1 <= _ref3 ? x <= _ref3 : x >= _ref3; 1 <= _ref3 ? x++ : x--) {
          _results.push((function() {
            var _ref4, _results2;
            _results2 = [];
            for (y = 1, _ref4 = this.gridsize[1]; 1 <= _ref4 ? y <= _ref4 : y >= _ref4; 1 <= _ref4 ? y++ : y--) {
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
      var dir, idir, neighbors, stack, total, unvisited, visited, x, y, _ref3, _ref4, _ref5;
      _ref3 = this.start, x = _ref3[0], y = _ref3[1];
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
          _ref4 = [x + dir[0], y + dir[1]], x = _ref4[0], y = _ref4[1];
          this.grid[x][y][(idir + 2) % 4] = false;
          stack.push([x, y]);
          visited += 1;
        } else {
          _ref5 = stack.pop(), x = _ref5[0], y = _ref5[1];
        }
      }
      return total;
    };

    Maze.prototype.find_neighbors = function(x, y) {
      "Find all x, y pairs in the up/down right/left directions that are still\nwithin the bounds of the grid. Return the directions towards each neighbor";
      var dir, idir, neighbors, nx, ny, _i, _len, _ref3;
      neighbors = [];
      for (_i = 0, _len = DIRECTIONS.length; _i < _len; _i++) {
        idir = DIRECTIONS[_i];
        dir = DIRS[idir];
        _ref3 = [x + dir[0], y + dir[1]], nx = _ref3[0], ny = _ref3[1];
        if ((((this.gridsize[0] > nx && nx >= 0) && 0 <= ny) && ny < this.gridsize[1])) {
          neighbors.push(idir);
        }
      }
      return neighbors;
    };

    Maze.prototype.render = function(p5) {
      var maze, size;
      this.ticks += 1;
      p5.background(255);
      p5.fill.apply(p5, __slice.call(this.wall_color).concat([32]));
      p5.rect(0, 0, constants.SCREEN_WIDTH, constants.SCREEN_HEIGHT);
      p5.strokeCap(p5.SQUARE);
      size = this.wallwidth;
      maze = this;
      p5.fill(127, 127, 127);
      p5.stroke.apply(p5, maze.wall_color);
      p5.strokeWeight(constants.WALL_THICKNESS);
      _.each(this.grid, function(row, x) {
        return _.each(row, function(walls, y) {
          var bottom, dx, dy, left, right, top, _ref3;
          _ref3 = [x * size + maze.screen_offsets[0], y * size + maze.screen_offsets[1]], dx = _ref3[0], dy = _ref3[1];
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
      var x, y, _ref3;
      p5.noStroke();
      p5.fill.apply(p5, color);
      _ref3 = this.grid_to_screen(point), x = _ref3[0], y = _ref3[1];
      return p5.ellipse(x, y, radius, radius);
    };

    Maze.prototype.draw_player = function(p5) {
      var i, p, points, _ref3;
      p5.stroke.apply(p5, this.player_color);
      p5.strokeWeight(constants.PLAYER_LINE_THICKNESS);
      points = this.player.get_points();
      for (i = 1, _ref3 = points.length - 1; 1 <= _ref3 ? i <= _ref3 : i >= _ref3; 1 <= _ref3 ? i++ : i--) {
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
    var begin, canvas, processing, scene_manager;
    scene_manager = null;
    begin = function(p5) {
      p5.setup = function() {
        p5.size(constants.SCREEN_WIDTH, constants.SCREEN_HEIGHT);
        p5.frameRate(constants.FRAMERATE);
        scene_manager = new SceneManager(p5);
        scene_manager.register_scene('main', MazeScene);
        scene_manager.register_scene('menu', MenuScene);
        return scene_manager.switch_scene('menu');
      };
      p5.draw = function() {
        return scene_manager.run(p5);
      };
      return p5.mouseClicked = function() {
        return scene_manager.mouseclick();
      };
    };
    $(document).bind('keypress keyup', (function(event) {
      return scene_manager.keyevent(event);
    }));
    canvas = document.getElementById("processing");
    return processing = new Processing(canvas, begin);
  });

  Scene = (function() {

    function Scene(manager) {
      this.manager = manager;
      this.state = {};
      this.ran = false;
    }

    Scene.prototype.get_state = function(key) {
      return this.state[key];
    };

    Scene.prototype.set_state = function(key, val) {
      return this.state[key] = val;
    };

    Scene.prototype.load = function(p5) {};

    Scene.prototype.setup = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    };

    Scene.prototype.render = function(p5) {};

    Scene.prototype.keypress = function(letter) {
      return false;
    };

    Scene.prototype.mouseclick = function() {};

    return Scene;

  })();

  SceneManager = (function() {

    function SceneManager(p5) {
      this.p5 = p5;
      this.scenes = {};
      this.active_scene = null;
      this.special_keys = [constants.keys.ESCAPE];
    }

    SceneManager.prototype.register_scene = function(scene_key, scene_class) {
      var scene;
      scene = new scene_class(this);
      return this.scenes[scene_key] = scene;
    };

    SceneManager.prototype.switch_scene = function() {
      var args, scene, scene_key;
      scene_key = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      scene = this.scenes[scene_key];
      if (!scene.ran) scene.load(this.p5);
      scene.setup.apply(scene, args);
      scene.ran = true;
      return this.active_scene = scene;
    };

    SceneManager.prototype.is_loaded = function(scene_key) {
      return this.scenes[scene_key] != null;
    };

    SceneManager.prototype.get_state = function(scene_key, key) {
      if (!this.is_loaded(scene_key)) return null;
      return this.scenes[scene_key].get_state(key);
    };

    SceneManager.prototype.run = function(p5) {
      var scene;
      scene = this.active_scene;
      return scene.render(p5);
    };

    SceneManager.prototype.keyevent = function(event) {
      var charCode, letter;
      charCode = event.which || event.keyCode;
      if (event.type === 'keyup') {
        if (__indexOf.call(this.special_keys, charCode) < 0) return;
        letter = charCode;
      } else {
        letter = String.fromCharCode(charCode);
      }
      return this.active_scene.keypress(letter);
    };

    SceneManager.prototype.mouseclick = function() {
      return this.active_scene.mouseclick();
    };

    return SceneManager;

  })();

  MazeScene = (function(_super) {

    __extends(MazeScene, _super);

    function MazeScene() {
      MazeScene.__super__.constructor.apply(this, arguments);
    }

    MazeScene.prototype.load = function(p5) {
      this.p5 = p5;
      this.set_state('running', true);
      return this.font = p5.loadFont("arial");
    };

    MazeScene.prototype.setup = function(difficulty) {
      var _ref3, _ref4;
      if ((difficulty != null) || !this.maze) {
        this.maze = new Maze(constants.MAZE_WIDTH, constants.MAZE_HEIGHT, difficulty);
        this.starting_ticks = 3 * (60 / (60 / constants.FRAMERATE));
        this.lose_match_color = (_ref3 = this.p5).color.apply(_ref3, this.maze.wall_color);
        this.win_match_color = (_ref4 = this.p5).color.apply(_ref4, constants.END_COLOR);
        this.set_state('status', 'starting');
      }
      if (this.get_state('status') !== 'dead') {
        return this.set_state('status', 'starting');
      }
    };

    MazeScene.prototype.render = function(p5) {
      var cur_pixel, curpos, status, text;
      this.maze.render(p5);
      status = this.get_state('status');
      if (status === 'dead') {
        p5.fill(0, 128);
        p5.textFont(this.font, 64);
        text = "You're dead, bro";
        center_text(p5, 64, text);
      } else if (status === 'win') {
        p5.fill(0, 128);
        p5.textFont(this.font, 64);
        text = "WINNING!!!";
        center_text(p5, 64, text);
      } else if (status === 'playing') {
        this.maze.player.update();
      } else if (status === 'starting') {
        this.do_starting(p5);
      }
      curpos = this.maze.player.get_current();
      cur_pixel = p5.get(curpos[0], curpos[1]);
      if (cur_pixel === this.lose_match_color) {
        return this.set_state('status', 'dead');
      } else if (cur_pixel === this.win_match_color) {
        return this.set_state('status', 'win');
      }
    };

    MazeScene.prototype.do_starting = function(p5) {
      var fontsize, fontwidth, maxfontmult, seconds;
      this.starting_ticks -= 1;
      if (this.starting_ticks <= 0) this.set_state('status', 'playing');
      seconds = Math.floor(this.starting_ticks / constants.FRAMERATE + 1);
      p5.fill(0, Math.floor(255 / constants.FRAMERATE) * (this.starting_ticks % constants.FRAMERATE));
      maxfontmult = Math.floor(constants.SCREEN_HEIGHT / constants.FRAMERATE);
      fontsize = constants.SCREEN_HEIGHT - maxfontmult * (this.starting_ticks % constants.FRAMERATE);
      p5.textFont(this.font, fontsize);
      fontwidth = p5.textWidth(seconds);
      return p5.text(seconds, constants.SCREEN_WIDTH / 2 - fontwidth / 2, constants.SCREEN_HEIGHT / 2 + fontsize / 3);
    };

    MazeScene.prototype.keypress = function(letter) {
      if (letter === 'a') {
        return this.maze.player.change_dir('left');
      } else if (letter === 'w') {
        return this.maze.player.change_dir('up');
      } else if (letter === 'd') {
        return this.maze.player.change_dir('right');
      } else if (letter === 's') {
        return this.maze.player.change_dir('down');
      } else if (letter === constants.keys.ESCAPE) {
        return this.manager.switch_scene('menu');
      }
    };

    return MazeScene;

  })(Scene);

  Pipe = (function() {

    function Pipe(color) {
      var rpoint;
      this.color = color;
      rpoint = [Math.random() * constants.SCREEN_WIDTH, Math.random() * constants.SCREEN_HEIGHT];
      this.pointlist = [rpoint];
      this.current = rpoint;
      this.idir = random_choice(DIRECTIONS);
      this.speed = 1 + 1.5 * Math.random();
      this.width = constants.PLAYER_LINE_THICKNESS;
      this.dead = false;
    }

    Pipe.prototype.update = function() {
      var dir, idx;
      if (this.dead) return;
      if (Math.random() <= 0.02) {
        idx = (4 + (DIRECTIONS.indexOf(this.idir) + random_choice([-1, 1]))) % 4;
        this.idir = DIRECTIONS[idx];
        this.pointlist.push(this.current);
        if (this.pointlist.length > 50) this.dead = true;
      }
      dir = DIRS[this.idir];
      return this.current = [this.current[0] + this.speed * dir[0], this.current[1] + this.speed * dir[1]];
    };

    Pipe.prototype.draw = function(p5) {
      p5.stroke.apply(p5, this.color);
      p5.strokeWeight(4);
      return draw_lines_from(p5, this.pointlist, this.current);
    };

    return Pipe;

  })();

  MenuScene = (function(_super) {

    __extends(MenuScene, _super);

    function MenuScene() {
      MenuScene.__super__.constructor.apply(this, arguments);
    }

    MenuScene.prototype.load = function(p5) {
      var _this = this;
      this.options = [
        [
          'Continue', function() {
            return _this.continue_game();
          }
        ], [
          'Easy', function() {
            return _this.start_game(EASY);
          }
        ], [
          'Medium', function() {
            return _this.start_game(MEDIUM);
          }
        ], [
          'Hard', function() {
            return _this.start_game(HARD);
          }
        ], [
          'Impossibru!', function() {
            return _this.start_game(IMPOSSIBRU);
          }
        ], [
          'Derp', function() {
            return _this.start_game(DERP);
          }
        ]
      ];
      this.num_pipes = 50;
      return this.font = p5.loadFont("arial");
    };

    MenuScene.prototype.setup = function() {
      var _;
      this.current_option = null;
      this.game_running = this.manager.get_state('main', 'running');
      this.pipes = (function() {
        var _ref3, _results;
        _results = [];
        for (_ = 1, _ref3 = this.num_pipes; 1 <= _ref3 ? _ <= _ref3 : _ >= _ref3; 1 <= _ref3 ? _++ : _--) {
          _results.push(new Pipe(random_color()));
        }
        return _results;
      }).call(this);
    };

    MenuScene.prototype.render = function(p5) {
      var i, pipe, _i, _len, _ref3;
      p5.background(0);
      i = 0;
      p5.strokeCap(p5.SQUARE);
      _ref3 = this.pipes;
      for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
        pipe = _ref3[_i];
        i += 1;
        pipe.update();
        pipe.draw(p5);
      }
      p5.fill(0, 192);
      p5.noStroke();
      p5.rect(0, 0, constants.SCREEN_WIDTH, constants.SCREEN_HEIGHT);
      return this.render_options(p5);
    };

    MenuScene.prototype.render_options = function(p5) {
      var menuheight, menuwidth, options, ox, oy, scene, x, y, _ref3,
        _this = this;
      _ref3 = [30, 20], x = _ref3[0], y = _ref3[1];
      options = _.filter(this.options, function(option) {
        return option[0] !== 'Continue' || _this.game_running;
      });
      p5.fill(255, 128);
      menuwidth = 300;
      menuheight = options.length * 50 + 10;
      ox = constants.SCREEN_WIDTH / 2 - menuwidth / 2;
      oy = constants.SCREEN_HEIGHT / 2 - menuheight / 2;
      p5.rect(ox, oy, menuwidth, menuheight);
      p5.textFont(this.font, 32);
      scene = this;
      return _.each(options, function(option, index) {
        var active, func, name, rect, show;
        name = option[0], func = option[1], show = option[2];
        rect = [ox + x - 10, oy + y - 10, 260, 40];
        active = point_in_rect([p5.mouseX, p5.mouseY], rect);
        if (active) {
          scene.current_option = func;
          p5.fill(192, 128);
        } else {
          p5.fill(255, 128);
        }
        p5.rect.apply(p5, rect);
        p5.fill(225);
        p5.text(name, ox + x + 1, oy + y + 20 + 1);
        p5.fill(64);
        p5.text(name, ox + x, oy + y + 20);
        return y += 50;
      });
    };

    MenuScene.prototype.keypress = function(letter) {
      if (letter === 'q') return this.manager.switch_scene('main');
    };

    MenuScene.prototype.start_game = function(difficulty) {
      return this.manager.switch_scene('main', difficulty);
    };

    MenuScene.prototype.continue_game = function() {
      return this.manager.switch_scene('main');
    };

    MenuScene.prototype.mouseclick = function() {
      if (this.current_option) return this.current_option();
    };

    return MenuScene;

  })(Scene);

  random_choice = function(array) {
    return array[Math.floor(Math.random() * array.length)];
  };

  random_color = function() {
    return [Math.random() * 255, Math.random() * 255, Math.random() * 255];
  };

  draw_lines_from = function(p5, pointlist, current) {
    var i, len, _ref3;
    len = pointlist.length;
    if (len === 0) return;
    if (len > 1) {
      for (i = 1, _ref3 = len - 1; 1 <= _ref3 ? i <= _ref3 : i >= _ref3; 1 <= _ref3 ? i++ : i--) {
        p5.line(pointlist[i - 1][0], pointlist[i - 1][1], pointlist[i][0], pointlist[i][1]);
      }
    }
    p5.line(pointlist[len - 1][0], pointlist[len - 1][1], current[0], current[1]);
  };

  draw_lines = function(p5, pointlist) {
    var i, len, _ref3;
    len = pointlist.length;
    if (len < 2) return;
    for (i = 1, _ref3 = len - 1; 1 <= _ref3 ? i <= _ref3 : i >= _ref3; 1 <= _ref3 ? i++ : i--) {
      p5.line(pointlist[i - 1][0], pointlist[i - 1][1], pointlist[i][0], pointlist[i][1]);
    }
  };

  point_in_rect = function(point, rect) {
    return point[0] >= rect[0] && point[0] <= rect[0] + rect[2] && point[1] >= rect[1] && point[1] <= rect[1] + rect[3];
  };

  center_text = function(p5, fontsize, text) {
    var width;
    width = p5.textWidth(text);
    return p5.text(text, constants.SCREEN_WIDTH / 2 - width / 2, constants.SCREEN_HEIGHT / 2 - fontsize / 2);
  };

}).call(this);
