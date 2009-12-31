require 'catan/board'

class GameController < ApplicationController
  helper :all # include all helpers, all the time
  #protect_from_forgery # See ActionController::RequestForgeryProtection for details

  def board
    @board = Board.new(params[:id])
    render :action => 'board'
  end

  def debug
    @board = Board.new(params[:id])
    render :text => @board.instance_variable_get(:@hex_store).hexes.length
  end
end

