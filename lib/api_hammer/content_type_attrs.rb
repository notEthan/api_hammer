module ApiHammer
  # parses attributes out of content type header
  class ContentTypeAttrs
    def initialize(content_type)
      @media_type = content_type.split(/\s*[;]\s*/, 2).first if content_type
      @media_type.strip! if @media_type
      @content_type = content_type
      @parsed = false
      @attributes = Hash.new { |h,k| h[k] = [] }
      catch(:unparseable) do
        throw(:unparseable) unless content_type
        uri_parser = URI.const_defined?(:Parser) ? URI::Parser.new : URI
        scanner = StringScanner.new(content_type)
        scanner.scan(/.*;\s*/) || throw(:unparseable)
        while match = scanner.scan(/(\w+)=("?)([^"]*)("?)\s*(,?)\s*/)
          key = scanner[1]
          quote1 = scanner[2]
          value = scanner[3]
          quote2 = scanner[4]
          comma_follows = !scanner[5].empty?
          throw(:unparseable) unless quote1 == quote2
          throw(:unparseable) if !comma_follows && !scanner.eos?
          @attributes[uri_parser.unescape(key)] << uri_parser.unescape(value)
        end
        throw(:unparseable) unless scanner.eos?
        @parsed = true
      end
    end

    attr_reader :media_type

    def parsed?
      @parsed
    end

    def [](key)
      @attributes[key]
    end

    def text?
      # ordered hash by priority mapping types to binary or text
      # regexps will have \A and \z added 
      types = {
        %r(image/.*) => :binary,
        %r(audio/.*) => :binary,
        %r(video/.*) => :binary,
        %r(model/.*) => :binary,
        %r(text/.*) => :text,
        %r(message/.*) => :text,
        'application/octet-stream' => :binary,
        'application/ogg' => :binary,
        'application/pdf' => :binary,
        'application/postscript' => :binary,
        'application/zip' => :binary,
        'application/gzip' => :binary,
      }
      types.each do |match, type|
        matched = match.is_a?(Regexp) ? media_type =~ %r(\A#{match.source}\z) : media_type == match
        if matched
          return type == :text
        end
      end
      # fallback (unknown or not given) assume text
      return true
    end
  end
end
