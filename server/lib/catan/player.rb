require 'catan/piece'
require 'catan/action'
require 'catan/turn'

module OpenCatan
  class Player

    attr_reader   :name, :color, :controls_trade_hub_for, :resources
    attr_accessor :longest_road, :knights_played, :landfalls, :vp_cards_used
    def initialize(name, color)
      @name = name
      @color = color

      @resources = Catan::RESOURCES.clone
      @development_cards = []
      @gold = 0

      @knights_played = 0
      @longest_road   = 0
      @landfalls      = 0
      @vp_cards_used  = 0

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

    # This is from piece.owner.
    def serialize_to_board_json
      @game.players.index(self)
    end

    def hand_size
      @resources.values.inject(0) do |sum, n| sum + n end
    end

    def get_card(card_id)
      @development_cards.detect do |card| card.id == card_id.to_i end
    end

    def discard(card)
      @game.deck.discard(@development_cards.delete(card))
    end

    def play_piece(type)
      raise OpenCatanException, "Out of pieces" if @pieces_remaining[type].empty?
      @pieces_remaining[type].shift
    end

    def receive_piece(type, piece)
      @pieces_remaining[type] << piece
    end

    def played_a_knight
      @knights_played += 1
    end

    def played_a_victory_point
      @vp_cards_used += 1
    end

    def receive(resource, from_gold = false)
      return if resource.nil?
      log "#{name} receives 1 #{resource}"
      @gold += 1 and return if resource == :gold
      @gold -= 1 if from_gold
      @resources[resource] += 1
    end

    def rob!
      lost = @resources.inject([]) { |resources, n| n.last.times do |i| resources << n.first end; resources }.rand
      @resources[lost] -= 1
      lost
    end

    def lose(resource)
      lost = @resources[resource]
      @resources[resource] = 0
      lost
    end

    def has_gold?
      @gold > 0
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
        @game.current_turn.roll_dice(self)
      when 'buy'
        @game.current_turn.send(:"buy_#{parameters.shift}", self)
      when 'place'
        @game.current_turn.send(:"place_#{parameters.shift}", self, parameters.shift)
      when 'spend'
        @game.current_turn.spend_gold(self, parameters.shift)
      when 'discard'
        @game.current_turn.discard(self, parameters.shift)
      when 'play'
        @game.current_turn.play_card(self, parameters.shift)
      when 'upgrade'
        @game.current_turn.upgrade(self, parameters.shift)
      when 'choose'
        @game.current_turn.choose(self, parameters.shift)
      when 'propose'
        @game.current_turn.propose(self, parameters.shift, parameters.shift, parameters.shift)
      when 'respond'
        @game.current_turn.respond(self, parameters.shift)
      when 'accept'
        @game.current_turn.accept(self, parameters.shift)
      when 'cancel'
        @game.current_turn.cancel(self)
      when 'done'
        @game.current_turn.done
        @development_cards.each do |card| card.set_playable! end
      else
        raise NoMethodError, "#{action} is not a known command"
      end
      @game.current_turn
    end

  end
end
