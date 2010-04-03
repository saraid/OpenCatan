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

    def play_piece(type)
      raise OpenCatanException, "Out of pieces" if @pieces_remaining[type].empty?
      @pieces_remaining[type].shift
    end

    attr_reader :game
    def join_game(game)
      @game = game
    end

    # A turn begins when the previous turn ends.
    # A turn ends when the player submits DONE.
    class Turn
      attr_reader :game

      def initialize(game)
        @game = game
      end
    end

    class Action
    end
  end
end
