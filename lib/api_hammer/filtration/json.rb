require 'json'
require 'json/pure/parser'

module ApiHammer
  module Filtration
    class ParserError < JSON::ParserError; end

    # This class implements the JSON filterer that is used to filter a JSON string
    class Json < JSON::Pure::Parser
      # Creates a new instance for the string _source_.
      def initialize(source, opts = {})
        super source
        @options = opts
      end

      def filter
        reset
        obj = ''
        while !eos? && scan_result(obj, IGNORE)
        end
        if eos?
          raise ParserError, "source did not contain any JSON!"
        else
          value = filter_value
          if value == UNPARSED
            raise ParserError, "source did not contain any JSON!"
          else
            obj << value
          end
        end
        obj
      end

      private

      def filter_string
        if scan(STRING)
          self[0]
        else
          UNPARSED
        end
      end

      def filter_value
        simple = [FLOAT, INTEGER, TRUE, FALSE, NULL] + (@allow_nan ? [NAN, INFINITY, MINUS_INFINITY] : [])
        if simple.any? { |type| scan(type) }
          self[0]
        elsif (string = filter_string) != UNPARSED
          string
        elsif scan(ARRAY_OPEN)
          self[0] + filter_array
        elsif scan(OBJECT_OPEN)
          self[0] + filter_object
        else
          UNPARSED
        end
      end

      def filter_array
        result = ''
        delim = false
        until eos?
          if (value = filter_value) != UNPARSED
            delim = false
            result << value
            scan_result(result, IGNORE)
            if scan_result(result, COLLECTION_DELIMITER)
              delim = true
            elsif !match?(ARRAY_CLOSE)
              raise ParserError, "expected ',' or ']' in array at '#{peek(20)}'!"
            end
          elsif scan_result(result, ARRAY_CLOSE)
            if delim
              raise ParserError, "expected next element in array at '#{peek(20)}'!"
            end
            break
          elsif scan_result(result, IGNORE)
            #
          else
            raise ParserError, "unexpected token in array at '#{peek(20)}'!"
          end
        end
        result
      end

      FILTERED_JSON = JSON.generate("[FILTERED]", :quirks_mode => true)

      def filter_object
        result = ''
        delim = false
        until eos?
          if (string = filter_string) != UNPARSED
            parsed_key = JSON.parse(string, :quirks_mode => true)
            result << string
            scan_result(result, IGNORE)
            unless scan_result(result, PAIR_DELIMITER)
              raise ParserError, "expected ':' in object at '#{peek(20)}'!"
            end
            scan_result(result, IGNORE)
            unless (value = filter_value).equal? UNPARSED
              if [*@options[:filter_keys]].include?(parsed_key)
                result << FILTERED_JSON
              else
                result << value
              end
              delim = false
              scan_result(result, IGNORE)
              if scan_result(result, COLLECTION_DELIMITER)
                delim = true
              elsif !match?(OBJECT_CLOSE)
                raise ParserError, "expected ',' or '}' in object at '#{peek(20)}'!"
              end
            else
              raise ParserError, "expected value in object at '#{peek(20)}'!"
            end
          elsif scan_result(result, OBJECT_CLOSE)
            if delim
              raise ParserError, "expected next name, value pair in object at '#{peek(20)}'!"
            end
            break
          elsif scan_result(result, IGNORE)
            #
          else
            raise ParserError, "unexpected token in object at '#{peek(20)}'!"
          end
        end
        result
      end

      def scan_result(result, match)
        if scan(match)
          result << self[0]
        end
      end
    end
  end
end
