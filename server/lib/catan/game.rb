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
      @board = Board.deserialize_from_yaml("lib/catan/sample/meh5x9.yml")
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

    def self.test
      require 'random_data'
      game = Game.new
      np = 4
      np.times do |x| game.add_player(Player.new(Random.firstname, Random.color)) end

      rolls = game.players.collect do |player| player.act(Player::Action::Roll.new) end
      game.player_pointer = rolls.index rolls.max
      log
      log "#{game.players[game.player_pointer].name} goes first!"

      board = game.board
      rows    = [4, 1, 1, 3, 2, 4, 7, 8, 2, 4]
      offsets = [1, 3, 1, 1, 2, 2, 3, 3, 4, 4]

      np.times do |i|
        intersection = board[rows[i]][offsets[i]].intersections.first
        game.current_player.act(Player::Action::PlaceSettlement.on(intersection))
        game.current_player.act(Player::Action::PlaceRoad.on(intersection.paths.rand))
        game.advance_player
      end
      np.times do |i|
        game.reverse_pointer
        intersection = board[rows[np+i]][offsets[np+i]].intersections.first
        game.current_player.act(Player::Action::PlaceSettlement.on(intersection))
        intersection.hexes.each do |hex|
          game.current_player.receive hex.product
        end
        game.current_player.act(Player::Action::PlaceRoad.on(intersection.paths.rand))
      end

      game.dice.remember
      game.start_game

      10.times do |i|
        game.current_turn.do_roll
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
