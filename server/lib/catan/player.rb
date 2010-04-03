require 'catan/piece'

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
    class Turn
      attr_reader :game

      def initialize(player, game)
        @player = player
        @game = game
        @possible_actions = [ :Roll, :PlayCard ]
      end

      def do_roll
        roll = @player.act(Player::Action::Roll.new)
        log "Hexes with #{roll}: #{game.board.find_hexes_by_number(roll).join(',')}"
        game.board.find_hexes_by_number(roll).each do |hex|
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
