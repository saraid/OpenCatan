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
      def do; @actor.game.log_action(self); @done = true; end
      def undo; raise OpenCatanException, "Cannot undo what has not been done" unless @done; end

      class Done < Action
      end

      class Chat < Action
      end

      class Roll < Action
        def do
          roll = @actor.game.dice.roll(2)
          log "#{@actor.name} rolled #{roll}"
          super
          return roll
        end
      end

      class BuyAction < Action
        def do
          @resource_hash.each_pair do |resource, cost|
            raise OpenCatanException, "Insufficient #{resource}" if @actor.resources[resource] < cost
            @actor.resources[resource] -= cost
          end
          super
        end
        def undo
          super
          @resource_hash.each_pair do |resource, cost|
            @actor.resources[resource] += cost
          end
        end
      end
      class BuySettlement < BuyAction
        def initialize
          @resource_hash = { :wood => 1,
                             :wheat => 1,
                             :clay => 1,
                             :sheep => 1
                           }
        end
      end
      class BuyRoad < BuyAction
        def initialize
          @resource_hash = { :wood => 1,
                             :clay => 1,
                           }
        end
      end
      class BuyBoat < BuyAction
        def initialize
          @resource_hash = { :wood => 1,
                             :sheep => 1
                           }
        end
      end
      class BuyCity < BuyAction
        def initialize
          @resource_hash = { :wheat => 2,
                             :ore => 3
                           }
        end
      end
      class BuyCard < BuyAction
        def initialize
          @resource_hash = { :wheat => 1,
                             :sheep => 1,
                             :ore => 1
                           }
        end
        def do
          super
          @actor.draw_card
        end
      end

      class UpgradeSettlement < Action
        def self.on(intersection)
          raise OpenCatanException, "No settlement found" unless intersection.piece.is_a? Piece::Settlement
          action = self.new
          action.intersection = intersection
          action
        end
        attr_accessor :intersection
        def do
          @actor.receive_piece(:settlement, @intersection.piece)
          @intersection.piece = @actor.play_piece(:city)
          super
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
          super
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
