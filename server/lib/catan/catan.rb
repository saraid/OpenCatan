require 'ext/array'

class Catan

  RESOURCES = {
    :wood  => 0,
    :wheat => 0,
    :clay  => 0,
    :ore   => 0,
    :sheep => 0,
  }

  HEX_TYPES = {
    :desert    => {:produces => nil,    :color => [255, 222, 173] },
    :forests   => {:produces => :wood,  :color => [34, 139, 34]   },
    :plains    => {:produces => :sheep, :color => [0, 255, 127]   },
    :fields    => {:produces => :wheat, :color => [255, 223, 0]   },
    :mountains => {:produces => :ore,   :color => [112, 128, 144] },
    :hills     => {:produces => :clay,  :color => [233, 116, 81]  },
    :water     => {:produces => nil,    :color => [0, 127, 255]   }
  }
end
