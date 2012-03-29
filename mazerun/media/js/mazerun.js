(function() {
  var DERP, DIFFICULTY_WIDTHS, DIRECTIONS, DIRS, DOWN, EASY, HARD, IMPOSSIBRU, LEFT, MEDIUM, Marker, Maze, MazeScene, MenuScene, Particle, Pipe, Player, RIGHT, Scene, SceneManager, TOP, center_text, constants, draw_lines, draw_lines_from, point_in_rect, random_choice, random_color, _ref, _ref2,
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
      ESCAPE: 27,
      LEFT: 37,
      RIGHT: 39,
      UP: 38,
      DOWN: 40,
      SHIFT: 16
    },
    LOSE_PHRASES: ["Dont hit walls!", "You're not very good at this", "NOPE", "So close! (maybe)"],
    WIN_PHRASES: ["That's how it's done!", "Impressive!", "WINNING!", "AWWW YYYYEAAHHH!!"]
  };

  _ref = [0, 1, 2, 3, 4], DERP = _ref[0], EASY = _ref[1], MEDIUM = _ref[2], HARD = _ref[3], IMPOSSIBRU = _ref[4];

  DIFFICULTY_WIDTHS = [64, 48, 32, 24, 16];

  DIRECTIONS = (_ref2 = [0, 1, 2, 3], LEFT = _ref2[0], TOP = _ref2[1], RIGHT = _ref2[2], DOWN = _ref2[3], _ref2);

  DIRS = [[-1, 0], [0, -1], [1, 0], [0, 1]];

  Player = (function() {

    function Player(pos, dir) {
      this.init_pos = pos;
      this.init_dir = this.dir = dir;
      this.x = pos[0], this.y = pos[1];
      this.path = [pos];
      this.speed = constants.PLAYER_SPEED;
      this.last_path = null;
      this.dir_keys = {
        'left': DIRS[LEFT],
        'up': DIRS[TOP],
        'right': DIRS[RIGHT],
        'down': DIRS[DOWN]
      };
      this.speedboost = false;
    }

    Player.prototype.update = function() {
      var speed;
      speed = this.speed * (this.speedboost ? 2 : 1);
      this.x += this.dir[0] * speed;
      return this.y += this.dir[1] * speed;
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

    Player.prototype.set_last_path = function() {
      this.last_path = this.path;
      return this.last_path.push([this.x, this.y]);
    };

    Player.prototype.reset = function() {
      var _ref3;
      this.dir = this.init_dir;
      this.set_last_path();
      this.path = [this.init_pos];
      return _ref3 = this.init_pos, this.x = _ref3[0], this.y = _ref3[1], _ref3;
    };

    return Player;

  })();

  Particle = (function() {

    function Particle(pos, vel, color) {
      this.pos = pos;
      this.vel = vel;
      this.color = color;
      this.alpha = 255;
    }

    Particle.prototype.update = function() {
      this.pos[0] += this.vel[0];
      this.pos[1] += this.vel[1];
      this.alpha -= 3;
      return this.alpha > 0;
    };

    Particle.prototype.render = function(p5) {
      p5.set(this.pos[0], this.pos[1], p5.color.apply(p5, __slice.call(this.color).concat([this.alpha])));
    };

    return Particle;

  })();

  Marker = (function() {

    function Marker(maze, position, color, radius) {
      this.maze = maze;
      this.position = position;
      this.color = color;
      this.radius = radius;
      this.exploding = false;
      this.done_exploding = false;
      this.p5 = this.maze.p5;
    }

    Marker.prototype.explode = function() {
      var center, factor, i, vx, vy;
      this.exploding = true;
      center = this.maze.grid_to_screen(this.position);
      this.particles = [];
      for (i = 0; i < 360; i++) {
        factor = 0.5 + 5 * Math.random();
        vx = Math.sin(i / 360 * Math.PI * 2) * factor;
        vy = Math.cos(i / 360 * Math.PI * 2) * factor;
        this.particles.push(new Particle([center[0], center[1]], [vx, vy], this.color));
      }
    };

    Marker.prototype.do_explode = function() {
      var alive, any_alive, particle, _i, _len, _ref3;
      any_alive = false;
      _ref3 = this.particles;
      for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
        particle = _ref3[_i];
        alive = particle.update();
        if (alive) {
          any_alive = true;
          particle.render(this.p5);
        }
      }
      if (!any_alive) this.done_exploding = true;
    };

    Marker.prototype.render = function() {
      var x, y, _ref3, _ref4;
      if (this.exploding) if (!this.done_exploding) this.do_explode();
      this.p5.noStroke();
      (_ref3 = this.p5).fill.apply(_ref3, __slice.call(this.color).concat([this.exploding ? 32 : 255]));
      _ref4 = this.maze.grid_to_screen(this.position), x = _ref4[0], y = _ref4[1];
      this.p5.ellipse(x, y, this.radius, this.radius);
    };

    return Marker;

  })();

  Maze = (function() {

    function Maze(p5, width, height, difficulty) {
      var corners, x, y;
      this.p5 = p5;
      this.width = width;
      this.height = height;
      this.DEBUG = false;
      this.ticks = 0;
      this.wallwidth = DIFFICULTY_WIDTHS[difficulty];
      this.player_width = constants.PLAYER_LINE_THICKNESS;
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
      this.player_alpha = 255;
      corners = [[0, 0], [0, this.gridsize[1] - 1], [this.gridsize[0] - 1, 0], [this.gridsize[0] - 1, this.gridsize[1] - 1]];
      this.start = random_choice(corners);
      while (true) {
        this.end = random_choice(corners);
        if (this.end !== this.start) break;
      }
      this.start_dir = null;
      this.make_solution();
      this.player = new Player(this.grid_to_screen(this.start), this.start_dir);
      this.start_marker = new Marker(this, this.start, constants.START_COLOR, constants.POINT_MARKER_WIDTH);
      this.end_marker = new Marker(this, this.end, constants.END_COLOR, constants.POINT_MARKER_WIDTH);
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

    Maze.prototype.render = function() {
      var size, _ref3,
        _this = this;
      this.ticks += 1;
      if (this.winning) {
        this.player_width += 2;
        this.player_alpha -= 10;
      }
      this.p5.background(255);
      this.p5.noStroke();
      (_ref3 = this.p5).fill.apply(_ref3, __slice.call(this.wall_color).concat([32]));
      this.p5.rect(0, 0, constants.SCREEN_WIDTH, constants.SCREEN_HEIGHT);
      this.p5.strokeCap(this.p5.SQUARE);
      size = this.wallwidth;
      this.p5.fill(127, 127, 127);
      this.p5.strokeWeight(constants.WALL_THICKNESS);
      _.each(this.grid, function(row, x) {
        return _.each(row, function(walls, y) {
          var bottom, dx, dy, left, right, top, _ref4, _ref5, _ref6;
          _ref4 = [x * size + _this.screen_offsets[0], y * size + _this.screen_offsets[1]], dx = _ref4[0], dy = _ref4[1];
          if (_this.DEBUG) {
            _this.p5.noStroke();
            (_ref5 = _this.p5).fill.apply(_ref5, __slice.call(_this.wall_color).concat([64]));
            _this.p5.rect(dx + _this.wallwidth / 2, dy + _this.wallwidth / 2, size - 8, size - 8);
          }
          (_ref6 = _this.p5).stroke.apply(_ref6, _this.wall_color);
          left = walls[0], top = walls[1], right = walls[2], bottom = walls[3];
          if (left) _this.p5.line(dx, dy, dx, dy + size, constants.WALL_THICKNESS);
          if (top) _this.p5.line(dx, dy, dx + size, dy, constants.WALL_THICKNESS);
          if (right) {
            _this.p5.line(dx + size, dy, dx + size, dy + size, constants.WALL_THICKNESS);
          }
          if (bottom) {
            return _this.p5.line(dx, dy + size, dx + size, dy + size, constants.WALL_THICKNESS);
          }
        });
      });
      this.draw_player();
      this.start_marker.render();
      return this.end_marker.render();
    };

    Maze.prototype.draw_player = function() {
      var _ref3, _ref4;
      (_ref3 = this.p5).stroke.apply(_ref3, __slice.call(this.player_color).concat([this.player_alpha]));
      this.p5.strokeWeight(this.player_width);
      draw_lines(this.p5, this.player.get_points());
      if (this.player.last_path) {
        this.p5.strokeWeight(constants.PLAYER_LINE_THICKNESS);
        (_ref4 = this.p5).stroke.apply(_ref4, __slice.call(this.player_color).concat([32]));
        draw_lines(this.p5, this.player.last_path);
      }
    };

    Maze.prototype.completed = function() {
      this.winning = true;
      this.player.set_last_path();
      this.start_marker.explode();
      return this.end_marker.explode();
    };

    Maze.prototype.grid_to_screen = function(pos) {
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
    $(document).bind('keypress keyup keydown', function(event) {
      return scene_manager.keyevent(event);
    });
    canvas = document.getElementById("maze");
    processing = new Processing(canvas, begin);
    return $('#maze').focus();
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

    Scene.prototype.keypress = function(letter, event_type) {
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
      this.special_keys = _.map(constants.keys, _.identity);
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
      var charCode, letter, _ref3;
      charCode = event.which || event.keyCode;
      if ((_ref3 = event.type) === 'keydown' || _ref3 === 'keyup') {
        if (__indexOf.call(this.special_keys, charCode) < 0) return;
        letter = charCode;
      } else {
        letter = String.fromCharCode(charCode);
      }
      return this.active_scene.keypress(letter, event.type);
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
        this.maze = new Maze(this.p5, constants.MAZE_WIDTH, constants.MAZE_HEIGHT, difficulty);
        this.reset_ticks();
        this.lose_match_color = (_ref3 = this.p5).color.apply(_ref3, this.maze.wall_color);
        this.win_match_color = (_ref4 = this.p5).color.apply(_ref4, constants.END_COLOR);
        this.set_state('status', 'starting');
      }
      if (this.get_state('status') !== 'dead') {
        return this.set_state('status', 'starting');
      }
    };

    MazeScene.prototype.reset_ticks = function() {
      return this.starting_ticks = 3 * (60 / (60 / constants.FRAMERATE));
    };

    MazeScene.prototype.render = function(p5) {
      var cur_pixel, curpos, status;
      this.maze.render(p5);
      status = this.get_state('status');
      switch (status) {
        case 'dead':
          p5.fill(0, 128);
          p5.textFont(this.font, 64);
          center_text(p5, this.dead_text);
          p5.textSize(32);
          center_text(p5, "Press spacebar to restart", 100);
          center_text(p5, "Escape for menu", 150);
          break;
        case 'win':
          p5.fill(0, 128);
          p5.textFont(this.font, 64);
          center_text(p5, this.win_text);
          break;
        case 'playing':
          this.maze.player.update();
          curpos = this.maze.player.get_current();
          cur_pixel = p5.get(curpos[0], curpos[1]);
          if (cur_pixel === this.lose_match_color && !this.maze.DEBUG) {
            this.set_state('status', 'dead');
            return this.dead_text = random_choice(constants.LOSE_PHRASES);
          } else if (cur_pixel === this.win_match_color) {
            this.maze.completed();
            this.set_state('status', 'win');
            return this.win_text = random_choice(constants.WIN_PHRASES);
          }
          break;
        case 'starting':
          this.do_starting(p5);
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

    MazeScene.prototype.keypress = function(letter, event_type) {
      switch (event_type) {
        case 'keypress':
          switch (letter) {
            case 'a':
              return this.maze.player.change_dir('left');
            case 'w':
              return this.maze.player.change_dir('up');
            case 'd':
              return this.maze.player.change_dir('right');
            case 's':
              return this.maze.player.change_dir('down');
            case ' ':
              if (this.get_state('status') === 'dead') {
                this.reset_ticks();
                this.maze.player.reset();
                return this.set_state('status', 'starting');
              }
              break;
            case 'q':
              return this.maze.DEBUG = !this.maze.DEBUG;
          }
          break;
        case 'keydown':
          switch (letter) {
            case constants.keys.LEFT:
              return this.maze.player.change_dir('left');
            case constants.keys.UP:
              return this.maze.player.change_dir('up');
            case constants.keys.RIGHT:
              return this.maze.player.change_dir('right');
            case constants.keys.DOWN:
              return this.maze.player.change_dir('down');
            case constants.keys.ESCAPE:
              return this.manager.switch_scene('menu');
            case constants.keys.SHIFT:
              return this.maze.player.speedboost = true;
          }
          break;
        case 'keyup':
          switch (letter) {
            case constants.keys.SHIFT:
              return this.maze.player.speedboost = false;
          }
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

  center_text = function(p5, text, y_offset) {
    var width, y;
    y = constants.SCREEN_HEIGHT / 2 + (y_offset || 0);
    width = p5.textWidth(text);
    return p5.text(text, constants.SCREEN_WIDTH / 2 - width / 2, y);
  };

}).call(this);
