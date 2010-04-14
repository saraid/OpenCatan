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

    def update_road_lengths
      roads = []
      road_pieces = @board.flatten.collect { |hex| hex.intersections.collect { |intersection|
        intersection.paths.select { |path| path.piece }
      }}.flatten.uniq
counter = 0
      road_pieces.each do |road_piece|
        next unless road_piece.is_a_trailhead?

        road = road_piece
        owner = road.piece.owner
        next_vertex = road.top_left_endpoint

        section_id = roads.length
        roads[section_id] = { :count => nil, :owner => owner.name, :paths => [] }
        until road.nil? || counter == 10 do
counter += 1
          roads[section_id][:paths] << { :vertex => next_vertex, :edge => road }
          current_path = roads[section_id][:paths].last
          next_vertex = current_path[:next_vertex] = current_path[:edge].other_side(current_path[:vertex])
          next_path = (next_vertex.piece && next_vertex.piece.owner == owner) || next_vertex.piece.nil?
          break unless next_path
          current_path[:forks] = next_vertex.paths.select do |path|
            path.piece && path.piece.owner == owner && path != road
          end
          current_path[:forks].delete road
          road = current_path[:forks].first
        end
      end
      roads
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
