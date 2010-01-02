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
Catan.State.draw = function() {
  for (row in this.board) {
    for (col in this.board[row]) {
      this.board[row][col].draw();
    }
  }
}

Catan.Hex = function() { this.init.apply(this, arguments); };
Catan.Hex.prototype = {
  init: function(row, col, number, type) {
    this.row = row;
    this.col = col;
    this.number = number;
    this.type = type;
  },
  toggle: function() {
    if (this.selected) operator = -1;
    else operator = 1;
    var rgb = this.draw_attributes.color;
    for (i = 0; i < rgb.length; i++) rgb[i] = parseInt(rgb[i])+50*operator;
    this.draw_attributes.color = rgb;
    this.selected = !this.selected;
  },
  draw: function(x, y, edge, color) {
    Catan.Draw.draw_hex(x || this.draw_attributes.x,
                        y || this.draw_attributes.y,
                        edge || this.draw_attributes.edge,
                        color || this.draw_attributes.color,
                        this.number, this.type, this.row, this.col);
  }
};

Catan.Draw = function() {};

Catan.Draw.init = function(hex_size, origin) {
  this.board = $("#board").get(0);
  this.context = this.board.getContext('2d');
  this.hex_size = hex_size;
  this.origin = origin;
  this.hex_store = [];
  setInterval(this.loop, 10);
  //this.loop();
  this.init_events();
  //this.draw_triangles(); // Debugging crap.
  //this.draw_warwick(); // Debugging crap.
};
Catan.Draw.init_events = function() {
  var offset = $("#board").offset();
  offset.top  += parseInt($("#board").css("borderTopWidth"));
  offset.left += parseInt($("#board").css("borderLeftWidth"));
  $("#board").click(function(event) {
    if (event.clientX > $("#board").width()  + offset.left)   return null;
    if (event.clientY > $("#board").height() + offset.top)    return null;
    if (event.clientX < offset.left + Catan.Draw.origin.left) return null;
    if (event.clientY < offset.top  + Catan.Draw.origin.top)  return null;
//    Catan.Util.xy_to_HEX(event.clientX-offset.left-Catan.Draw.origin.left,
//                         event.clientY-offset.top-Catan.Draw.origin.top);
    var on_hex = Catan.Util.xy_to_hex(event.clientX-offset.left, event.clientY-offset.top);
    on_hex.toggle();
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
Catan.Draw.draw_triangles = function() {
  this.context.fillStyle = "black";

  // H lines.
  for (i = 0; i < 9; i++)
    this.context.fillRect(60, 50+34*i, 320, 1);

  // E lines.
  for (i = 0; i < 10; i++)
    this.draw_line(320-40*i, 50, 480-40*i, 322);

  // X lines.
  for (i = 0; i < 10; i++)
    this.draw_line(80+40*i, 50, -80+40*i, 322);

  this.draw_line(60, 50, 60, 322);
  this.draw_line(380, 50, 380, 322);

  // Y lines.
  this.context.fillStyle = "blue";
  for (i = 0; i < 16; i++)
    this.context.fillRect(80+20*i, 50, 1, 272);
};
Catan.Draw.draw_warwick = function() {
  this.context.fillStyle = "black";
  for (j = 0; j < 3; j++) {
    for (i = 0; i < 4; i++)
      this.context.strokeRect(80+120*j, 50+68*i, 60, 68);
    for (i = 0; i < 5; i++)
      this.context.strokeRect(20+120*j, 16+68*i, 60, 68);
  }
};
Catan.Draw.draw_line = function(from_x, from_y, to_x, to_y) {
  this.context.beginPath();
  this.context.moveTo(from_x,   from_y);
  this.context.lineTo(from_x+1, from_y);
  this.context.lineTo(to_x+1,   to_y);
  this.context.lineTo(to_x,     to_y);
  this.context.fill();
}

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
//{
//  var s=Catan.Draw.hex_size;
//  var h=2*Math.floor(Catan.Draw.hex_size*0.866);
//  var col = x/s/1.5;
//  var row = (y-(col%2)*h/2)/h;
//  var result = { row: Math.floor(row), col: Math.floor(col) };
//  console.log(result);
//  return result;
//}
Catan.Util.xy_to_warwick = function(x, y) {
  var mx = x;
  var my = 340 - y;
  console.log(Math.floor(mx), Math.floor(my));
  var cw = Catan.Draw.hex_size / 2;
  var tw = Catan.Draw.hex_size;
  var h  = 2 * Math.floor(Catan.Draw.hex_size * 0.866);

  var tx = mx/(cw+tw); 
  var rx = mx%(cw+tw);
  my += tx*h/2;
  var ty = my/h; 
  var ry = my%h;
  var rx = tw+cw-rx;
  ry -= h/2;
  if(2*cw*ry > rx*h) {tx++; ty++;}
  if(2*cw*ry < -rx*h) tx++;
  console.log(Math.floor(tx), Math.floor(ty));
}
Catan.Util.xy_to_HEX = function(x, y) {
console.log("x=", x, "y=", y);
  x = ((x - (Catan.Draw.hex_size / 2)) * 1 / Catan.Draw.hex_size) / 1;
  y = (y / Math.floor(Catan.Draw.hex_size * 0.866)) / 2;
console.log("x=", x, "y=", y);
  var coor = {};
  coor['H'] = Math.floor(y * 2);
  coor['E'] = Math.floor(1.732 * x - y);
  coor['X'] = Math.floor(1.732 * x + y);
  console.log(coor);
  console.log(Catan.Util.HEX_to_hexnum(coor['H'], coor['E'], coor['X']));
  return coor;
}
Catan.Util.HEX_to_hexnum = function(h, e, x) {
  var t = e + h - x + ((((x-2*h) % 3)+3) % 3);
  var n = Math.floor( (x - 2*h - ((((x-2*h) % 3)+3) % 3))/3.0 );

  var ox, oy;
  if (t > 0) {
    ox = 2 + 2 * n + h;
    oy = 1 + Math.floor( (h-1)/2 );
  } else {
    ox = 1 + 2 * n + h;
    oy = 1 + Math.floor( h/2 );
  }

  var rv = { left: Math.floor(ox / 2) + 1, top: oy };
  return rv;
}
