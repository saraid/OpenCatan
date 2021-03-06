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
          row << "OpenCatan::Board::Hex::#{hex[:type]}".constantize.new
          row[offset].set_location(index, offset)
          row[offset].set_number(hex[:number])
          row[offset].add_trade_hub(hex[:trade])
        end
        board << Row.new(row)
      end
      board.build_intersections_and_paths
    end
    def serialize_to_yaml(file)
      serialized_board = collect do |row|
        row.collect do |hex|
          hex.serialize_to_yaml
        end
      end
    end
    def serialize_to_board_json
      collect do |row| row.serialize_to_board_json end
    end

    attr_accessor :longest_row

    def build_intersections_and_paths
      first_row.each do |hex| 2.times do hex.place_intersection Intersection.new end end
      last_row.each  do |hex| 2.times do hex.place_intersection Intersection.new end end
      each_with_index do |row, index|
        if (index % 2).zero?
          row.first.place_intersection Intersection.new
          row.last.place_intersection Intersection.new
        end
        row.each_with_index do |hex, offset|
          hex.neighbor_pairs.each do |pair|
            next if pair.all? do |location| !valid_location?(location) end
            intersection = Intersection.new
            pair.collect! do |location| find_by_location(location) end
            pair.compact!
            pair << hex
            pair.each do |this_hex| intersection.in_hex(this_hex) end
            pair.each do |this_hex| this_hex.remove_duplicates! end
            intersection.add_to_hexes
          end
        end
      end
      each_hex do |hex|
        hex.sort_intersections!(self)
        hex.connect_intersections!
      end
      each_hex do |hex|
        hex.create_trade_hubs
      end
      self
    end

    def find_by_location(location)
      self[location.row][location.offset] if valid_location?(location)
    end

    def find_intersection(id)
      each_hex do |hex|
        intersection = hex.intersections.detect do |intersection|
          intersection.id == id.to_i
        end
        return intersection if intersection
      end
      nil
    end

    def find_path(endpoints)
      endpoints = endpoints.split('-').collect do |x| x.to_i end if endpoints.respond_to? :split
      endpoint = nil
      each_hex do |hex|
        endpoint ||= hex.intersections.detect do |intersection|
          endpoints.include? intersection.id
        end
      end
      return nil unless endpoint
      endpoint.paths.detect do |path|
        endpoints.include? path.other_side(endpoint).id
      end
    end

    def find_hexes_by_number(number)
      flatten.select do |hex|
        hex.number == number
      end
    end

    def each_hex(&block)
      flatten.each(&block)
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
      @@counter = Sequence.new
      def initialize
        @hexes = []
        @paths = []
        @trade_hubs = []
        #@id = self.object_id
        @id = @@counter.next
      end
      attr_reader :piece, :hexes, :paths, :id, :trade_hubs

      def serialize_to_board_json
        { :id => @id, 
          :piece => self.piece ? { :type => self.piece.class.to_s.split('::').last,
                                   :owner => self.piece.owner.serialize_to_board_json
                               } : nil,
          :paths => @paths.collect do |i| i.serialize_to_board_json end,
        }
      end

      # There are some cases where this does not denote actual equivalence.
      # In cases of "outliers", or intersections occupying only one hex,
      # there are no characteristics to differentiate one intersection from
      # another.
      def ==(obj)
        @hexes.length == obj.hexes.length \
        && @hexes.all? do |hex| obj.hexes.include? hex end
      end

      def eql?(obj)
        self == obj
      end

      def hash
        return super if @hexes.length == 1
        @hexes.inject(0) do |sum, n| sum + n.hash end
      end

      def in_hex(hex, recursing = false)
        return if @hexes.include?(hex) || hex.nil?
        @hexes << hex
      end

      def add_to_hexes
        @hexes.each do |hex| hex.place_intersection(self, true) end
      end

      def connect_with(intersection_or_path)
        case intersection_or_path
        when Intersection
          @paths << Path.new(intersection_or_path, self)
          intersection_or_path.connect_with(@paths.last)
        when Path
          @paths << intersection_or_path unless @paths.include? intersection_or_path
        end
        @paths.uniq!
      end

      def distance
        @hexes.inject(0) do |sum, n| n.distance + sum end
      end

      def piece=(piece)
        raise OpenCatanException, "Intersection #{@id} in use." if @piece
        raise OpenCatanException, "Intersection near #{@id} in use." if @paths.any? do |path| path.has_piece_on_other_side_of(self) end
        @piece = piece
        @piece.owner.controls_trade_hub_for[@trade_hub.type] = true if @trade_hub
      end

      def upgrade_with(piece)
        raise OpenCatanException unless @piece
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
        @intersections.sort! do |a, b| a.distance <=> b.distance end
      end

      def serialize_to_board_json
        { :id => @intersections.join('-'),
          :piece => self.piece ? { :type => self.piece.class.to_s.split('::').last,
                                   :owner => self.piece.owner.serialize_to_board_json
                               } : nil,
        }
      end

      attr_reader :piece
      def piece=(piece)
        raise OpenCatanException, "Path #{self} in use." if @piece
        @piece = piece
      end

      def hash
        @intersections.collect {|i| "0%04d" % i.id}.join.to_i
      end

      def ==(obj)
        @intersections == obj.instance_variable_get(:@intersections)
      end
      def eql?(obj); self == obj; end

      def top_left_endpoint
        @intersections.first
      end

      def has_piece_on_other_side_of(intersection)
        !other_side(intersection).piece.nil?
      end

      def other_side(intersection)
        @intersections.detect { |inter| inter.id != intersection.id }
      end

      def is_a_trailhead?
        @intersections.any? do |intersection|
          intersection.paths.select { |path| path != self }.all? do |path| path.piece.nil? end
        end
      end

      def to_s
        "[#{@intersections.join('-')}]"
      end

      def inspect
        "[#{@intersections.collect {|x|x.inspect}.join('-')}]"
      end
    end

    class TradeHub
      def initialize(intersection1, intersection2, type, raw_data)
        @intersections = []
        @intersections << intersection1
        @intersections << intersection2
        @type = type.to_sym
        @raw_data = raw_data

        @intersections.each do |intersection|
          intersection.trade_hubs << self
        end
      end
      attr_reader :type

      def serialize_to_board_json
        @raw_data
      end

      def to_s
        "{#{@intersections.join('-')}}"
      end

      def inspect
        "{#{@intersections.collect {|x|x.inspect}.join('-')}}"
      end
    end

    class Row < Array # of Hexes
      def self.create_by_count(hex_count)
        Row.new(hex_count).collect do |x|
          Hex.create_random
        end
      end

      def serialize_to_board_json
        collect do |hex| hex.serialize_to_board_json end
      end
    end

    class Hex

      def initialize
        @intersections = []
        @paths = []
        @number = rand(12) unless product.nil?
        @robber = false
        @trade_hubs = []
      end
      attr_reader :location, :intersections, :number

      def serialize_to_yaml
        { :type => type, :number => number }
      end

      def serialize_to_board_json
        { :number        => number,
          :type          => type,
          :has_robber    => has_robber?,
          :intersections => @intersections.collect { |intersection| intersection.serialize_to_board_json },
          :trade_hubs    => @trade_hubs.collect { |i| i.serialize_to_board_json if i }
        }
      end

      def type
        self.class.to_s.split('::').last
      end

      def has_robber?
        @robber
      end

      def rob!
        @robber = true
      end

      def unrob!
        @robber = false
      end

      def set_location(row, offset)
        @location = Location.new(row, offset)
      end

      def set_number(number)
        @number = number
      end

      def add_trade_hub(hash)
        @trade_hubs << hash if hash
      end

      def create_trade_hubs
        @trade_hubs.collect! do |hub|
          TradeHub.new(@intersections[hub[:direction]], 
                       @intersections[hub[:direction].succ],
                       hub[:type], hub)
        end
      end

      def distance
        @location.row + @location.offset
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
        pairs << [Location.relative(@location, -1, -1 + hack), Location.relative(@location, -2, 0)]
        pairs << [pairs.last.last, Location.relative(@location, -1, 0 + hack)]
        pairs << [pairs.last.last, Location.relative(@location,  1,  0 + hack)]
        pairs << [pairs.last.last, Location.relative(@location,  2,  0)]
        pairs << [pairs.last.last, Location.relative(@location,  1, -1 + hack)]
        pairs << [pairs.last.last, pairs.first.first]
        pairs
      end

      def place_intersection(intersection, recursing = false)
        return if @intersections.length >= 6 || @intersections.include?(intersection)
        @intersections << intersection
        intersection.in_hex(self, true) unless recursing
      end

      def remove_duplicates!
        @intersections.uniq!
      end

      def has_intersection?(intersection)
        @intersections.include? intersection
      end

      def sort_intersections!(board)
        outliers = @intersections.select do |intersection| intersection.hexes.length == 1 end
        intersections = []
        neighbor_pairs.each do |pair|
          intersections << if pair.any? { |location| board.valid_location?(location) }
              @intersections.detect do |intersection|
                pair.collect! do |location| location.respond_to?(:row) ? board.find_by_location(location) : location end
                pair.compact!
                pair.length+1 == intersection.hexes.length && pair.all? do |hex|
                  intersection.hexes.include? hex
                end
              end
            else
              outliers.shift
            end
        end
        @intersections = intersections
      end

      def connect_intersections!
        6.times do |index|
          @intersections[index].connect_with @intersections[index-1]
        end
      end

      def self.produces resource
        @produces = resource
      end

      def product
        self.class.instance_variable_get :@produces
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
