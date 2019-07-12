module Gitlab
  class Util
    class << self
      def get_env(key)
        ret = ENV[key]

        if ret.is_a? String
          ret&.strip
        else
          ret
        end
      end

      def set_env(key, value)
        ENV[key] = value&.strip
      end

      def set_env_if_missing(key, value)
        ENV[key] ||= value&.strip
      end
    end
  end
end
