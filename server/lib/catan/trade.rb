module OpenCatan
  # A trade negotiation is defined as any series of
  # proposals possibly culminating in an accepted
  # or cancelled offer.
  class TradeNegotiation
    @@counter = OpenCatan::Sequence.new
    def initialize(game, initiator, limited_to)
      @game       = game
      @initiator  = initiator
      @proposals  = {}
      @limited_to = limited_to
      @status = :pending

      if @limited_to.present?
        @limited_to = @limited_to.split(',').collect! do |index|
          @game.players[index]
        end
      end
    end
    attr_reader :status, :initiator

    def propose(proposer, offer, demand)
      @proposals[proposer] = {
        :id         => @@counter.next, # self.object_id
        :offer      => JSON.parse(offer),
        :demand     => JSON.parse(demand),
      }

      # Verify that offer is valid.
      valid = true
      @proposals[proposer][:offer].each_pair do |resource, amount|
        raise OpenCatanException, "#{proposer.name} is offering more #{resource} than is owned." unless proposer.resources[resource.to_sym] >= amount
      end
    end

    def respond(player, message)
      @proposals[player] ||= {}
      @proposals[player].update!({ :message => message })
    end

    def accept(player)
      raise OpenCatanException, "Cannot accept your own proposal." if @initiator == player
      @status = :accepted
      @accepted = @proposals[player]
      @accepted[:offer].each_pair do |resource, amount|
        amount.times do |i| @initiator.receive resource.to_sym end
        player.resources[resource.to_sym] -= amount
      end
      @accepted[:demand].each_pair do |resource, amount|
        amount.times do |i| player.receive resource.to_sym end
        @initiator.resources[resource.to_sym] -= amount
      end
    end

    def cancel!
      @status = :cancelled
    end
  end
end
