require 'catan/catan'
require 'catan/board'
require 'catan/player'
require 'catan/action'
require 'catan/development_card'
require 'catan/dice'

module OpenCatan

  class Game
    def initialize
      @deck = Deck.new
      @dice = Dice.new
      @board = Board.deserialize_from_yaml("catan/sample/meh5x9_num.yml")
      @players = []
      @player_pointer = nil
    end
    attr_reader :dice, :deck, :board
    attr_accessor :player_pointer

    def rig!
      @dice = LoadedDice.new
      @deck = RiggedDeck.new
    end

    attr_reader :players
    def add_player(player)
      @players << player
      player.join_game(self)
    end

    def log_action(action)
      @actions ||= []
      @actions << action
    end

    def start_game
      @turns = []
      @turns << Player::Turn.new(current_player, self)
    end

    def current_player
      @players[@player_pointer]
    end

    def current_turn
      @turns.last
    end

    def advance_player
      @player_pointer = @player_pointer.succ
      @player_pointer = 0 if @player_pointer == @players.length
      @turns << Player::Turn.new(current_player, self) if @turns
    end

    def reverse_pointer
      @player_pointer = @player_pointer - 1
      @player_pointer = @players.length - 1 if @player_pointer == -1
    end

    def status
      log(current_turn.inspect)
      log(players.collect do |player| "#{player.name}: #{player.resources.inspect}" end)
    end

    def self.test
      game = Game.new
      game.rig!
p game.deck
      np = 4
      colors = ['red', 'orange', 'blue', 'white']
      np.times do |x| game.add_player(Player.new("Player #{x}", colors[x])) end

      rolls = game.players.collect do |player| player.act(Player::Action::Roll.new) end
      game.player_pointer = rolls.index rolls.max
      log
      log "#{game.players[game.player_pointer].name} goes first!"

      board = game.board
      rows    = [4, 1, 1, 3, 8, 2, 4, 7]
      offsets = [1, 3, 1, 2, 3, 2, 2, 3]

      np.times do |i|
        intersection = board[rows[i]][offsets[i]].intersections.first
        game.current_player.act(Player::Action::PlaceSettlement.on(intersection))
        game.current_player.act(Player::Action::PlaceRoad.on(intersection.paths.first))
        game.advance_player
      end
      np.times do |i|
        game.reverse_pointer
        intersection = board[rows[np+i]][offsets[np+i]].intersections.first
        game.current_player.act(Player::Action::PlaceSettlement.on(intersection))
        intersection.hexes.each do |hex|
          game.current_player.receive hex.product
        end
        game.current_player.act(Player::Action::PlaceRoad.on(intersection.paths.first))
      end

      game.dice.remember
      game.start_game

      game.status
      game.players[3].submit_command "spend", "{\"wood\":1}"

      game.current_player.submit_command "roll" # Player 0
      game.current_player.submit_command "buy", "road"
      game.current_player.submit_command "place", "road", "75-105"
      game.current_player.submit_command "done"

      game.current_player.submit_command "roll" # Player 1
      game.current_player.submit_command "buy", "card"
      game.current_player.submit_command "done"

      game.current_player.submit_command "roll" # Player 2
      game.status
      game.players[0].submit_command     "spend", "{\"wheat\":1}"
      game.current_player.submit_command "done"

      game.current_player.submit_command "roll" # Player 3
      game.current_player.submit_command "done"

      game.current_player.submit_command "roll" # Player 0
      game.status
      game.players[3].submit_command     "spend", "{\"wood\":1}"
      game.current_player.submit_command "buy", "settlement"
      game.current_player.submit_command "place", "settlement", "105"
      game.current_player.submit_command "done"

      game.current_player.submit_command "roll" # Player 1
      game.current_player.submit_command "buy", "card"
      game.current_player.submit_command "play", "50"
      game.current_player.submit_command "spend", "{\"wood\":1,\"clay\":1}"
      game.current_player.submit_command "buy", "road"
      game.current_player.submit_command "place", "road", "30-31"
      game.current_player.submit_command "done"

      game.current_player.submit_command "roll" # Player 2
      game.current_player.submit_command "done"

      game.current_player.submit_command "roll" # Player 3
      game.current_player.submit_command "done"

      game.current_player.submit_command "roll" # Player 0
      game.current_player.submit_command "done"

      game.current_player.submit_command "roll" # Player 1
      game.current_player.submit_command "play", "42"
      game.current_player.submit_command "place", "road", "30-37"
      game.current_player.submit_command "place", "road", "37-7"
      game.current_player.submit_command "done"

      game
    end
  end
end

module Kernel
  def log(*args)
    puts(*args)
  end
end
