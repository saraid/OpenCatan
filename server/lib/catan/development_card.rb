module OpenCatan
  class Deck

    class DevelopmentCard
      AMOUNT_IN_DECK = 0
    end

    class ProgressCard < DevelopmentCard
      AMOUNT_IN_DECK = 0
    end

    class RoadBuilding < ProgressCard
      AMOUNT_IN_DECK = 2
    end

    class YearOfPlenty < ProgressCard
      AMOUNT_IN_DECK = 2
    end

    class Monopoly < ProgressCard
      AMOUNT_IN_DECK = 2
    end

    class Knight < DevelopmentCard
      AMOUNT_IN_DECK = 14
    end

    class VictoryPoint < DevelopmentCard
      AMOUNT_IN_DECK = 5
    end

    def initialize
      @contents = []
      Deck.constants.each do |card_type|
        card_class = Deck.const_get(card_type)
        card_class.const_get(:AMOUNT_IN_DECK).times do |i|
          @contents << card_class.new
        end
      end

      # Shuffle
      @contents.randomize!
    end

    def draw
      @contents.shift
    end

    def method_missing(id, *args, &block)
      @contents.send(id, *args, &block)
    end
  end
end
