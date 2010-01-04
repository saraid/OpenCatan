var Catan = function() {};

Catan.State = function() {};
Catan.State.init = function() {
  if (this.initialized) return false;
  this.initialized = true;
  this.board = [];
  this.intersections = [];
  this.paths = [];
};

Catan.State.add_hex = function(x, y, color, number, type, row, col) {
  this.init();
  if (!this.board[row]) this.board[row] = [];
  this.board[row][col] = new Catan.Hex(row, col, number, type);
  this.board[row][col].draw_attributes = {
    x: x, y: y, color: color
  };
}
Catan.State.add_intersection = function(id, x, y, hexes) {
  this.init();
  this.intersections[id] = new Catan.Intersection(id, hexes);
  this.intersections[id].draw_attributes = { x: x, y: y };
}
Catan.State.add_path = function(intersections) {
  this.init();
  var curr_path = this.paths[this.paths.length] = new Catan.Path(intersections[0], intersections[1]);
}
Catan.State.foreach_hex = function(proc) {
  for (row in this.board) {
    for (col in this.board[row]) {
      proc.call(this, this.board[row][col]);
    }
  }
}
Catan.State.draw = function() {
  this.foreach_hex(function(hex) { hex.draw(); });
  for (i in this.intersections) this.intersections[i].draw();
  for (i in this.paths) this.paths[i].draw();
}

Catan.Hex = function() { this.init.apply(this, arguments); };
Catan.Hex.prototype = {
  init: function(row, col, number, type) {
    this.row = row;
    this.col = col;
    this.number = number;
    this.type = type;
    this.state_changed = true;
  },
  add_for_redraw: function(obj) {
    if (this.redraw == null) this.redraw = [];
    this.redraw[this.redraw.length] = obj;
  },
  needs_redraw: function() {
    this.state_changed = true;
  },
  toggle: function() {
    if (this.selected) operator = -1;
    else operator = 1;
    var rgb = this.draw_attributes.color;
    for (i = 0; i < rgb.length; i++) rgb[i] = parseInt(rgb[i])+50*operator;
    this.draw_attributes.color = rgb;
    this.selected = !this.selected;
    this.state_changed = true;
  },
  highlight: function(set_on) {
    if (set_on) {
      if (this.highlighted) return null;
      else Catan.State.foreach_hex(function(hex) { hex.highlight(false); });
      operator = 1;
    } else {
      if (!this.highlighted) return null;
      operator = -1;
    }
    var rgb = this.draw_attributes.color;
    for (i = 0; i < rgb.length; i++) rgb[i] = parseInt(rgb[i])+50*operator;
    this.draw_attributes.color = rgb;
    this.highlighted = set_on;
    this.state_changed = true;
  },
  draw: function() {
    if (!this.state_changed) return false;
    Catan.Draw.draw_hex(this.draw_attributes.x,
                        this.draw_attributes.y,
                        this.draw_attributes.color,
                        this.number, this.type, this.row, this.col);
    this.state_changed = false;
    for (i = 0; i < this.redraw.length; i++) {
      this.redraw[i].needs_redraw();
    }
  }
};

