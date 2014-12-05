module ApiHammer
  class ParsedBody
    attr_reader :body, :content_type, :media_type, :object

    def initialize(body, content_type)
      @body = body
      @content_type = content_type
      @media_type = ::Rack::Request.new({'CONTENT_TYPE' => content_type}).media_type
      @object = begin
        if media_type == 'application/json'
          JSON.parse(body) rescue nil
        elsif media_type == 'application/x-www-form-urlencoded'
          CGI.parse(body).map { |k, vs| {k => vs.last} }.inject({}, &:update)
        end
      end
    end
  end
end
