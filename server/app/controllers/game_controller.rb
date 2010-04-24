require 'catan/game'

class GameController < ApplicationController
  helper :all # include all helpers, all the time
  #protect_from_forgery # See ActionController::RequestForgeryProtection for details

  def board
    @game = create_or_find_game(params[:id])
    save
    @foo = @game.board.serialize_to_board_json
    render :action => 'board'
  end

  private
  def create_or_find_game(id)
    @game = if id
      File.open("data/#{id}.catan", File::RDONLY) do |f| Marshal.load(f) end
    else
      OpenCatan::Game.new
    end
  end

  def save
    File.open("data/#{@game.id}.catan", File::CREAT|File::WRONLY) do |f| Marshal.dump(@game, f) end
  end
end

