var Catan = function() {};

Catan.State = function() {};
Catan.State.init = function() {
  if (this.initialized) return false;
  this.initialized = true;
  this.board = [];
  this.intersections = [];
  this.paths = [];
};

Catan.State.add_hex = function(color, number, type, row, col) {
  this.init();
  if (!this.board[row]) this.board[row] = [];
  this.board[row][col] = new Catan.Hex(row, col, number, type);
  this.board[row][col].draw_attributes = {
    color: color
  };
}
Catan.State.add_intersection = function(id, row, col, hexes) {
  this.init();
  this.intersections[id] = new Catan.Intersection(id, row, col, hexes);
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
Catan.State.redraw = function() {
  this.foreach_hex(function(hex) { hex.state_changed = true; });
  for (i in this.intersections) this.intersections[i].state_changed = true;
  for (i in this.paths) this.paths[i].state_changed = true;
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
    Catan.Draw.draw_hex(this);
    this.state_changed = false;
    for (i = 0; i < this.redraw.length; i++) {
      this.redraw[i].needs_redraw();
    }
  }
};

Catan.Intersection = function() { this.init.apply(this, arguments); }
Catan.Intersection.prototype = {
  init: function(id, row, col, hexes) {
    this.id = id;
    this.row = row;
    this.col = col;
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
    Catan.Draw.draw_intersection(this);
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
    Catan.Draw.draw_path(this);
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

Catan.Draw.init = function(hex_width, origin) {
  this.board = $("#board");
  this.context = this.board.get(0).getContext('2d');
  this.hex_width = hex_width;
  this.origin = origin;
  this.hex_store = [];
  this.offset = $("#board").offset();
    this.offset.top  += parseInt(this.board.css("borderTopWidth"));
    this.offset.left += parseInt(this.board.css("borderLeftWidth"));

  setInterval(function() {
      Catan.State.draw();
      Catan.Draw.zooming = false;
  }, 10);
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
Catan.Draw.zoom = function(out, amount) {
  this.context.fillStyle = "white";
  this.context.fillRect(0, 0, this.board.width(), this.board.height());
  this.hex_width += out ? amount : -amount;
  //this.origin.top += Math.floor(Math.abs(amount) * 0.866) * amount/Math.abs(amount);
  this.hex_store = [];
  this.zooming = true;
  Catan.State.redraw();
}
Catan.Draw.draw_hex = function(hex) {

  var x, y;
  if (!hex.draw_attributes.x || this.zooming) {
    // Determine x and y
    var x_offset = this.hex_width * 1.5;
    x = (this.board.width() / 2) - (x_offset * Catan.State.board[hex.row].length) + (x_offset * hex.col * 2) + this.hex_width / 2;
    y = this.origin.top + Math.floor(this.hex_width * 0.866) * hex.row;
    hex.draw_attributes.x = x;
    hex.draw_attributes.y = y;
  } else {
    x = hex.draw_attributes.x;
    y = hex.draw_attributes.y;
  }

  this.context.fillStyle = "rgb(" + hex.draw_attributes.color.join(',') + ")";
  this.context.beginPath();
  var vertices = [[x + (this.hex_width / 2)    , y                          ],
                  [x + (3 * this.hex_width / 2), y                          ],
                  [x + (2 * this.hex_width)    , y + (this.hex_width * 0.866)],
                  [x + (3 * this.hex_width / 2), y + (this.hex_width * 1.732)],
                  [x + (this.hex_width / 2)    , y + (this.hex_width * 1.732)],
                  [x                          , y + (this.hex_width * 0.866)]]
  this.context.moveTo(vertices[0][0], vertices[0][1]);
  for (i = 0; i < 6; i++)
    this.context.lineTo(vertices[i][0], vertices[i][1]);
  this.context.fill();

  this.context.textAlign = "center";
  this.context.font = "12px Times";
  this.context.fillStyle = "black";
  this.context.fillText(hex.type, x + this.hex_width, y + this.hex_width);

  this.hex_store[this.hex_store.length] = [hex.draw_attributes.x + this.hex_width,
                                           hex.draw_attributes.y + this.hex_width,
                                           hex];
};
Catan.Draw.draw_intersection = function(inter) {

  var x, y;
  if (!inter.draw_attributes || this.zooming) {
    x = this.board.width() / 2;
    if (inter.col < Catan.Intersection.offset_pattern[inter.row].length/2)
      x -= this.hex_width * (Catan.Intersection.offset_pattern[inter.row][inter.col] / 2);
    else
      x += this.hex_width * (Catan.Intersection.offset_pattern[inter.row][inter.col] / 2);
    y = this.origin.top + Math.floor(this.hex_width * 0.866) * inter.row;
    inter.draw_attributes = { x: x, y: y };
  } else {
    x = inter.draw_attributes.x;
    y = inter.draw_attributes.y;
  }

  this.context.fillStyle = !inter.invisible ? "black" : "white";
  this.context.beginPath();
  var size = this.hex_width / 8;
  if (inter.invisible) size+=2;
  this.context.arc(x, y, size, 0, Math.PI*2, true);
  this.context.fill();
};
Catan.Draw.draw_path = function(path) {

  var x, y, angle;
  if (!path.draw_attributes || this.zooming) {
    x = (path.intersections[0].draw_attributes.x + path.intersections[1].draw_attributes.x)/2;
    y = (path.intersections[0].draw_attributes.y + path.intersections[1].draw_attributes.y)/2;
    if (path.intersections[0].draw_attributes.y == path.intersections[1].draw_attributes.y)
      angle = 0;
    else if (path.intersections[0].draw_attributes.x < path.intersections[1].draw_attributes.x)
      angle = Math.PI*4/3;
    else
      angle = Math.PI*-1/3;
    path.draw_attributes = { x: x, y: y, angle: angle };
  } else {
    x     = path.draw_attributes.x;
    y     = path.draw_attributes.y;
    angle = path.draw_attributes.angle;
  }

  this.context.fillStyle = !path.invisible ? "black" : "white";
  var path_width  = this.hex_width / 10;
  var path_length = this.hex_width * 0.75;
  if (path.invisible) {
     path_width  += 2;
     path_length += 2;
  }

  this.context.save();
  this.context.translate(x, y);
  this.context.rotate(angle);
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
  var distance = Catan.Draw.hex_width;
  var result = null;
  for (i = 0; i < Catan.Draw.hex_store.length; i++) {
    var hex = Catan.Draw.hex_store[i];
    this_distance = Math.sqrt(Math.pow(x - hex[0], 2) + Math.pow(y - hex[1], 2));
    if (this_distance < distance) {
      distance = this_distance
      result = hex;
    }
  }
  
  if (result) return result[2];
  return null;
}
Catan.Util.xy_to_intersection = function(x, y) {
  var distance = Catan.Draw.hex_width / 8;
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
  var distance = Catan.Draw.hex_width * 0.75 / 2;
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
