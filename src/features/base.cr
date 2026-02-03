module Crybot
  module Features
    abstract class FeatureModule
      @running : Bool = false

      abstract def start : Nil
      abstract def stop : Nil

      def running? : Bool
        @running
      end
    end
  end
end
