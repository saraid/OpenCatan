class Catan

  RESOURCES = {
    :wood  => 0,
    :wheat => 0,
    :clay  => 0,
    :ore   => 0,
    :sheep => 0,
  }.freeze

  HEX_TYPES = {
    :desert    => nil,
    :forest    => :wood,
    :plains    => :sheep,
    :field     => :wheat,
    :mountains => :ore,
    :hills     => :clay,
    :water     => nil,
  }.freeze
end
