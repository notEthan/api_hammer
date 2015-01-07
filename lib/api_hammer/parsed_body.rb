require 'rack'

module ApiHammer
  class ParsedBody
    attr_reader :body, :content_type, :media_type

    def initialize(body, content_type)
      @body = body
      @content_type = content_type
      @media_type = ::Rack::Request.new({'CONTENT_TYPE' => content_type}).media_type
    end

    def object
      instance_variable_defined?(:@object) ? @object : @object = begin
        if media_type == 'application/json'
          JSON.parse(body) rescue nil
        elsif media_type == 'application/x-www-form-urlencoded'
          CGI.parse(body).map { |k, vs| {k => vs.last} }.inject({}, &:update)
        end
      end
    end

    def filtered_body(options)
      @filtered_body ||= begin
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
      end
    end
  end
end
