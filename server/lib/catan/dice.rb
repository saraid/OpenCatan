module OpenCatan
  class Dice
    def initialize
      @history = []
      @remember = false
    end
    attr_reader :history

    def remember; @remember = true;  self; end
    def forget;   @remember = false; self; end

    def roll(number = 1, sides = 6)
      @history << Array.new(number).collect { |die| rand(sides) + 1 }
      action = @remember ? :last : :pop
      @history.send(action).inject(0) { |sum,n| sum + n }
    end
  end

  class LoadedDice < Dice
    def initialize
      super
      @rolls  = [5, 4, 3, 2]
      @rolls += [9, 6, 5, 9,
                 8, 12, 4, 6,
                 8, 8, 8, 10,
                 6, 8, 6, 6,
                 8, 8, 6, 6,
                 7, 3
                ]
    end
    def roll(number = 1, sides = 6)
      return super if @rolls.empty?
      @rolls.shift
    end
  end
end
