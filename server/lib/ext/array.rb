class Array
  def randomize!
    self.size.times do |src|
      dest = Kernel.rand(self.size).round
      t = self[src]
      self[src] = self[dest]
      self[dest] = t
    end
  end

  def to_s
    join(', ')
  end
end
