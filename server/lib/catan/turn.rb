require 'catan/action'

module OpenCatan
  class Player
    # A turn begins when the previous turn ends.
    # A turn ends when the player submits DONE.
    require 'state_machine'
    class Turn
      attr_reader :game

      def initialize(player, game)
        @player = player
        @game = game
        @actions = []
        @turn_state = TurnState.new
        super()
      end
      attr_reader :turn_state

      class TurnState
        def initialize
          @status = 'ok'
        end

        def roll_result(player, resource)
          @roll_results ||= {}
          @roll_results[player.name] ||= {}
          @roll_results[player.name][resource] ||= 0
          @roll_results[player.name][resource] = @roll_results[player.name][resource].succ
          gold_holders = @roll_results.select { |name, player| player[:gold] }.collect do |x| x.first end
          @status = "Waiting for #{gold_holders.join(', ')}" unless gold_holders.empty?
        end

        def inspect
          roll_results = []
          @roll_results.each_pair do |name, player|
            roll_results << "#{name} collected #{player.collect { |resource, amount| "#{amount} #{resource}" }.join(', ')}"
          end if @roll_results
          { :status => @status,
            :roll_results => roll_results
          }.inspect
        end
        def to_s; inspect; end

        def to_json
        end
      end

      state_machine :dice_state, :namespace => 'dice', :action => :roll, :initial => :rolling do 
        event :roll do
          transition :rolling => :rolled
        end
      end

      state_machine :robber_state, :initial => :robber_unmoved do
        after_transition :on => :rolled_a_seven do |x, y| log "Rolled a 7!" end
        event :rolled_a_seven do
          transition :robber_unmoved => :discard_cards
        end
        event :play_knight do
          transition :robber_unmoved => :place_robber
        end
        event :discarding_done do
          transition :discard_cards => :place_robber
        end
        event :place_robber do
          transition :place_robber => :stealing_cards
        end
        event :cards_stolen do
          transition :stealing_cards => :robber_unmoved
        end
      end

      state_machine :purchase_state, :initial => :nothing do
        event :buy_card do
          transition :nothing => same
        end
        event :buy_settlement, :buy_road, :buy_boat do
          transition :nothing => :placing_piece
        end
        event :place_piece do
          transition :placing_piece => :nothing
        end
      end

      # Done Action
      def done
        @done = true
        @game.advance_player
        return self
      end
      def done?; @done; end

      # Buy Actions
      def buy_settlement
        @player.act(Player::Action::BuySettlement.new) if super
      end
      def buy_road
        @player.act(Player::Action::BuyRoad.new) if super
      end
      def buy_boat
        @player.act(Player::Action::BuyBoat.new) if super
      end
      def buy_city
        @player.act(Player::Action::BuyCity.new) if super
      end
      def buy_card
        @player.act(Player::Action::BuyCard.new) if super
      end

      # Place Actions
      def place_settlement(intersection)
        @player.act(Player::Action::PlaceSettlement.on(@game.board.find_intersection(intersection))) if place_piece
      end
      def place_road(path)
        @player.act(Player::Action::PlaceRoad.on(@game.board.find_path(path))) if place_piece
      end
      def place_boat(path)
        @player.act(Player::Action::PlaceBoat.on(@game.board.find_path(path))) if place_piece
      end
      def upgrade(intersection)
        @player.act(Player::Action::UpgradeSettlement.on(@game.board.find_intersection(intersection))) if place_piece
      end

      # Spend Action
      def spend_gold(player, resource_hash)
        resources = JSON.parse(resource_hash)
        resources.each_pair do |resource, amount|
          amount.times do |x| player.receive(resource.to_sym) end
        end
        player.gold_spent!
      end

      private
      def roll
        @roll = @player.act(Player::Action::Roll.new)
        rolled_a_seven and return if @roll == 7
        log "Hexes with #{@roll}: #{game.board.find_hexes_by_number(@roll).join(',')}"
        game.board.find_hexes_by_number(@roll).each do |hex|
          if hex.has_robber?
            log "#{hex} is being robbed!"
            next
          end
          hex.intersections.each do |intersection|
            if intersection.piece
              intersection.piece.owner.receive hex.product
              turn_state.roll_result(intersection.piece.owner, hex.product)
            end
          end
        end
      end
      
    end
  end
end
