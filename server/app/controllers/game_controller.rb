require 'catan/game'

class GameController < ApplicationController

  # This is a hack. Ability to choose color comes later.
  COLORS = ["red", "orange", "blue", "white"]

  before_filter :create_or_find_game
  before_filter :require_log_in, :except => :index
  after_filter  :save

  def index
    redirect_to :controller => :game, :id => @game.id and return if @new_game
    @foo = @game.board.serialize_to_board_json
    render :action => 'board'
  end

  def join
    join_game
    render :text => @game.players.length
  end

  def start
    return unless @game.players.index(@game.find_player_by_name(session[:user])).zero?
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
      render :text => @game.current_turn.inspect.to_json
    rescue NoMethodError
      super
    end
  end

  private
  def create_or_find_game
    @game = File.open("data/#{params[:id]}.catan", File::RDONLY) do |f| Marshal.load(f) end if params[:id]
    if @game.nil?
      require_log_in
      @new_game = true
      @game = OpenCatan::Game.new
      join_game 
    end
  end

  def save
    File.open("data/#{@game.id}.catan", File::CREAT|File::WRONLY) do |f| Marshal.dump(@game, f) end
  end

  def join_game
    user = User.find_by_username(session[:user])
    OpenCatan::Player.new(user.username, COLORS[@game.players.length]).join_game(@game)
    # Really ought to save this relationship in the database to allow for multiple games in progress
  end
end

