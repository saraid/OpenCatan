require 'catan/board2'
require 'catan/player'
require 'catan/action'
require 'catan/development_card'
require 'catan/dice'

module OpenCatan
  class OpenCatanException < StandardError; end

  class Game
    def initialize
      @deck = Deck.new
      @dice = Dice.new
      @board = Board.deserialize_from_yaml("lib/catan/sample/vanilla3x5.yml")
      @players = []
      @player_pointer = nil
    end
    attr_reader :dice, :deck, :board
    attr_accessor :player_pointer

    attr_reader :players
    def add_player(player)
      @players << player
      player.join_game(self)
    end

    def current_player
      @players[@player_pointer]
    end

    def advance_player
      @player_pointer = @player_pointer.succ
      @player_pointer = 0 if @player_pointer == @players.length
    end

    def self.test
      require 'random_data'
      game = Game.new
      5.times do |x| game.add_player(Player.new(Random.firstname, Random.color)) end

      rolls = game.players.collect do |player| player.act(Player::Action::Roll.new) end
      game.player_pointer = rolls.index rolls.max
      log "#{game.players[game.player_pointer].name} goes first!"

      board = game.board
      5.times do |x|
        intersection = board[2][1].intersections.rand
        game.current_player.act(Player::Action::PlaceSettlement.on(intersection))
        game.current_player.act(Player::Action::PlaceRoad.on(intersection.paths.rand))
        game.advance_player
      end

      game
    end
  end
end

module Kernel
  def log(*args)
    puts(*args)
  end
end
