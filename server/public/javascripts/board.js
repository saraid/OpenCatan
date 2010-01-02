var Catan = function() {};

Catan.State = function() {};
Catan.State.init = function() {
  if (this.initialized) return false;
  this.initialized = true;
  this.board = [];
};

Catan.State.add_hex = function(x, y, edge, color, number, type, row, col) {
  this.init();
  if (!this.board[row]) this.board[row] = [];
  this.board[row][col] = new Catan.Hex(row, col, number, type);
  this.board[row][col].draw_attributes = {
    x: x, y: y, edge: edge, color: color
  };
}
Catan.State.foreach = function(proc) {
  for (row in this.board) {
    for (col in this.board[row]) {
      proc.call(this, this.board[row][col]);
    }
  }
}
Catan.State.draw = function() {
  this.foreach(function(hex) { hex.draw(); });
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
      else Catan.State.foreach(function(hex) { hex.highlight(false); });
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
  draw: function(x, y, edge, color) {
    if (!this.state_changed) return false;
    Catan.Draw.draw_hex(x || this.draw_attributes.x,
                        y || this.draw_attributes.y,
                        edge || this.draw_attributes.edge,
                        color || this.draw_attributes.color,
                        this.number, this.type, this.row, this.col);
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
  }).mousemove(function(event) {
    if (Catan.Draw.outside_bounds(event.pageX, event.pageY)) return null;
    var on_hex = Catan.Util.xy_to_hex(event.pageX-Catan.Draw.offset.left, event.pageY-Catan.Draw.offset.top);
    if (on_hex) on_hex.highlight(true);
  });
};
Catan.Draw.draw_hex = function(x, y, edge, color, number, type, row, col) {
  this.context.fillStyle = "rgb(" + color.join(',') + ")";
  this.context.beginPath();
  var vertices = [[x + (edge / 2)    , y                 ],
                  [x + (3 * edge / 2), y                 ],
                  [x + (2 * edge)    , y + (edge * 0.866)],
                  [x + (3 * edge / 2), y + (edge * 1.732)],
                  [x + (edge / 2)    , y + (edge * 1.732)],
                  [x                 , y + (edge * 0.866)]]
  this.context.moveTo(vertices[0][0], vertices[0][1]);
  for (i = 0; i < 6; i++)
    this.context.lineTo(vertices[i][0], vertices[i][1]);
  this.context.fill();

  this.context.textAlign = "center";
  this.context.font = "12px Times";
  this.context.fillStyle = "black";
  this.context.fillText(type, x + edge, y + edge);

  this.hex_store[this.hex_store.length] = [x + edge, y + edge, type, row, col];
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
