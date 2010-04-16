require 'catan/action'
require 'catan/trade'

module OpenCatan
  class TurnStateException < OpenCatanException; end

  class Player
    # A turn begins when the previous turn ends.
    # A turn ends when the player submits DONE.
    class Turn
      def initialize(game)
        @game = game
        @actions = []
        @trades  = []
        @status = 'ok'
        super()
      end

      def to_s; inspect; end
      def to_json; summary.to_json; end
      def inspect; summary.inspect; end

      state_machine :dice_state, :namespace => 'dice', :initial => :rolling do 
        event :roll do
          transition :rolling => :rolled
        end
      end

      state_machine :robber_state, :initial => :robber_unmoved do
        after_transition :on => :rolled_a_seven do |x, y| log "Rolled a 7!" end
        after_transition :to => :discarding_cards, :do => :check_hand_sizes
        event :rolled_a_seven do
          transition :robber_unmoved => :discarding_cards
        end
        event :play_knight do
          transition :robber_unmoved => :place_robber
        end
        event :discarding_done do
          transition :discarding_cards => :place_robber
        end
        event :place_robber do
          transition :place_robber => :stealing_cards
        end
        event :choose_robber_victim do
          transition :stealing_cards => :robber_unmoved
        end
      end
      def play_knight
        super
        @game.update_army_sizes
      end

      state_machine :purchase_state, :initial => :nothing do
        event :buy_card do
          transition :nothing => same, :if => :dice_rolled?
        end
        event :buy_settlement, :buy_road, :buy_boat, :buy_city, :road_building do
          transition :nothing => :placing_piece, :if => :dice_rolled?
        end
        event :place_piece do
          transition :placing_piece => :nothing, :if => :road_building_done?
          transition :placing_piece => same
        end
      end

      state_machine :monopoly_state, :initial => :nothing do
        event :play_monopoly do
          transition :nothing => :monopolizing
        end
        event :choose_monopolized_resource do
          transition :monopolizing => :nothing
        end
      end

      state_machine :trade_state, :initial => :nothing do
        event :propose do
          transition all => :trading
        end
        event :respond do
          transition :trading => same
        end
        event :accept, :cancel do
          transition :trading => :nothing
        end
      end

      # Roll Action
      def roll_dice(player)
        super
        @roll = player.act(Player::Action::Roll.new)
        return if @game.setting_up?
        rolled_a_seven and return if @roll == 7
        log "Hexes with #{@roll}: #{@game.board.find_hexes_by_number(@roll).join(',')}"
        @game.board.find_hexes_by_number(@roll).each do |hex|
          if hex.has_robber?
            log "#{hex} is being robbed!"
            next
          end
          hex.intersections.each do |intersection|
            (case intersection.piece
            when Piece::Settlement
              1
            when Piece::City
              2
            else
              0
            end).times do |x|
              intersection.piece.owner.receive hex.product
              roll_result(intersection.piece.owner, hex.product)
            end
          end
        end
      end

      # Done Action
      def done
        update_status
        raise TurnStateException, @status if @status != 'ok'
        @current_trade.cancel! if @current_trade
        @done = true
        @game.status
        @game.advance_player
        return self
      end
      def done?; @done; end

      # Buy Actions
      def buy_settlement(player)
        player.act(Player::Action::BuySettlement.new) if super
      end
      def buy_road(player)
        player.act(Player::Action::BuyRoad.new) if super
      end
      def buy_boat(player)
        player.act(Player::Action::BuyBoat.new) if super
      end
      def buy_city(player)
        player.act(Player::Action::BuyCity.new) if super
      end
      def buy_card(player)
        player.act(Player::Action::BuyCard.new) if super
      end

      # Place Actions
      def place_settlement(player, intersection)
        intersection = @game.board.find_intersection(intersection)
        player.act(Player::Action::PlaceSettlement.on(intersection)) if @game.setting_up? || place_piece
        intersection.hexes.each do |hex| player.receive hex.product end if @game.placing_settlements_in_reverse?
        @game.update_road_lengths
      end
      def place_road(player, path)
        @roads_to_build -= 1 if @roads_to_build
        player.act(Player::Action::PlaceRoad.on(@game.board.find_path(path))) if @game.setting_up? || place_piece
        @game.update_road_lengths
      end
      def place_boat(player, path)
        player.act(Player::Action::PlaceBoat.on(@game.board.find_path(path))) if @game.setting_up? || place_piece
        @game.update_road_lengths
      end
      def upgrade(player, intersection)
        player.act(Player::Action::UpgradeSettlement.on(@game.board.find_intersection(intersection))) if place_piece
      end
      def place_robber(player, hex)
        hex = hex.split(',').collect do |i| i.to_i end
        hex = @game.board[hex.first][hex.last]
        player.act(Player::Action::PlaceRobber.on(hex)) if super
        @stealables = hex.intersections.collect do |i| i.piece.owner if i.piece end.compact
        @stealables.reject! do |player| player.hand_size.zero? end
        choose_robber_victim(player, @stealables.first) if @stealables.length == 1
        choose_robber_victim(nil, nil) if @stealables.empty?
      end

      # Spend Action
      def spend_gold(player, resource_hash) # This should really go into an Action subclass
        resources = JSON.parse(resource_hash)
        resources.each_pair do |resource, amount|
          amount.times do |x| player.receive(resource.to_sym, true) end
        end
      end

      # Discard Action
      def discard(player, resource_hash) # This should really go into an Action subclass
        resources = JSON.parse(resource_hash)
        resources.each_pair do |resource, amount|
          player.resources[resource.to_sym] -= amount
        end
        @needs_to_discard[player] -= resources.inject(0) { |sum, n| sum + n.last }
        @needs_to_discard.delete player if @needs_to_discard[player].zero?
        discarding_done if @needs_to_discard.empty?
      end

      # Play Action
      def play_card(player, card)
        card = player.get_card(card)
        player.act(Player::Action::PlayCard.new(card))
      end

      # Choose Action
      def choose(player, option)
        choose_monopolized_resource(player, option) if Catan::RESOURCES.keys.include? option.to_sym
        choose_robber_victim(player, option)
      end

      def choose_robber_victim(player, victim)
        return super if player.nil?
        victim = victim.respond_to?(:resources) ? victim : @game.players[victim.to_i]
        player.act(Player::Action::ChooseVictim.new(victim)) if super
      end

      def choose_monopolized_resource(player, resource)
        super
        resource = resource.to_sym
        @game.players.select { |victim| victim != player }.each do |victim|
          amount = victim.lose(resource)
          log "#{player.name} stole #{amount} #{resource} from #{victim.name}"
          amount.times do |i| player.receive resource end
        end
      end

      # Trade Actions
      def propose(player, offer, demand, limited_to)
        super
        @trades << TradeNegotiation.new(@game, player, limited_to) unless @trades.last && @trades.last.status == :pending
        @current_trade = @trades.last
        @current_trade.propose(player, offer, demand)
      end

      def respond(player, message)
        @current_trade.respond(player, message) if super
      end

      def accept(player, offer)
        offer = @game.players[offer.to_i]
        @current_trade.accept(offer) if @current_trade.initiator == player && super
      end

      def cancel(player)
        @current_trade.cancel! if @current_trade.initiator == player && super
      end

      private
      def road_building
        @roads_to_build = 2 if super
      end
      def road_building_done?
        @roads_to_build == 0 || @roads_to_build.nil?
      end

      def check_hand_sizes
        @needs_to_discard ||= {}
        @game.players.each do |player|
          @needs_to_discard[player] = player.hand_size / 2 if player.hand_size >= 7
        end
      end

      def roll_result(player, resource)
        @roll_results ||= {}
        @roll_results[player] ||= {}
        @roll_results[player][resource] ||= 0
        @roll_results[player][resource] = @roll_results[player][resource].succ
        update_status
      end

      def update_status
        @needs_to_discard ||= {}
        @gold_holders = @game.players.select do |player| player.has_gold? end
        @status = "Waiting for #{@gold_holders.collect { |player| player.name }.join(', ')} to spend gold." and return unless @gold_holders.empty?
        if robber_state != 'robber_unmoved'
          case robber_state
          when 'discarding_cards'
          @status = "Waiting for #{@needs_to_discard.keys.collect { |player| player.name }.join(', ')} to discard cards" and return
          when 'stealing_cards'
          @status = "Waiting for #{@game.current_player.name} to steal cards. Options: #{@stealables.collect { |player| player.name }}." and return
          end
        end
        @status = 'Purchasing' and return if purchase_state != 'nothing'
        @status = 'ok'
      end

      def summary
        update_status
        roll_results = []
        @roll_results.each_pair do |player, resources|
          roll_results << "#{player.name} collected #{resources.collect { |resource, amount| "#{amount} #{resource}" }.join(', ')}"
        end if @roll_results
        { :status => @status,
          :roll_results => roll_results
        }
      end

    end

  end

  class SetupTurn
    def initialize(game)
      @placeholder_turn = Player::Turn.new(game)
      @setup_methods = {:roll_dice => 0, :place_settlement => 0, :place_road => nil, :spend_gold => nil}
    end
    attr_reader :setup_methods

    def method_missing(id, *args, &block)
      if @setup_methods.keys.include? id
        @setup_methods[id] += 1 if @setup_methods[id]
        return @placeholder_turn.send(id, *args, &block)
      end
      super
    end
  end
end