Catan.Intersection = function() { this.init.apply(this, arguments); }
Catan.Intersection.prototype = {
  init: function(id, hexes) {
    this.id = id;
    this.hexes = [];
    for (i = 0; i < hexes.length; i++) {
      this.hexes[i] = Catan.State.board[hexes[i][0]][hexes[i][1]];
      this.hexes[i].add_for_redraw(this);
    }
    this.invisible = true;
    this.state_changed = true;
  },
  needs_redraw: function() {
    if (this.invisible) return false;
    this.state_changed = true;
  },
  show: function() {
    if (!this.invisible) return null;
    this.invisible = false;
    this.state_changed = true;
  },
  hide: function() {
    if (this.invisible) return null;
    this.invisible = true;
    this.state_changed = true;
  },
  draw: function() {
    if (!this.state_changed) return false;
    Catan.Draw.draw_intersection(this.draw_attributes.x,
                                 this.draw_attributes.y,
                                 !this.invisible);
    if (this.invisible)
      for (i = 0; i < this.hexes.length; i++) {
        this.hexes[i].needs_redraw();
      }
    this.state_changed = false;
  }
};
Catan.Path = function() { this.init.apply(this, arguments); }
Catan.Path.prototype = {
  init: function(i1, i2) {
    this.intersections = [Catan.State.intersections[i1],
                          Catan.State.intersections[i2]];
    this.draw_attributes = {
      x: (this.intersections[0].draw_attributes.x + this.intersections[1].draw_attributes.x)/2,
      y: (this.intersections[0].draw_attributes.y + this.intersections[1].draw_attributes.y)/2
    };
    if (this.intersections[0].draw_attributes.y == this.intersections[1].draw_attributes.y)
      this.draw_attributes.angle = 0;
    else if (this.intersections[0].draw_attributes.x < this.intersections[1].draw_attributes.x)
      this.draw_attributes.angle = Math.PI*4/3;
    else
      this.draw_attributes.angle = Math.PI*-1/3;

    for (i = 0; i < this.intersections.length; i++) {
      var hexes = this.intersections[i].hexes;
      for (j = 0; j < hexes.length; j++) {
        hexes[j].add_for_redraw(this);
      }
    }

    this.invisible = true;
    this.state_changed = true;
  },
  needs_redraw: function() {
    if (this.invisible) return false;
    this.state_changed = true;
  },
  show: function() {
    if (!this.invisible) return null;
    this.invisible = false;
    this.state_changed = true;
  },
  hide: function() {
    if (this.invisible || this.stuck) return null;
    this.invisible = true;
    this.state_changed = true;
  },
  stick: function() {
    this.stuck = true;
  },
  draw: function() {
    if (!this.state_changed) return false;
    Catan.Draw.draw_path(this.draw_attributes, !this.invisible);
    if (this.invisible) {
      for (i = 0; i < this.intersections.length; i++) {
        for (j = 0; j < this.intersections[i].hexes.length; j++) {
          this.intersections[i].hexes[j].needs_redraw();
        }
      }
    }
    this.state_changed = false;
  }
};

Catan.Draw = function() {};

