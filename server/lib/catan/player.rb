require 'catan/piece'
require 'catan/action'
require 'catan/turn'

module OpenCatan
  class Player

    attr_reader :name, :color, :controls_harbor_for
    def initialize(name, color)
      @name = name
      @color = color

      @resources = Catan::RESOURCES.clone
      @development_cards = []

      @knights_played = 0
      @longest_road   = 0

      @controls_harbor_for = Catan::RESOURCES.clone
      @controls_harbor_for.each_pair do |key, value|
        @controls_harbor_for[key] = false
      end
      @controls_harbor_for[:general] = false

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

  end
end
