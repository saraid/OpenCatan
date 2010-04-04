# done
# roll
# chat, message
# 
# spend, resource_hash # on gold, year-of-plenty, and monopoly cards
# discard, resource_hash
# place, robber, hex_coords # on 7s and knight cards
# 
# buy, settlement
# place, settlement, intersection_id
# buy, road
# place, road, path_id
# buy, boat
# place, boat, path_id
# buy, city
# upgrade, intersection_id
# 
# buy, card
# play, card_id
# 
# trade
# propose, offer: resource_hash, demand: resource_hash
# accept, proposal_id
# reject, proposal_id
# block, resource_hash
# offer_more # because it's funny

module OpenCatan
  class Player
    def act(action)
      action.actor = self
      action.do
    end

    class Action
      attr_accessor :actor

      class Done < Action
      end

      class Chat < Action
      end

      class Roll < Action
        def do
          roll = @actor.game.dice.roll(2)
          log "#{@actor.name} rolled #{roll}"
          roll
        end
      end

      class PlaceAction < Action
        def self.on(location)
          action = self.new
          action.location = location
          action
        end
        attr_accessor :location
        def do
          @location.piece = @actor.play_piece(@piece_type)
          log "#{@actor.name} placed a #{@piece_type} on #{@location}"
        end
      end
      class PlaceSettlement < PlaceAction
        def initialize; @piece_type = :settlement; end
      end
      class PlaceRoad < PlaceAction
        def initialize; @piece_type = :road; end
      end
      class PlaceBoat < PlaceAction
        def initialize; @piece_type = :boat; end
      end
    end
  end
end