Catan.Draw.init = function(hex_size, origin) {
  this.board = $("#board").get(0);
  this.context = this.board.getContext('2d');
  this.hex_size = hex_size;
  this.origin = origin;
  this.hex_store = [];
  this.offset = $("#board").offset();
    this.offset.top  += parseInt($("#board").css("borderTopWidth"));
    this.offset.left += parseInt($("#board").css("borderLeftWidth"));

  setInterval(this.loop, 10);
  this.init_events();
};
Catan.Draw.outside_bounds = function(x, y) {
  if (x > $("#board").width()  + this.offset.left)   return true;
  if (y > $("#board").height() + this.offset.top)    return true;
  if (x < this.offset.left + Catan.Draw.origin.left) return true;
  if (y < this.offset.top  + Catan.Draw.origin.top)  return true;
  return false;
};
Catan.Draw.init_events = function() {
  $("#board").click(function(event) {
    if (Catan.Draw.outside_bounds(event.pageX, event.pageY)) return null;
    var on_hex = Catan.Util.xy_to_hex(event.pageX-Catan.Draw.offset.left, event.pageY-Catan.Draw.offset.top);
    if (on_hex) on_hex.toggle();
    var on_path = Catan.Util.xy_to_path(event.pageX-Catan.Draw.offset.left, event.pageY-Catan.Draw.offset.top);
    if (on_path) on_path.stick();
  }).mousemove(function(event) {
    if (Catan.Draw.outside_bounds(event.pageX, event.pageY)) null;
    Catan.Draw.nuke_intersections_and_paths();
    var on_hex = Catan.Util.xy_to_hex(event.pageX-Catan.Draw.offset.left, event.pageY-Catan.Draw.offset.top);
    if (on_hex) on_hex.highlight(true);
    var on_inter = Catan.Util.xy_to_intersection(event.pageX-Catan.Draw.offset.left, event.pageY-Catan.Draw.offset.top);
    if (on_inter) on_inter.show();
    var on_path = Catan.Util.xy_to_path(event.pageX-Catan.Draw.offset.left, event.pageY-Catan.Draw.offset.top);
    if (on_path) on_path.show();
  });
};
Catan.Draw.draw_hex = function(x, y, color, number, type, row, col) {
  this.context.fillStyle = "rgb(" + color.join(',') + ")";
  this.context.beginPath();
  var vertices = [[x + (this.hex_size / 2)    , y                          ],
                  [x + (3 * this.hex_size / 2), y                          ],
                  [x + (2 * this.hex_size)    , y + (this.hex_size * 0.866)],
                  [x + (3 * this.hex_size / 2), y + (this.hex_size * 1.732)],
                  [x + (this.hex_size / 2)    , y + (this.hex_size * 1.732)],
                  [x                          , y + (this.hex_size * 0.866)]]
  this.context.moveTo(vertices[0][0], vertices[0][1]);
  for (i = 0; i < 6; i++)
    this.context.lineTo(vertices[i][0], vertices[i][1]);
  this.context.fill();

  this.context.textAlign = "center";
  this.context.font = "12px Times";
  this.context.fillStyle = "black";
  this.context.fillText(type, x + this.hex_size, y + this.hex_size);

  this.hex_store[this.hex_store.length] = [x + this.hex_size, y + this.hex_size, type, row, col];
};
Catan.Draw.draw_intersection = function(x, y, visible) {
  this.context.fillStyle = visible ? "black" : "white";
  this.context.beginPath();
  var size = this.hex_size / 8;
  if (!visible) size+=2;
  this.context.arc(x, y, size, 0, Math.PI*2, true);
  this.context.fill();
};
Catan.Draw.draw_path = function(attributes, visible) {
  this.context.fillStyle = visible ? "black" : "white";
  var path_width  = this.hex_size / 10;
  var path_length = this.hex_size * 0.75;
  if (!visible) {
     path_width++;
     path_length++;
  }

  this.context.save();
  this.context.translate(attributes.x, attributes.y);
  this.context.rotate(attributes.angle);
  this.context.beginPath();
  this.context.moveTo(-path_length/2, -path_width/2);
  this.context.lineTo( path_length/2, -path_width/2);
  this.context.lineTo( path_length/2,  path_width/2);
  this.context.lineTo(-path_length/2,  path_width/2);
  this.context.fill();
  this.context.restore();
};
Catan.Draw.nuke_intersections_and_paths = function() {
  for (i in Catan.State.intersections) {
    var inter = Catan.State.intersections[i];
    if (!inter.invisible) inter.hide();
  }
  for (i in Catan.State.paths) {
    var path = Catan.State.paths[i];
    if (!path.invisible) path.hide();
  }
};

Catan.Util = function() {};
Catan.Util.xy_to_hex = function(x, y) {
  var distance = Catan.Draw.hex_size;
  var result = null;
  for (i = 0; i < Catan.Draw.hex_store.length; i++) {
    var hex = Catan.Draw.hex_store[i];
    this_distance = Math.sqrt(Math.pow(x - hex[0], 2) + Math.pow(y - hex[1], 2));
    if (this_distance < distance) {
      distance = this_distance
      result = hex;
    }
  }
  
  if (result) return Catan.State.board[result[3]][result[4]];
  return null;
}
Catan.Util.xy_to_intersection = function(x, y) {
  var distance = Catan.Draw.hex_size / 8;
  var result = null;
  for (i in Catan.State.intersections) {
    var inter = Catan.State.intersections[i];
    this_distance = Math.sqrt(Math.pow(x - inter.draw_attributes.x, 2) + Math.pow(y - inter.draw_attributes.y, 2));
    if (this_distance < distance) {
      distance = this_distance
      result = inter;
    }
  }
  
  return result;
}
Catan.Util.xy_to_path = function(x, y) {
  var distance = Catan.Draw.hex_size * 0.75 / 2;
  var result = null;
  for (i in Catan.State.paths) {
    var path = Catan.State.paths[i];
    this_distance = Math.sqrt(Math.pow(x - path.draw_attributes.x, 2) + Math.pow(y - path.draw_attributes.y, 2));
    if (this_distance < distance) {
      distance = this_distance
      result = path;
    }
  }
  
  return result;
}
