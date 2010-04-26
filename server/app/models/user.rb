require 'catan/player'

class User < ActiveRecord::Base
  def spawn_player(color)
    @player = OpenCatan::Player.new(self.username, color)
  end
end
