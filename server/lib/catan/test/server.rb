require 'catan/game'
require 'gserver'
require 'random_data'

class Server < GServer
  def initialize
    super(10001, DEFAULT_HOST, 2)
    self.audit = true
    @game = OpenCatan::Game.new
    @colors = ['red', 'blue', 'orange', 'white']
    @message_queue = {}
  end

  def attach_message(*args)
    @message_queue.keys.each do |queue| 
      @message_queue[queue] << args.join(' ')
    end
  end

  def serve(io)
    io.print("O Hai! What's your name? ")
    begin
      player = OpenCatan::Player.new(io.gets.strip.gsub(/\W/,''), @colors.rand)
      player.join_game @game
      @message_queue[player] = []
      @game.start_game if @game.players.length == 2
      success = true
    rescue Exception => e
      log e.message
      success = false
    end
    if success
      prompt = '> '
      io.print prompt
      prompted = true

      loop do
        if IO.select([io], nil, nil, 0.5)
          player.submit_command io.gets.chop
          prompted = false
        elsif !@message_queue[player].empty?
          io.puts "\r" if prompted
          io.puts "#{@message_queue[player].shift}\r"
          io.print prompt
          prompted = true
        end
      end
    end
  end
end

module Kernel
  def log(*args)
    puts(*args)
    $server.attach_message(*args)
  end
end

$server = Server.new.start
loop do
  break if $server.stopped?
end
