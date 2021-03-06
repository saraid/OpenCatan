var OpenCatan = function() {};
OpenCatan.Canvas = function(element, board){
  this.element   = $(element);
  this.board     = board;
  this.width     = this.element.width();
  this.height    = this.element.height();
  this.hex_width = 50;
  this.context   = this.element.get(0).getContext('2d');
  this.h_offset  = 0;
  this.v_offset  = 0;
  this.zooming   = false;

  this.origin    = this.element.offset();
    this.origin.top  += parseInt(this.element.css("borderTopWidth"));
    this.origin.left += parseInt(this.element.css("borderLeftWidth"));

  window.open_catan = this;
  board.init_canvas(this);

  var self = this;
  this.element.mousemove(function(event){
    for (var i in self.board.intersection) self.board.intersection[i].invisible = true;
    for (var i in self.board.path) self.board.path[i].invisible = true;
    self.board.foreach_hex(function(hex) { hex.needs_redraw = true; });
    self.render();
    var thing = self.xy_to_object(event.pageX-self.origin.left, event.pageY-self.origin.top);
    if (thing && thing.invisible != null) {
      thing.invisible = false;
      thing.draw(self);
      document.body.style.cursor = thing.piece ? "help" : "pointer";
    }else{
      document.body.style.cursor = "default";
    }
  }).click(function(event){
    var thing = self.xy_to_object(event.pageX-self.origin.left, event.pageY-self.origin.top);
    if (thing) {
      if (thing instanceof OpenCatan.Board.Hex) console.log("Hex", thing.id);
      if (thing instanceof OpenCatan.Board.Intersection) window.location.href = window.location.href + "/place/settlement/" + thing.id;
      if (thing instanceof OpenCatan.Board.Path) window.location.href = window.location.href + "/place/road/" + thing.id;
    }
  });
  this.xy_to_object = function(x, y){
    var result = null;
    var distance;

    // Intersections
    distance = self.hex_width / 8;
    for (var i in self.board.intersection){
      var intersection = self.board.intersection[i];
      var center = { x: intersection.draw_attributes.x,
                     y: intersection.draw_attributes.y };
      var this_distance = Math.sqrt(Math.pow(x - center.x, 2) + Math.pow(y - center.y, 2));
      if (this_distance < distance) {
        distance = this_distance
        result = intersection;
      }
    }
    if (result) return result;

    // Paths
    distance = self.hex_width * 0.325;
    for (var i in self.board.path){
      var path = self.board.path[i];
      var center = { x: path.draw_attributes.x,
                     y: path.draw_attributes.y };
      var this_distance = Math.sqrt(Math.pow(x - center.x, 2) + Math.pow(y - center.y, 2));
      if (this_distance < distance) {
        distance = this_distance
        result = path;
      }
    }
    if (result) return result;

    // Hexes
    distance = self.hex_width;
    for (var row=0;row<self.board.hex.length;row++) {
      for (var offset=0;offset<self.board.hex[row].length;offset++) {
        var hex = self.board.hex[row][offset];
        var hex_center = { x: hex.draw_attributes.x + self.hex_width,
                           y: hex.draw_attributes.y + self.hex_width };
        var this_distance = Math.sqrt(Math.pow(x - hex_center.x, 2) + Math.pow(y - hex_center.y, 2));
        if (this_distance < distance) {
          distance = this_distance
          result = hex;
        }
      }
    }

    return result;
  }

  this.render = function(){
    var canvas = self;
    for(var path_id in self.board.path){
      self.board.path[path_id].draw(self);
    }
    for(var intersection_id in self.board.intersection){
      self.board.intersection[intersection_id].draw(self);
    }
    self.board.foreach_hex(function(hex) { hex.draw(canvas); })
    for (var i=0;i<self.board.pieces.length;i++) self.board.pieces[i].draw_piece(self);
  };

  // Stuff!
  this.pan = function(options){
    self.context.fillStyle = "white";
    self.context.fillRect(0, 0, self.width, self.height);
    if (options.horizontal) self.h_offset += parseInt(options.horizontal);
    if (options.vertical)   self.v_offset += parseInt(options.vertical);
    self.board.init_canvas(self);
    self.render();
  };
  this.zoom = function(out, amount){
    self.context.fillStyle = "white";
    self.context.fillRect(0, 0, self.width, self.height);
    self.hex_width += out ? -amount : amount;
    self.board.init_canvas(self);
    self.render();
  };
};
OpenCatan.Board = function(json) {
  var json = JSON.parse(json);

  // Accessors
  this.pieces       = [];
  this.hex          = [];
  this.intersection = {};
  this.path         = {};

  for(var row=0;row<json.length;row++){
    this.hex[row] = [];
    for(var offset=0;offset<json[row].length;offset++){
      this.hex[row][offset]    = new OpenCatan.Board.Hex(this, json[row][offset]);
      this.hex[row][offset].id = row+","+offset;
    }
  }
  for (var path_id in this.path){
    var intersections = this.path[path_id].id.split('-');
    for (var i=0;i<2;i++){
      var intersection_id = parseInt(intersections[i]);
      this.path[path_id].add_intersection(this.intersection[intersection_id]);
    }
  }

  this.height = this.hex.length;
  this.width  = this.hex[0].length;

  var self = this;
  this.foreach_hex = function(proc) {
    for(var row=0;row<self.hex.length;row++)
      for(var offset=0;offset<self.hex[row].length;offset++)
        proc.call(self, self.hex[row][offset]);
  };

  // Initialize canvas.
  this.init_canvas = function(canvas){
    for(var row=0;row<this.hex.length;row++){
      for(var offset=0;offset<this.hex[row].length;offset++){
        self.hex[row][offset].init_canvas(canvas, row, offset);
      }
    }
    for (var path_id in self.path){
      self.path[path_id].init_canvas(canvas);
    }
  }
};
OpenCatan.Board.Hex = function(board, json){
  this.type = json.type;
  this.number = json.number;
  this.has_robber = json.has_robber;
  this.intersections = [];
  for(var i=0;i<6;i++) this.intersections[i] = new OpenCatan.Board.Intersection(board, json.intersections[i]);
  this.trade_hubs = [];
  for(var i=0;i<json.trade_hubs.length;i++) this.trade_hubs[i] = json.trade_hubs[i];

  var self = this;
  this.define_vertices = function(x, y, canvas){
    var hex_width = canvas.hex_width;
    return [[x + (hex_width / 2)    , y                          ],
            [x + (3 * hex_width / 2), y                          ],
            [x + (2 * hex_width)    , y + (hex_width * 0.866)],
            [x + (3 * hex_width / 2), y + (hex_width * 1.732)],
            [x + (hex_width / 2)    , y + (hex_width * 1.732)],
            [x                      , y + (hex_width * 0.866)]];
  };
  this.init_canvas = function(canvas, row, offset){
    var this_row = canvas.board.hex[row]
    var h_mid = (this_row.length % 2 == 0) ? this_row.length / 2 : Math.floor(this_row.length / 2);
    var h_off = (this_row.length % 2 == 0) ? 0.5 : -1;
    self.draw_attributes = {
      'x': (canvas.width / 2) + canvas.hex_width                     * (h_off + (offset - h_mid) * 3)   + canvas.h_offset,
      'y': (canvas.height/ 2) + Math.floor(canvas.hex_width * 0.866) * (row - (board.height / 2) - 0.5) + canvas.v_offset,
      'needs_redraw': true
    };

    var vertices = self.define_vertices(self.draw_attributes.x, self.draw_attributes.y, canvas);
    for(var i=0;i<6;i++){
      self.intersections[i].init_canvas(vertices[i][0], vertices[i][1], canvas);
    }
  };

  this.draw = function(canvas){
    //if (!self.draw_attributes.needs_redraw) return;
    self.draw_attributes.needs_redraw = false;

    var context = canvas.context;
    var hex_width = canvas.hex_width;
    var x = self.draw_attributes.x;
    var y = self.draw_attributes.y;
    var img = OpenCatan.Board.Hex.Image[self.type];
    switch(self.type){
      case 'Desert':   context.fillStyle = "rgb(255, 222, 173)"; break;
      case 'Forest':   context.fillStyle = "rgb( 34, 139,  34)"; img = OpenCatan.Board.Hex.Image.Forest; break;
      case 'Plain':    context.fillStyle = "rgb(  0, 255, 127)"; break;
      case 'Field':    context.fillStyle = "rgb(255, 223,   0)"; break;
      case 'Mountain': context.fillStyle = "rgb(112, 128, 144)"; img = OpenCatan.Board.Hex.Image.Mountain; break;
      case 'Hill':     context.fillStyle = "rgb(233, 116,  81)"; break;
      case 'Water':    context.fillStyle = "rgb(  0, 127, 255)"; break;
      case 'Mine':     context.fillStyle = "rgb( 47,  79,  79)"; break;
      default:         context.fillStyle = "rgb(255, 255, 255)"; break;
    }
    if (img) {
      context.drawImage(img, x, y, 100, 86); 
    } else {
      context.beginPath();
      var vertices = self.define_vertices(x, y, canvas);
      context.moveTo(vertices[0][0], vertices[0][1]);
      for (i = 0; i < 6; i++)
        context.lineTo(vertices[i][0], vertices[i][1]);
      context.fill();
    }

    var center = { 'x': x + hex_width, 'y': y + Math.floor(0.866 * hex_width) };
    if (self.number){
      context.fillStyle = "white";
      context.beginPath();
      context.arc(center.x, center.y, 12, 0, Math.PI*2, true);
      context.fill();
      context.textAlign = "center";
      context.textBaseline = "middle";
      context.font = "12px Times";
      context.fillStyle = "black";
      context.fillText(self.number, center.x, center.y + 1);
    }

    if (self.trade_hubs.length > 0){
      for(var i=0;i<self.trade_hubs.length;i++){
        var trade_hub = self.trade_hubs[i];
        var angle     = Math.PI*(2*trade_hub.direction-3)/6;
        var distance  = Math.floor(0.5 * hex_width) + hex_width;
        var location  = { x: center.x + distance * Math.cos(angle),
                          y: center.y + distance * Math.sin(angle) };
        var intersections = [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 0]][trade_hub.direction];
        context.beginPath();
        context.moveTo(location.x, location.y);
        context.lineTo(self.intersections[intersections[0]].draw_attributes.x, self.intersections[intersections[0]].draw_attributes.y);
        context.stroke();
        context.moveTo(location.x, location.y);
        context.lineTo(self.intersections[intersections[1]].draw_attributes.x, self.intersections[intersections[1]].draw_attributes.y);
        context.stroke();
        switch(trade_hub.type){
          case 'wood':  context.fillStyle = "rgb( 34, 139,  34)"; break;
          case 'clay':  context.fillStyle = "rgb(233, 116,  81)"; break;
          case 'wheat': context.fillStyle = "rgb(255, 223,   0)"; break;
          case 'sheep': context.fillStyle = "rgb(  0, 255, 127)"; break;
          case 'ore':   context.fillStyle = "rgb(112, 128, 144)"; break;
          default:      context.fillStyle = "white";
        }
        context.beginPath();
        context.arc(location.x, location.y, 12, 0, Math.PI*2, true);
        context.fill();
        context.stroke();
        context.fillStyle = "black";
        context.fillText(trade_hub.type == "general" ? "3:1" : "2:1", location.x, location.y + 1);
      }
    }

    if (self.has_robber){
      context.fillStyle = "black";
      context.fillRect(center.x + 10, center.y - 20, 15, 15);
      context.strokeStyle = "red";
      context.strokeRect(center.x + 10, center.y - 20, 15, 15);
    }
  };
};
OpenCatan.Board.Hex.Image = {
  'Desert':   "/images/desert_tile.png",
  'Forest':   "/images/forest_tile.png",
  'Mountain': "/images/mountain_tile.png",
  'Water':    "/images/water_tile.png"
};
for (var i in OpenCatan.Board.Hex.Image) {
  var img_location = OpenCatan.Board.Hex.Image[i];
  OpenCatan.Board.Hex.Image[i] = new Image();
  OpenCatan.Board.Hex.Image[i].src = img_location;
}
OpenCatan.Board.Intersection = function(board, json){
  this.id = json.id;
  this.piece = json.piece;
  board.intersection[this.id] = this;
  this.paths = []
  for(var i=0;i<json.paths.length;i++){
    if (board.path[json.paths[i].id])
      this.paths[i] = board.path[json.paths[i].id];
    else
      this.paths[i] = new OpenCatan.Board.Path(board, json.paths[i]);
  }
  if (this.piece) board.pieces.push(this);

  var self = this;
  this.init_canvas = function(x, y, canvas){
    self.draw_attributes = { 'x': x, 'y': y };
  };

  this.invisible = true;
  this.draw = function(canvas){
    if (self.piece) return;
    var context = canvas.context;
    var x = self.draw_attributes.x;
    var y = self.draw_attributes.y;
    context.fillStyle = !self.invisible ? "black" : "white";
    context.beginPath();
    var size = canvas.hex_width / 8;
    if (self.invisible) size+=2;
    context.arc(x, y, size, 0, Math.PI*2, true);
    context.fill();
  };
  this.draw_piece = function(canvas){
    var context = canvas.context;
    var x = self.draw_attributes.x;
    var y = self.draw_attributes.y;
    if (self.piece){
      var size = canvas.hex_width / 5;
      context.fillStyle = players[self.piece.owner];
      context.strokeStyle = "black";
      context.fillRect(x - size / 2,   y - size / 2, size, size);
      context.strokeRect(x - size / 2, y - size / 2, size, size);
      if (self.piece.type == "City"){
        context.beginPath();
        context.arc(x, y, size * 0.8, 0, Math.PI*2, true);
        context.stroke();
      }
    }
  };
};
OpenCatan.Board.Path = function(board, json){
  this.id = json.id;
  this.piece = json.piece
  this.intersections = [];
  board.path[this.id] = this;
  if (this.piece) board.pieces.push(this);
  this.invisible = true;

  var self = this;
  this.add_intersection = function(intersection){
    for (var i=0;i<self.intersections.length;i++){
      if (intersection.id == self.intersections[i].id) return;
    }
    self.intersections.push(intersection);
  };
  this.init_canvas = function(canvas){
    var x = (self.intersections[0].draw_attributes.x + self.intersections[1].draw_attributes.x)/2;
    var y = (self.intersections[0].draw_attributes.y + self.intersections[1].draw_attributes.y)/2;
    var angle;
    if (self.intersections[0].draw_attributes.y == self.intersections[1].draw_attributes.y)
      angle = 0;
    else if ((self.intersections[0].draw_attributes.x - self.intersections[1].draw_attributes.x)/
             (self.intersections[0].draw_attributes.y - self.intersections[1].draw_attributes.y) > 0)
      angle = Math.PI*4/3;
    else
      angle = Math.PI*-1/3;
    self.draw_attributes = { x: x, y: y, angle: angle };
  };

  this.draw = function(canvas){
    if (self.piece) return;
    var context = canvas.context;
    var x     = self.draw_attributes.x;
    var y     = self.draw_attributes.y;
    var angle = self.draw_attributes.angle;
    context.fillStyle = !self.invisible ? "black" : "white";
    var path_width  = canvas.hex_width / 10;
    var path_length = canvas.hex_width * 0.75;
    if (self.invisible) {
       path_width  += 2;
       path_length += 2;
    }

    context.save();
    context.translate(x, y);
    context.rotate(angle);
    context.beginPath();
    context.moveTo(-path_length/2, -path_width/2);
    context.lineTo( path_length/2, -path_width/2);
    context.lineTo( path_length/2,  path_width/2);
    context.lineTo(-path_length/2,  path_width/2);
    context.fill();
    context.restore();
  };
  this.draw_piece = function(canvas){
    var context = canvas.context;
    var x     = self.draw_attributes.x;
    var y     = self.draw_attributes.y;
    var angle = self.draw_attributes.angle;
    context.fillStyle = players[self.piece.owner];
    context.strokeStyle = "black";
    var path_width  = canvas.hex_width / 10;
    var path_length = canvas.hex_width * 0.75;

    context.save();
    context.translate(x, y);
    context.rotate(angle);
    context.beginPath();
    context.moveTo(-path_length/2, -path_width/2);
    context.lineTo( path_length/2, -path_width/2);
    context.lineTo( path_length/2,  path_width/2);
    context.lineTo(-path_length/2,  path_width/2);
    context.fill();
    context.stroke();
    context.restore();
  };
};

