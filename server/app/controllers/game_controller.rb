require 'catan/board'
require 'catan/player'
require 'random_data'

class GameController < ApplicationController
  helper :all # include all helpers, all the time
  #protect_from_forgery # See ActionController::RequestForgeryProtection for details

  def board
    @players = Array.new(3)
    @players.collect! { |player| player = Player.new(Random.firstname, Random.color) }
    @board = Board.new(params[:id])
    render :action => 'board'
  end

  def debug
    @board = Board.new(params[:id])
    render :text => @board.instance_variable_get(:@hex_store).hexes.length
  end
end

