require 'catan/piece'

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
    end
  end
end
