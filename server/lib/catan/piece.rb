require 'catan/catan'

class Piece

  attr_accessor :owner

  class Settlement < Piece
    AMOUNT_PER_PLAYER = 5
    REQUIRES = ::Catan::RESOURCES.merge({
      :wood  => 1,
      :wheat => 1,
      :clay  => 1,
      :sheep => 1,
    })
  end

  class City < Piece
    AMOUNT_PER_PLAYER = 4
    REQUIRES = ::Catan::RESOURCES.merge({
      :wheat => 2,
      :ore   => 3,
    })
  end

  class Road < Piece
    AMOUNT_PER_PLAYER = 15
    REQUIRES = ::Catan::RESOURCES.merge({
      :wood  => 1,
      :clay  => 1,
    })
  end

  class Boat < Piece
    AMOUNT_PER_PLAYER = 15
    REQUIRES = ::Catan::RESOURCES.merge({
      :wood  => 1,
      :sheep => 1,
    })
  end

  class Robber < Piece
    AMOUNT_PER_PLAYER = 0
  end

end
