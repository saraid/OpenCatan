require 'catan/catan'
require 'catan/board'
require 'catan/player'
require 'catan/action'
require 'catan/development_card'
require 'catan/dice'
require 'uuidtools'

module OpenCatan

  class Game
    def initialize
      @id = UUIDTools::UUID.random_create.to_s
      @deck = Deck.new
      @dice = Dice.new
      @board = Board.deserialize_from_yaml("lib/catan/sample/meh5x9_num.yml")
      @players = []
      @player_pointer = nil

      @longest_road = nil
      @largest_army = nil

      @robber = Piece::Robber.new

      start_state_machine # Why is the state_machine not working!? I don't know!
    end
    attr_reader :id, :dice, :deck, :board, :players, :robber

    state_machine :game_state, :initial => :players_joining do
      event :start_state_machine do transition nil => :players_joining end
      event :start_game do
        transition :players_joining => :determining_turn_order
      end

      event :setup do
        transition :determining_turn_order => :placing_settlements,         :if => :turn_order?
        transition :placing_settlements => :placing_settlements_in_reverse, :if => :phase_1_done?
        transition :placing_settlements_in_reverse => :normal_play,         :if => :phase_2_done?
        transition all => same
      end
      before_transition :to => :normal_play, :do => :setup_turns

      event :game_over do
        transition :normal_play => :game_over
      end
    end

    def add_player(player)
      @players << player
    end

    def log_action(action)
      @actions ||= []
      @actions << action
    end

    def game_actions
      (@actions || []).select do |action| !action.is_a? Player::Action::Chat end
    end

    def setting_up?
      ['determining_turn_order',
       'placing_settlements',
       'placing_settlements_in_reverse'
      ].include? game_state
    end

    def setup_turns
      @turns = []
      @turns << Player::Turn.new(self)
    end

    def turn_order?
      if game_actions.length == 4
        rolls = game_actions.collect { |roll_action| roll_action.roll }
        @player_pointer = rolls.index rolls.max
      end
      @player_pointer.present?
    end

    def phase_1_done?
      @setup_turn.setup_methods[:place_settlement] == @players.length
    end

    def phase_2_done?
      @setup_turn.setup_methods[:place_settlement] == (2 * @players.length)
    end

    def current_player
      @players[@player_pointer]
    end

    def current_turn
      return @turns.last if game_state == 'normal_play'
      setup and return @setup_turn ||= SetupTurn.new(self)
    end

    def advance_player
      @player_pointer = @player_pointer.succ
      @player_pointer = 0 if @player_pointer == @players.length
      @turns << Player::Turn.new(self) if @turns
    end

    def reverse_pointer
      @player_pointer = @player_pointer - 1
      @player_pointer = @players.length - 1 if @player_pointer == -1
    end

    def update_road_lengths
      return if self.setting_up?
      roads = []
      # Get all road pieces.
      road_pieces = @board.flatten.collect { |hex| hex.intersections.collect { |intersection|
        intersection.paths.select { |path| path.piece }
      }}.flatten.uniq
      road_pieces.each do |road_piece|
        next unless road_piece.is_a_trailhead?

        # We have a new group of roads to count.
        road = road_piece
        owner = road.piece.owner
        next_vertex = road.top_left_endpoint

        section_id = roads.length
        roads[section_id] = { :count => 0, :owner => owner, :paths => [] }
        current_path_count = 0
        # Walk the trail until we hit the final endpoint.
        until road.nil? do
          current_path_count += 1
          roads[section_id][:paths] << { :vertex => next_vertex, :edge => road }
          current_path = roads[section_id][:paths].last
          next_vertex = current_path[:next_vertex] = current_path[:edge].other_side(current_path[:vertex])
          # FIXME: Using 'break' here is the wrong method. We need to unravel to test other forks, not stop the loop.
          break if roads[section_id][:paths].collect { |tmp| tmp[:vertex] }.include?(next_vertex) # Test for cycles
          next_path = (next_vertex.piece && next_vertex.piece.owner == owner) || next_vertex.piece.nil?
          break unless next_path # If there is a settlement in the way, we're done.
          current_path[:forks] = next_vertex.paths.select do |path|
            path.piece && path.piece.owner == owner && path != road \
            && (path.piece.class == road.piece.class || next_vertex.piece.present?) # road-boat transitions need a settlement
                                                                                    # We already know it's the right owner.
          end
          road = current_path[:forks].first

          # We've hit an endpoint. Rewind and count passed-by forks.
          if road.nil?
            current_path[:next_vertex] = nil
            roads[section_id][:count] = current_path_count if current_path_count > roads[section_id][:count]
            # Walk back to find a fork.
            next_path = (roads[section_id][:paths].reverse.detect do |piece|
              current_path_count -= 1
              piece[:forks].length == 2 \
              && !roads[section_id][:paths].collect { |tmp| tmp[:edge] }.include?(piece[:forks].last)
            end || {:forks => []})
            road = next_path[:forks].last
            next_vertex = road.other_side(next_path[:vertex]) if road
          end
        end
      end

      # Find the longest road among all players.
      longest_road = 0
      @players.each do |player|
        player.longest_road = roads.select { |x| x[:owner] == player }.max { |a,b| a[:count] <=> b[:count] }[:count]
        longest_road = player.longest_road if longest_road < player.longest_road
      end
      top_ranked = @players.select do |player| player.longest_road == longest_road end
      # You can lose longest_road.
      @longest_road = (longest_road >= 5 && top_ranked.length == 1) ? top_ranked.first : nil

      roads.each { |x| x[:owner] = x[:owner].name } # for debugging
    end

    def update_army_sizes
      largest_army = @players.collect { |player| player.knights_played }.max
      top_ranked = @players.select do |player| player.knights_played == largest_army end
      @largest_army = (largest_army >= 3 && top_ranked.length == 1) ? top_ranked.first : @largest_army
    end

    def calculate_victory_points
      @victory_points = {}
      @players.each do |player|
        @victory_points[player]  = 0
        @victory_points[player] += player.landfalls 
        @victory_points[player] += player.vp_cards_used
      end
      towns = @board.flatten.collect do |hex| hex.intersections.select do |intersection| intersection.piece.present? end end.flatten
      towns.uniq!
      towns.each do |town|
        @victory_points[town.piece.owner] += case
          when Piece::Settlement; 1
          when Piece::City;       2
        end
      end
      @victory_points[@longest_road] += 2 if @longest_road
      @victory_points[@largest_army] += 2 if @largest_army
    end

    def status
      log(current_turn.inspect)
      log(players.collect do |player|
        "#{"%6s" % player.name}: #{player.resources.inspect}; Hand: #{player.hand_size}; VPs: #{@victory_points[player]}"
      end)
    end

  end
end

module Kernel
  def log(*args)
    puts(*args)
  end
end
