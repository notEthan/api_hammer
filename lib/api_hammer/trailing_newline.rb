require 'rack'

module ApiHammer
  # Rack middleware which adds a trailing newline to any responses which do not include one. 
  #
  # one effect of this is to make curl more readable, as without this, the prompt that follows the 
  # request will be on the same line. 
  #
  # does not add a newline to blank responses.
  class TrailingNewline
    def initialize(app)
      @app=app
    end
    class TNLBodyProxy < Rack::BodyProxy
      def each
        last_has_newline = false
        blank = true
        @body.each do |e|
          last_has_newline = e =~ /\n\z/m
          blank = false if e != ''
          yield e
        end
        yield "\n" unless blank || last_has_newline
      end
      include Enumerable
    end
    def call(env)
      status, headers, body = *@app.call(env)
      _, content_type = headers.detect { |(k,_)| k =~ /\Acontent.type\z/i }
      if env['REQUEST_METHOD'].downcase != 'head' && ApiHammer::ContentTypeAttrs.new(content_type).text?
        body = TNLBodyProxy.new(body){}
        if headers["Content-Length"]
          headers["Content-Length"] = body.map(&:bytesize).inject(0, &:+).to_s
        end
      end
      [status, headers, body]
    end
  end
end
