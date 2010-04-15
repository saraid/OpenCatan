require 'catan/game'

@game = OpenCatan::Game.new
@game.rig!
np = 4
colors = ['red', 'orange', 'blue', 'white']
Array.new(np).each_with_index do |meh, x|
  OpenCatan::Player.new(colors[x].capitalize, colors[x]).join_game(@game)
end

@game.start_game

@game.players[0].submit_command "roll"
@game.players[1].submit_command "roll"
@game.players[2].submit_command "roll"
@game.players[3].submit_command "roll"

log
@game.players[0].submit_command "place", "settlement", "76"
@game.players[0].submit_command "place", "road", "76-75"
@game.players[1].submit_command "place", "settlement", "34"
@game.players[1].submit_command "place", "road", "8-34"
@game.players[2].submit_command "place", "settlement", "26"
@game.players[2].submit_command "place", "road", "4-26"
@game.players[3].submit_command "place", "settlement", "57"
@game.players[3].submit_command "place", "road", "57-56"

log
@game.players[3].submit_command "place", "settlement", "196"
@game.players[3].submit_command "place", "road", "196-164"
@game.players[2].submit_command "place", "settlement", "82"
@game.players[2].submit_command "place", "road", "82-81"
@game.players[1].submit_command "place", "settlement", "32"
@game.players[1].submit_command "place", "road", "32-31"
@game.players[0].submit_command "place", "settlement", "171"
@game.players[0].submit_command "place", "road", "171-170"

log
@game.status
@game.players[3].submit_command "spend", "{\"wood\":1}"

log
@game.current_player.submit_command "roll" # Red
@game.current_player.submit_command "buy", "road"
@game.current_player.submit_command "place", "road", "75-105"
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Orange
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Blue
@game.players[0].submit_command     "spend", "{\"wheat\":1}"
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # White
@game.current_player.submit_command "buy", "road"
@game.current_player.submit_command "place", "road", "56-88"
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Red
@game.players[3].submit_command     "spend", "{\"wheat\":1}"
@game.current_player.submit_command "buy", "settlement"
@game.current_player.submit_command "place", "settlement", "105"
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Orange
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Blue
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # White
@game.current_player.submit_command "buy", "card"
@game.current_player.submit_command "play", "50"
@game.current_player.submit_command "spend", "{\"wood\":1,\"clay\":1}"
@game.current_player.submit_command "buy", "road"
@game.current_player.submit_command "place", "road", "164-142"
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Red
@game.players[3].submit_command     "spend", "{\"wheat\":1}"
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Orange
@game.players[3].submit_command     "spend", "{\"wheat\":1}"
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Blue
@game.players[3].submit_command     "spend", "{\"ore\":1}"
@game.current_player.submit_command "buy", "city"
@game.current_player.submit_command "upgrade", "82"
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # White
@game.current_player.submit_command "buy", "card"
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Red
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Orange
@game.players[3].submit_command     "spend", "{\"wheat\":1}"
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Blue
@game.current_player.submit_command "buy", "card"
@game.current_player.submit_command "buy", "card"
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # White
@game.current_player.submit_command "buy", "city"
@game.current_player.submit_command "upgrade", "196"
@game.current_player.submit_command "play", "42"
@game.current_player.submit_command "place", "road", "142-110"
@game.current_player.submit_command "place", "road", "88-110"
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Red
@game.players[3].submit_command     "spend", "{\"wood\":2}"
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Orange
@game.players[3].submit_command     "spend", "{\"clay\":1,\"wheat\":1}"
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Blue
@game.players[3].submit_command     "spend", "{\"sheep\":1,\"wheat\":1}"
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # White
@game.current_player.submit_command "buy", "road"
@game.current_player.submit_command "place", "road", "88-87"
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Red
@game.status
@game.players[0].submit_command     "discard", "{\"ore\":4}"
@game.players[2].submit_command     "discard", "{\"ore\":5,\"wheat\":1}"
@game.players[3].submit_command     "discard", "{\"ore\":2,\"wood\":1,\"clay\":1}"
@game.current_player.submit_command "place", "robber", "2,2"
@game.current_player.submit_command "choose", "2"
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Orange
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Blue
@game.current_player.submit_command "buy", "card"
@game.current_player.submit_command "play", "32"
@game.current_player.submit_command "place", "robber", "5,3"
@game.current_player.submit_command "play", "35"
@game.current_player.submit_command "place", "robber", "6,3"
@game.current_player.submit_command "choose", "0"
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # White
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Red
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Orange
@game.current_player.submit_command "done"

@game.current_player.submit_command "roll" # Blue
@game.current_player.submit_command "play", "31"
@game.current_player.submit_command "place", "robber", "8,0"
@game.current_player.submit_command "done"

