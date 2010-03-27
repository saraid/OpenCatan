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
    end
  end
end
