class Dice
  @@history = []

  def self.roll(number = 1, sides = 6)
    @@history << Array.new(number).collect { |die| rand(sides) + 1 }
    @@history.last.inject(0) { |sum,n| sum + n }
  end

  def self.history
    @@history
  end

end
