require 'catan/piece'
require 'catan/action'
require 'catan/turn'

module OpenCatan
  class Player

    attr_reader :name, :color, :controls_trade_hub_for, :resources
    def initialize(name, color)
      @name = name
      @color = color

      @resources = Catan::RESOURCES.clone
      @development_cards = []
      @gold = 0

      @knights_played = 0
      @longest_road   = 0

      @controls_trade_hub_for = Catan::RESOURCES.clone
      @controls_trade_hub_for.each_pair do |key, value|
        @controls_trade_hub_for[key] = false
      end
      @controls_trade_hub_for[:general] = false

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

    def get_card(card_id)
      @development_cards.detect do |card| card.id == card_id.to_i end
    end

    def play_piece(type)
      raise OpenCatanException, "Out of pieces" if @pieces_remaining[type].empty?
      @pieces_remaining[type].shift
    end

    def receive_piece(type, piece)
      @pieces_remaining[type] << piece
    end

    def receive(resource)
      return if resource.nil?
      log "#{name} receives 1 #{resource}"
      @gold = @gold.succ and return if resource == :gold
      @resources[resource] = @resources[resource].succ
    end

    def has_gold?
      @gold > 0
    end

    def gold_spent!
      @gold = 0
    end

    def draw_card
      @development_cards << @game.deck.draw
      log "#{name} drew a #{@development_cards.last}"
    end

    attr_reader :game
    def join_game(game)
      @game = game
      @game.add_player(self)
    end

    def submit_command(*parameters)
      log " [Action] #{self.name}: #{parameters.join(", ")}"
      action = parameters.shift
      case action
      when 'roll'
        @game.current_turn.roll_dice
      when 'buy'
        @game.current_turn.send(:"buy_#{parameters.shift}")
      when 'place'
        @game.current_turn.send(:"place_#{parameters.shift}", parameters.shift)
      when 'spend'
        @game.current_turn.spend_gold(self, parameters.shift)
      when 'play'
        @game.current_turn.play_card(parameters.shift)
      when 'done'
        @game.current_turn.done
        @development_cards.each do |card| card.set_playable! end
      end
      @game.current_turn
    end

  end
end
