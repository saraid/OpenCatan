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

    state_machine :game_state, :initial => :players_joining do
      event :start_game do
        transition :players_joining => :game_phase_1
      end

      event :end_phase_1 do
        transition :game_phase_1 => :game_phase_2
      end

      event :end_phase_2 do
        transition :game_phase_2 => :normal_play
      end

      event :game_over do
        transition :normal_play => :game_over
      end
    end

    attr_reader :players
    def add_player(player)
      @players << player
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

  end
end

module Kernel
  def log(*args)
    puts(*args)
  end
end
