module Conflux
  module Helpers
    class Env
      # Will come in handy when adding windows support

      def self.[](key)
        val = ENV[key]

        if val && Conflux::Helpers.running_on_windows? && val.encoding == Encoding::ASCII_8BIT
          val = val.dup.force_encoding('utf-8')
        end

        val
      end
    end
  end
end
