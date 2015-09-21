require 'rack'

module ApiHammer
  class Body
    attr_reader :body, :content_type

    def initialize(body, content_type)
      @body = body
      @content_type = content_type
    end

    # parses the body to an object
    def object
      instance_variable_defined?(:@object) ? @object : @object = begin
        if media_type == 'application/json'
          JSON.parse(body) rescue nil
        elsif media_type == 'application/x-www-form-urlencoded'
          CGI.parse(body).map { |k, vs| {k => vs.last} }.inject({}, &:update)
        end
      end
    end

    def filtered(options)
      @filtered ||= Body.new(begin
        if media_type == 'application/json'
          begin
            ApiHammer::Filtration::Json.new(body, options).filter
          rescue JSON::ParserError
            body
          end
        elsif media_type == 'application/x-www-form-urlencoded'
          ApiHammer::Filtration::FormEncoded.new(body, options).filter
        else
          body
        end
      end, content_type)
    end

    def content_type_attrs
      @content_type_attrs ||= ContentTypeAttrs.new(content_type)
    end

    def media_type
      content_type_attrs.media_type
    end

    # deal with the vagaries of getting the response body in a form which JSON 
    # gem will not cry about generating 
    def jsonifiable
      @jsonifiable ||= Body.new(catch(:jsonifiable) do
        original_body = self.body
        unless original_body.is_a?(String)
          begin
            # if the response body is not a string, but JSON doesn't complain 
            # about dumping whatever it is, go ahead and use it
            JSON.generate([original_body])
            throw :jsonifiable, original_body
          rescue
            # otherwise return nil - don't know what to do with whatever this object is 
            throw :jsonifiable, nil
          end
        end

        # first try to change the string's encoding per the Content-Type header 
        body = original_body.dup
        unless body.valid_encoding?
          # I think this always comes in as ASCII-8BIT anyway so may never get here. hopefully.
          body.force_encoding('ASCII-8BIT')
        end

        content_type_attrs = ContentTypeAttrs.new(content_type)
        if content_type_attrs.parsed?
          charset = content_type_attrs['charset'].first
          if charset && Encoding.list.any? { |enc| enc.to_s.downcase == charset.downcase }
            if body.dup.force_encoding(charset).valid_encoding?
              body.force_encoding(charset)
            else
              # I guess just ignore the specified encoding if the result is not valid. fall back to 
              # something else below.
            end
          end
        end
        begin
          JSON.generate([body])
        rescue Encoding::UndefinedConversionError
          # if updating by content-type didn't do it, try UTF8 since JSON wants that - but only 
          # if it seems to be valid utf8. 
          # don't try utf8 if the response content-type indicated something else. 
          try_utf8 = !(content_type_attrs && content_type_attrs.parsed? && content_type_attrs['charset'].any?)
          if try_utf8 && body.dup.force_encoding('UTF-8').valid_encoding?
            body.force_encoding('UTF-8')
          else
            # I'm not sure if there is a way in this situation to get JSON gem to generate the 
            # string correctly. fall back to an array of codepoints I guess? this is a weird 
            # solution but the best I've got for now. 
            body = body.codepoints.to_a
          end
        end
        body
      end, content_type)
    end
  end
end
