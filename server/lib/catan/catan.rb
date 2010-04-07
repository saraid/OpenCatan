require 'ext/array'

module OpenCatan
  class OpenCatanException < StandardError; end
  class Catan

    RESOURCES = {
      :wood  => 0,
      :wheat => 0,
      :clay  => 0,
      :ore   => 0,
      :sheep => 0,
    }
  end
end
