module OpenCatan
  class Board < Array

    class LoadError < Exception; end

    def self.deserialize_from_yaml(file)
      board = Board.new
      map = YAML.load(File.open(file) do |file| file.read end)

      board.longest_row = map.max do |a, b| a.length <=> b.length end
      valid = false
      map.each_with_index do |row, index|
        valid = (row.length == ((index % 2).zero?) \
                  ? board.longest_row.length             \
                  : board.longest_row.length-1)          \
                || valid
      end
      raise LoadError, "Invalid board format" unless valid

      map.each_with_index do |raw_row, index|
        row = Row.new
        raw_row.each_with_index do |hex, offset|
          row << "OpenCatan::Board::Hex::#{hex}".constantize.new
          row[offset].set_location(index, offset)
        end
        board << Row.new(row)
      end
      board.build_intersections_and_paths
    end
    attr_accessor :longest_row

    class Count
      def initialize; @count = 0; end
      def plusplus; @count = @count.succ; end
    end

    def build_intersections_and_paths
      intersections = Count.new
      first_row.each do |hex| 2.times do hex.place_intersection Intersection.new(intersections.plusplus) end end
      last_row.each  do |hex| 2.times do hex.place_intersection Intersection.new(intersections.plusplus) end end
      each_with_index do |row, index|
        if (index % 2).zero?
          row.first.place_intersection Intersection.new(intersections.plusplus)
          row.last.place_intersection Intersection.new(intersections.plusplus)
        end
        row.each_with_index do |hex, offset|
          hex.neighbor_pairs.each do |pair|
            next if pair.all? do |location| !valid_location?(location) end
            intersection = Intersection.new(intersections.plusplus)
            pair.collect! do |location| find_by_location(location) end
            pair.compact!
            pair << hex
            pair.each do |this_hex| intersection.in_hex(this_hex) end
          end
        end
      end
      flatten.each do |hex|
        hex.connect_intersections!
      end
      self
    end

    def find_by_location(location)
      self[location.row][location.offset] if valid_location?(location)
    end

    def find_intersection(id)
      flatten.detect do |hex|
        hex.intersections.detect do |intersection|
          intersection.id = id
        end
      end
    end

    def valid_location?(location)
      (   location.row >= 0     \
       && location.row < height \
       && location.offset >= 0  \
       && location.offset < ((location.row % 2).zero? ? width : width-1)
      )
    end

    def first_row
      self.first
    end

    def last_row
      self.last
    end

    def width
      longest_row.length
    end

    def height
      length
    end

    class Intersection
      def initialize(id)
        @hexes = []
        @paths = []
        @id = id
      end
      def in_hex(hex, recursing = false)
        return if @hexes.include? hex || hex.nil?
        @hexes << hex
        hex.place_intersection(self, true) unless recursing
      end

      def connect_with(intersection)
        @paths << Path.new(intersection, self)
      end

      attr_reader :piece, :paths, :id
      def piece=(piece)
        raise OpenCatanException, "Intersection #{@id} in use." if @piece
        @piece = piece
      end

      def to_s
        @id.to_s
      end

      def inspect
        "(#{@hexes.collect {|x|x.inspect}.join('|')})"
      end
    end

    class Path
      def initialize(intersection1, intersection2)
        @intersections = []
        @intersections << intersection1
        @intersections << intersection2
      end

      attr_reader :piece
      def piece=(piece)
        raise OpenCatanException, "Path #{self} in use." if @piece
        @piece = piece
      end

      def has_piece_on_other_side_of(intersection)
        !other_side.piece.nil?
      end

      def other_side(intersection)
        @intersections.detect { |inter| inter != intersection }
      end

      def to_s
        "[#{@intersections.join('-')}]"
      end

      def inspect
        "[#{@intersections.collect {|x|x.inspect}.join('-')}]"
      end
    end

    class Row < Array # of Hexes
      def self.create_by_count(hex_count)
        Row.new(hex_count).collect do |x|
          Hex.create_random
        end
      end
    end

    class Hex

      def initialize
        @intersections = []
        @paths = []
      end
      attr_reader :location, :intersections

      def set_location(row, offset)
        @location = Location.new(row, offset)
      end

      class Location
        attr_reader :row, :offset
        def initialize(row, offset)
          @row = row
          @offset = offset
        end

        def self.relative(location, row, offset)
          Location.new(location.row + row, location.offset + offset)
        end

        def to_s; "<#{@row},#{@offset}>"; end
      end

      def to_s; @location.to_s; end
      def inspect; @location.to_s; end

      def neighbor_pairs
        hack = (@location.row % 2).zero? ? 0 : 1
        pairs = []
        pairs << [Location.relative(@location, -2, 0), Location.relative(@location, -1, 0 + hack)]
        pairs << [pairs.last.last, Location.relative(@location,  1,  0 + hack)]
        pairs << [pairs.last.last, Location.relative(@location,  2,  0)]
        pairs << [pairs.last.last, Location.relative(@location,  1, -1 + hack)]
        pairs << [pairs.last.last, Location.relative(@location, -1, -1 + hack)]
        pairs << [pairs.last.last, pairs.first.first]
        pairs
      end

      def place_intersection(intersection, recursing = false)
        return if @intersections.length >= 6 || @intersections.include?(intersection)
        @intersections << intersection
        intersection.in_hex(self, true) unless recursing
      end

      def has_intersection?(intersection)
        @intersections.include? intersection
      end

      def connect_intersections!
        6.times do |index|
          @intersections[index].connect_with @intersections[index-1]
        end
      end

      def self.produces resource
        @@produces = resource
      end

      def produces
        @@produces
      end

      class Desert < Hex
        produces nil
      end

      class Forest < Hex
        produces :wood
      end

      class Plain < Hex
        produces :sheep
      end

      class Field < Hex
        produces :wheat
      end

      class Mountain < Hex
        produces :ore
      end

      class Hill < Hex
        produces :clay
      end

      class Water < Hex
        produces nil
      end

      class Mine < Hex
        produces :gold
      end
    end

  end
end
