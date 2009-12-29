class Board

  class HexStore
    @rows = []
  end

  class Hex
    @filled_intersections = []

    def initialize(number, type)
      @number = number
      @type   = type
    end
    attr_reader :number, :type

    def fill_intersection(settlement)
      raise "Attempted to fill in too many intersections!" if @filled_intersections.length >= 6
      @filled_intersections << settlement
    end

    def notify_with_resource
      @filled_intersections.each do |settlement|
        settlement.receive_resource(type)
      end
    end
  end

  class Intersection
    @paths = []
    def initialize
    end

    def add_path(path)
      raise "Attempted to add too many paths!" if @paths >= 3
      @paths << path
    end
  end

  class Path
    def initialize(intersection1, intersection2, sailable = false)
      @intersections = [intersection1, intersection2]
      @intersections.each { |intersection| intersection.add_path self }
      @sailable = sailable
    end
  end

  # Map Types
  # :hex, :square, :rectangle
  # 
  # Hex and square sizes defined by top border.
  # 
  def initialize(map_size = 4, map_type = :hex)
    @hex_store = HexStore.new
  end
end
