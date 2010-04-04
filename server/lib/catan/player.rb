require 'catan/piece'
require 'catan/action'

module OpenCatan
  class Player

    attr_reader :name, :color
    def initialize(name, color)
      @name = name
      @color = color

      @resources = Catan::RESOURCES.clone
      @development_cards = []

      @knights_played = 0
      @longest_road   = 0

      @pieces_remaining = {}
      Piece.constants.each do |type|
        @pieces_remaining[type.downcase.to_sym] = []
        Piece.const_get(type).const_get(:AMOUNT_PER_PLAYER).times do |i|
          @pieces_remaining[type.downcase.to_sym] << Piece.const_get(type).new
        end
        @pieces_remaining[type.downcase.to_sym].each do |piece|
          piece.owner = self
        end
      end
    end

    def hand_size
      @resources.values.inject(0) do |sum, n| sum + n end
    end

    def play_piece(type)
      raise OpenCatanException, "Out of pieces" if @pieces_remaining[type].empty?
      @pieces_remaining[type].shift
    end

    def receive(resource)
      return if resource.nil?
      resource = @resources.keys.rand if resource == :gold # Hack it for now
      @resources[resource] = @resources[resource].succ
      log "#{name} receives 1 #{resource}"
    end

    attr_reader :game
    def join_game(game)
      @game = game
    end

    # A turn begins when the previous turn ends.
    # A turn ends when the player submits DONE.
    require 'state_machine'
    class Turn
      attr_reader :game

      def initialize(player, game)
        @player = player
        @game = game
        @actions = []
        super()
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

      def done
        @game.advance_player
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
            end
          end
        end
      end
      
    end
  end
end
