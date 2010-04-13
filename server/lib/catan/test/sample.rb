require 'catan/game'

@game = OpenCatan::Game.new
@game.rig!
np = 4
colors = ['red', 'orange', 'blue', 'white']
Array.new(np).each_with_index do |meh, x|
  OpenCatan::Player.new("Player #{x}", colors[x]).join_game(@game)
end

rolls = @game.players.collect do |player| player.act(OpenCatan::Player::Action::Roll.new) end
@game.player_pointer = rolls.index rolls.max
log
log "#{@game.players[@game.player_pointer].name} goes first!"

board = @game.board
rows    = [4, 1, 1, 3, 8, 2, 4, 7]
offsets = [1, 3, 1, 2, 3, 2, 2, 3]

np.times do |i|
  intersection = board[rows[i]][offsets[i]].intersections.first
  @game.current_player.act(OpenCatan::Player::Action::PlaceSettlement.on(intersection))
  @game.current_player.act(OpenCatan::Player::Action::PlaceRoad.on(intersection.paths.first))
  @game.advance_player
end
np.times do |i|
  @game.reverse_pointer
  intersection = board[rows[np+i]][offsets[np+i]].intersections.first
  @game.current_player.act(OpenCatan::Player::Action::PlaceSettlement.on(intersection))
  intersection.hexes.each do |hex|
    @game.current_player.receive hex.product
  end
  @game.current_player.act(OpenCatan::Player::Action::PlaceRoad.on(intersection.paths.first))
end

@game.dice.remember
@game.start_game

@game.status
@game.players[3].submit_command "spend", "{\"wood\":1}"

@game.current_player.submit_command "roll" # Player 0
@game.current_player.submit_command "buy", "road"
@game.current_player.submit_command "place", "road", "75-105"
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Player 1
@game.current_player.submit_command "buy", "card"
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Player 2
@game.status
@game.players[0].submit_command     "spend", "{\"wheat\":1}"
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Player 3
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Player 0
@game.status
@game.players[3].submit_command     "spend", "{\"wood\":1}"
@game.current_player.submit_command "buy", "settlement"
@game.current_player.submit_command "place", "settlement", "105"
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Player 1
@game.current_player.submit_command "buy", "card"
@game.current_player.submit_command "play", "50"
@game.current_player.submit_command "spend", "{\"wood\":1,\"clay\":1}"
@game.current_player.submit_command "buy", "road"
@game.current_player.submit_command "place", "road", "30-31"
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Player 2
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Player 3
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Player 0
@game.players[3].submit_command     "spend", "{\"wheat\":1}"
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Player 1
@game.current_player.submit_command "play", "42"
@game.current_player.submit_command "place", "road", "30-37"
@game.current_player.submit_command "place", "road", "37-7"
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Player 2
@game.players[3].submit_command     "spend", "{\"wheat\":1}"
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Player 3
@game.current_player.submit_command "buy", "city"
@game.current_player.submit_command "upgrade", "217"
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Player 0
@game.players[3].submit_command     "spend", "{\"wheat\":1,\"ore\":1}"
@game.current_player.submit_command "done"
