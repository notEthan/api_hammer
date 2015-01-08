require 'strscan'

module ApiHammer
  module Filtration
    class FormEncoded
      def initialize(string, options = {})
        @string = string
        @options = options
      end

      def filter
        ss = StringScanner.new(@string)
        filtered = ''
        while !ss.eos?
          if ss.scan(/[&;]/)
            filtered << ss[0]
          end
          if ss.scan(/[^&;]+/)
            kv = ss[0]
            key, value = kv.split('=', 2)
            parsed_key = CGI::unescape(key)
            if [*@options[:filter_keys]].any? { |fk| parsed_key =~ /(\A|[\[\]])#{Regexp.escape(fk)}(\z|[\[\]])/ }
              filtered << [key, '[FILTERED]'].join('=')
            else
              filtered << ss[0]
            end
          end
        end
        filtered
      end
    end
  end
end
