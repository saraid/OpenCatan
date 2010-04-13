module OpenCatan
  class Deck

    class DevelopmentCard
    @@counter = OpenCatan::Sequence.new
      AMOUNT_IN_DECK = 0
      def initialize
        @id = @@counter.next #self.object_id # Just need a unique identifier.
        @just_received = true
      end
      attr_reader :id

      def type
        self.class.to_s.split('::').last
      end

      def set_playable!
        @just_received = false
      end
      def playable?
        !@just_received
      end
    end

    class ProgressCard < DevelopmentCard
      AMOUNT_IN_DECK = 0
    end

    class RoadBuilding < ProgressCard
      AMOUNT_IN_DECK = 2
    end

    class YearOfPlenty < ProgressCard
      AMOUNT_IN_DECK = 2

      def use(player, game)
        2.times do |x| player.receive(:gold) end
      end
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
      @discards = []
      Deck.constants.sort.each do |card_type|
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

    def discard(card)
      @discards << card
    end

    def method_missing(id, *args, &block)
      @contents.send(id, *args, &block)
    end
  end

  class RiggedDeck < Deck
    def initialize
      super
      [50].each do |type|
        unshift(@contents.detect do |card| card.id == type end)
      end
    end
  end
end
