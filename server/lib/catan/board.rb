require 'catan/catan'

class Board

  class HexStore
    def initialize
      @rows = []
    end
    attr_reader :rows

    def new_row=(row)
      @rows << row
    end

    def length
      @rows.length
    end

    def fetch(row, offset)
      rv = @rows[row][offset]
      puts "#{row} #{offset}" if rv.nil?
      rv
    end

    def hexes
      @rows.flatten
    end
  end

  class Hex

    def initialize(number, type, row, offset)
      @number = number
      @type   = type
      @row    = row
      @offset = offset
      @intersections = []
    end
    attr_reader :number, :type
    attr_reader :row, :offset
    attr_reader :intersections

    def to_s
      "#{@row} #{@offset}"
    end

    def fill_intersection(intersection)
      return if @intersections.include? intersection
      raise "Attempted to fill in too many intersections!" if @intersections.length >= 6
      @intersections << intersection
      intersection.connect_with_hex(self)
    end

    def notify_with_resource
      @filled_intersections.each do |settlement|
        settlement.receive_resource(type)
      end
    end
  end

  class Intersection
    include Comparable
    def initialize(id)
      @identifier = id
      @paths = []
      @hexes = []
    end
    attr_reader :identifier, :paths

    def <=>(other)
      @identifier <=> other.identifier
    end

    def connect_with_hex(hex)
      raise "Attempted to add too many hexes!" if @hexes.length >= 3
      @hexes << hex
    end

    def add_path(path)
      return if @paths.include? path
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
          print " #{"%3d" % intersection.instance_variable_get(:@identifier)} |"
        end
        print "\n"
      end
      nil
    end
    def self.clear_paths; @@paths = []; end

    def initialize(intersection1, intersection2, sailable = false)
      @intersections = [intersection1, intersection2].sort
      @intersections.each { |intersection| intersection.add_path self }
      @sailable = sailable
      @@paths << self
    end
    attr_reader :intersections, :sailable

    def to_s
      "[#{@intersections.collect { |x| x.identifier }.join ' '}]"
    end

    def ==(other)
      @intersections.all? { |i| other.instance_variable_get(:@intersections).include? i }
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
    map_size = map_size.to_i

    hex_shaped_map(map_size)
  end
  attr_reader :hex_store

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

    # Create distribution
    seed_array = Catan::HEX_TYPES.collect { |key, value| key if value[:produces] }.compact
    terrain_distribution = []
    row_array.inject(0) { |sum, n| sum + n }.times do |i|
      terrain_distribution << seed_array[i % seed_array.length]
    end
    terrain_distribution.randomize!
    terrain_distribution[rand(terrain_distribution.length)] = :desert

    # Create hexes
    row_array.each_with_index do |length, row|
      @hex_store.new_row = (0...length).collect do |offset|
        Hex.new(rand(12), terrain_distribution.shift, row, offset)
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
    intersections.times do |id|
      @intersections << Intersection.new(id)
    end

    # Define rows of intersections
    intersection_array = (2..(2*size)).select {|x|(x%2).zero?}
    tmp = intersection_array.reverse.clone
    (2*size-3).times do intersection_array << intersection_array[-1] end
    intersection_array = intersection_array + tmp
    
    # Pattern A - X0XX0XX0...
    # Pattern B - XX0XX0XX...
    intersection_index = 0
    intersection_array.each_with_index do |intersection_count, row_index|
      if row_index < size
        intersection_count.times do |offset|
          @hex_store.fetch(row_index, offset / 2).fill_intersection @intersections[intersection_index]
          if offset > 0 && offset < intersection_count-1
            @hex_store.fetch(row_index - 1, (offset - 1) / 2).fill_intersection @intersections[intersection_index] 
          end
          if offset > 1 && offset < intersection_count-2
            @hex_store.fetch(row_index - 2, (offset - 2) / 2).fill_intersection @intersections[intersection_index] 
          end
          intersection_index += 1
        end
      elsif row_index >= size && row_index < intersection_array.length-size
        if (size + row_index) % 2 == 0 # Pattern A
          intersection_count.times do |offset|
            @hex_store.fetch(row_index - 1, offset / 2).fill_intersection @intersections[intersection_index]
            if offset > 0 && offset < intersection_count-1
              @hex_store.fetch(row_index, (offset - 1) / 2).fill_intersection @intersections[intersection_index]
              @hex_store.fetch(row_index - 2, (offset - 1) / 2).fill_intersection @intersections[intersection_index] 
            end
            intersection_index += 1
          end
        else                           # Pattern B
          intersection_count.times do |offset|
            @hex_store.fetch(row_index - 2, offset / 2).fill_intersection @intersections[intersection_index]
            if offset > 0 && offset < intersection_count-1
              @hex_store.fetch(row_index - 1, (offset - 1) / 2).fill_intersection @intersections[intersection_index]
            end
            @hex_store.fetch(row_index, offset / 2).fill_intersection @intersections[intersection_index]
            intersection_index += 1
          end
        end
      else 
        intersection_count.times do |offset|
          @hex_store.fetch(row_index - 2, offset / 2).fill_intersection @intersections[intersection_index] 
          if offset > 0 && offset < intersection_count-1
            @hex_store.fetch(row_index - 1, (offset - 1) / 2).fill_intersection @intersections[intersection_index] 
          end
          if offset > 1 && offset < intersection_count-2
            @hex_store.fetch(row_index, (offset - 2) / 2).fill_intersection @intersections[intersection_index] 
          end
          intersection_index += 1
        end
      end
    end

    #
    # Create paths
    #

    @hex_store.hexes.each do |hex|
      intersections = hex.intersections
      Path.new(intersections[0], intersections[1])
      Path.new(intersections[1], intersections[3])
      Path.new(intersections[3], intersections[5])
      Path.new(intersections[5], intersections[4])
      Path.new(intersections[4], intersections[2])
      Path.new(intersections[2], intersections[0])
    end

  end
  private :hex_shaped_map

  def dump_intersections
instance_variable_get(:@hex_store).rows.each do |x| x.each do |h| print '['; h.instance_variable_get(:@intersections).each do |i| print i.instance_variable_get(:@identifier); print ' '; end; print ']' end; puts; end;
  nil
  end

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
