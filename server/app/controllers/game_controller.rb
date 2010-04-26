require 'catan/game'

class GameController < ApplicationController

  # This is a hack. Ability to choose color comes later.
  COLORS = ["red", "orange", "blue", "white"]

  before_filter :create_or_find_game
  before_filter :require_log_in, :except => :index
  after_filter  :save_game

  def index
    @foo = @game.board.serialize_to_board_json
    render :action => 'board', :layout => 'base'
  end

  def join
    join_game
    render :text => @game.players.length
  end

  def start
    return unless @game.players.index(@game.find_player_by_name(session[:user])).zero?
    @game.start_game
    redirect_to :action => :index, :id => params[:id]
  end

  def status
    render :text => { :state => @game.game_state, :turn => @game.current_turn.inspect.to_s }.to_json
  end

  def ping
    render :text => "blah"
  end

  def method_missing(id, *args, &block)
    begin
      @game.find_player_by_name(session[:user]).submit_command id, *params[:args]
      @game.current_turn
      #render :text => @game.current_turn.inspect.to_json
      redirect_to :action => :index, :id => params[:id]
    rescue NoMethodError => e
      raise e
    end
  end

  private
  def create_or_find_game
    @game = File.open("data/#{params[:id]}.catan", File::RDONLY) do |f| Marshal.load(f) end if params[:id]
    if @game.nil?
      redirect_to :controller => :user, :action => :login and return unless logged_in?
      @game = OpenCatan::Game.new
      join_game 
      save_game
      redirect_to :controller => :game, :id => @game.id
    end
  end

  def save_game
    File.open("data/#{@game.id}.catan", File::CREAT|File::WRONLY) do |f| Marshal.dump(@game, f) end
  end

  def join_game
    user = User.find_by_username(session[:user])
    OpenCatan::Player.new(user.username, COLORS[@game.players.length]).join_game(@game)
    # Really ought to save_game this relationship in the database to allow for multiple games in progress
  end
end

