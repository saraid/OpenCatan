var Catan = function() {};

Catan.Draw = function() {};

Catan.Draw.init = function(origin) {
  this.board = $("#board").get(0);
  this.context = this.board.getContext('2d');
  this.origin = origin;
  //setInterval(this.loop, 10);
  this.loop();
}
Catan.Draw.draw_hex = function(x, y, edge, color) {
  this.context.fillStyle = color;
  this.context.beginPath();
  var vertices = [[x + (edge / 2)    , y],
                  [x + (3 * edge / 2), y],
                  [x + (2 * edge)    , y + (edge * 0.866)],
                  [x + (3 * edge / 2), y + (edge * 1.732)],
                  [x + (edge / 2)    , y + (edge * 1.732)],
                  [x                 , y + (edge * 0.866)]]
  this.context.moveTo(vertices[0][0], vertices[0][1]);
  for (i = 0; i < 6; i++)
    this.context.lineTo(vertices[i][0], vertices[i][1]);
  this.context.fill();
};
Catan.Draw
