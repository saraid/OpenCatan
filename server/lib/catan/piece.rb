require 'catan/catan'

class Piece

  class Settlement
    AMOUNT_PER_PLAYER = 5
    REQUIRES = ::Catan::RESOURCES.merge({
      :wood  => 1,
      :wheat => 1,
      :clay  => 1,
      :sheep => 1,
    })
  end

  class City
    AMOUNT_PER_PLAYER = 4
    REQUIRES = ::Catan::RESOURCES.merge({
      :wheat => 2,
      :ore   => 3,
    })
  end

  class Road
    AMOUNT_PER_PLAYER = 15
    REQUIRES = ::Catan::RESOURCES.merge({
      :wood  => 1,
      :clay  => 1,
    })
  end

  class Boat
    AMOUNT_PER_PLAYER = 15
    REQUIRES = ::Catan::RESOURCES.merge({
      :wood  => 1,
      :sheep => 1,
    })
  end

  class Robber
    AMOUNT_PER_PLAYER = 0
  end

end
