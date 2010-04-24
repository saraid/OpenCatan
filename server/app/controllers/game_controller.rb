require 'catan/game'

class GameController < ApplicationController
  helper :all # include all helpers, all the time
  #protect_from_forgery # See ActionController::RequestForgeryProtection for details

  before_filter :create_or_find_game
  after_filter  :save

  def index
    @foo = @game.board.serialize_to_board_json
    render :action => 'board'
  end

  def method_missing(id, *args, &block)
  end

  private
  def create_or_find_game
    @game = if params[:id]
      File.open("data/#{params[:id]}.catan", File::RDONLY) do |f| Marshal.load(f) end
    else
      OpenCatan::Game.new
    end
  end

  def save
    File.open("data/#{@game.id}.catan", File::CREAT|File::WRONLY) do |f| Marshal.dump(@game, f) end
  end
end

