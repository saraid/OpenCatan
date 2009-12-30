class Board

  class HexStore
    def initialize
      @rows = []
    end

    def new_row=(row)
      @rows << row
    end

    def rows
      @rows
    end

    def length
      @rows.length
    end
  end

  class Hex
    @filled_intersections = []

    def initialize(number, type, row, offset)
      @number = number
      @type   = type
      @row    = row
      @offset = offset
    end
    attr_reader :number, :type
    attr_reader :row, :offset

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
    def initialize(id)
      @id = id
      @paths = []
    end

    def add_path(path)
      raise "Attempted to add too many paths!" if @paths.length >= 3
      @paths << path
    end
  end

  class Path
    @@paths = [] # For debugging
    def self.dump_paths 
      puts "from |  to |"
      Board::Path.paths.each do |path|
        foo = path.instance_variable_get :@intersections
        foo.each do |intersection|
          print " #{"%3d" % intersection.instance_variable_get(:@id)} |"
        end
        print "\n"
      end
      nil
    end
    def self.clear_paths; @@paths = []; end

    def initialize(intersection1, intersection2, sailable = false)
      @intersections = [intersection1, intersection2]
      @intersections.each { |intersection| intersection.add_path self }
      @sailable = sailable
      @@paths << self
    end
  end

  # Map Types
  # :hex, :square, :rectangle
  # 
  # Hex and square sizes defined by top border.
  # 
  def initialize(map_size = 4, map_type = :hex)
    Board::Path.clear_paths # For debugging
    @hex_store = HexStore.new

    hex_shaped_map(map_size)
  end

  def hex_shaped_map(size)

    #
    # Build hexes
    #

    # Define rows of hexes
    row_array = (1...size).to_a
    tmp = row_array.reverse.clone
    (2*size-3).times do |i| 
      row_array << ((i % 2).zero?() ? size : size-1)
    end
    row_array = row_array + tmp

    # Create hexes
    row_array.each_with_index do |length, row|
      @hex_store.new_row = (1..length).collect do |offset|
        Hex.new(rand(12), :desert, row, offset)
      end
    end

    #
    # Build intersections
    #

    # Count intersections
    intersections = (2..(2*size)).inject(0) do |sum, n|
      if (n%2).zero?
        if n == 2*size
          sum + (2*size-1)*2*size
        else
          sum + (2*n)
        end
      else
        sum
      end
    end

    # Create intersections
    @intersections = []
    intersections.times do |i|
      @intersections << Intersection.new(i)
    end

    # 
    # Build paths
    #
    
    # Walk from the top to the upper left corner
    upper_left_ids = (0..size).collect {|x|2*x}.inject([0]) { |ary,n| ary << ary[-1] + n }
    upper_left_ids.shift # first one was dummy
    upper_left_ids.each_with_index do |id, index|
      break if index == size
      lower_index = upper_left_ids[index+1]+1
      lower_index = upper_left_ids[index+1] if index == size-1
      Path.new(@intersections[id], @intersections[id+1])
      Path.new(@intersections[id], @intersections[lower_index])
    end

  end
  private :hex_shaped_map

  def render_ascii
    size = (@hex_store.length + 5)/4
    render = ""
    spaces = 2*size-1
    spaces.times do print ' ' end
    print "_\n"

    rows = @hex_store.rows
    rows[0...size-1].each_with_index do |row, row_index|
      offsets = []
      row.collect! do |hex|
        offsets << hex.offset
        "/#{hex.row   }\\"
      end
      offsets.pop
      offsets << ''

      spaces -= 2
      spaces.times do |i| print ' ' end if spaces > 0
      print "_#{[row, offsets].transpose.flatten.join}_"
      print "\n"
    end
    spaces -= 2

    rows[size-1...rows.length-size+1].each_with_index do |row, row_index|
        next if row_index % 2 == 1

        row_top = row.clone
        offsets = []
        row_top.collect! do |hex|
          offsets << hex.offset
          "/#{hex.row   }\\"
        end

        offsets.pop
        offsets << ''

        print [row_top, offsets].transpose.flatten.join
        print "\n"


        row_bottom = row.clone
        rowNums = []
        row_bottom.collect! do |hex|
          rowNums << hex.row+1
          "\\#{hex.offset   }/"
        end
        rowNums.pop
        rowNums << ''

        rowNums.pop
        rowNums << ''

        print [row_bottom, rowNums].transpose.flatten.join
        print "\n"
    end

    spaces += 1
    rows[rows.length-size+1...rows.length].each_with_index do |row, row_index|
      rowNums = []
      row.collect! do |hex|
        rowNums << hex.row
        "\\#{hex.offset   }/"
      end
      rowNums.pop
      rowNums << ''

      spaces += 2
      spaces.times do |i| print ' ' end if spaces > 0
      print [row, rowNums].transpose.flatten.join
      print "\n"
    end
  end
end
