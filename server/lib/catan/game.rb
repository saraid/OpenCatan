require 'catan/board2'
require 'catan/player'
require 'catan/action'
require 'catan/development_card'

module OpenCatan
  class Game
    def initialize
      @deck = Deck.new
      @dice = Dice.new
      @board = Board.deserialize_from_yaml("lib/catan/sample/vanilla3x5.yml")
      @players = []
      @player_pointer = nil
    end
    attr_reader :dice, :deck
    attr_accessor :player_pointer

    attr_reader :players
    def add_player(player)
      @players << player
      player.join_game(self)
    end

    def self.test
      require 'random_data'
      game = Game.new
      5.times do |x| game.add_player(Player.new(Random.firstname, Random.color)) end

      rolls = game.players.collect do |player| player.act(Player::Action::Roll.new) end
      game.player_pointer = rolls.index rolls.max
      log "#{game.players[game.player_pointer].name} goes first!"

      game
    end
  end
end

module Kernel
  def log(*args)
    puts(*args)
  end
end
