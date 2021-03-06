require 'faraday'
require 'rack'
require 'api_hammer'

module ApiHammer
  # outputs the response body to the given logger or output device (defaulting to STDOUT) 
  class FaradayOutputter < ::Faraday::Middleware
    def initialize(app, options={})
      @app=app
      @options = options
      @outdev = @options[:outdev] || STDOUT
    end

    def call(request_env)
      @app.call(request_env).on_complete do |response_env|
        puts(response_env[:body] || '')
      end
    end

    def puts(str)
      meth = @options[:logger] ? @options[:logger].method(:info) : (@options[:outdev] || STDOUT).method(:puts)
      meth.call(str)
    end
  end

  # this is to approximate `curl -v`s output. but it's all faked, whereas curl gives you 
  # the real text written and read for request and response. whatever, close enough. 
  class FaradayCurlVOutputter < FaradayOutputter

    # defines a method with the given name, applying coloring defined by any additional arguments. 
    # if @options[:color] is set, respects that; otherwise, applies color if the output device is a tty. 
    def self.color(name, *color_args)
      define_method(name) do |arg|
        if color?
          require 'term/ansicolor'
          color_args.inject(arg) do |result, color_arg|
            Term::ANSIColor.send(color_arg, result)
          end
        else
          arg
        end
      end
    end

    color :info, :intense_yellow
    color :info_body, :yellow
    color :protocol

    color :request, :intense_cyan
    color :request_verb, :bold
    color :request_header
    color :request_blankline, :intense_cyan, :bold

    color :response, :intense_green
    color :response_status, :bold, :green
    color :response_header
    color :response_blankline, :intense_green, :bold

    color :omitted_body, :intense_yellow

    def call(request_env)
      puts "#{info('*')} #{info_body("connect to #{request_env[:url].host} on port #{request_env[:url].port}")}"
      puts "#{info('*')} #{info_body("getting our SSL on")}" if request_env[:url].scheme=='https'
      puts "#{request('>')} #{request_verb(request_env[:method].to_s.upcase)} #{request_env[:url].request_uri} #{protocol("HTTP/#{Net::HTTP::HTTPVersion}")}"
      request_env[:request_headers].each do |k, v|
        puts "#{request('>')} #{request_header(k)}#{request(':')} #{v}"
      end
      puts "#{request_blankline('>')} "
      request_body = alter_body_by_content_type(request_env[:body], request_env[:request_headers]['Content-Type'])
      (request_body || '').split("\n", -1).each do |line|
        puts "#{request('>')} #{line}"
      end
      @app.call(request_env).on_complete do |response_env|
        puts "#{response('<')} #{protocol("HTTP/#{Net::HTTP::HTTPVersion}")} #{response_status(response_env[:status].to_s)}"
        request_env[:response_headers].each do |k, v|
          puts "#{response('<')} #{response_header(k)}#{response(':')} #{v}"
        end
        puts "#{response_blankline  ('<')} "
        response_body = alter_body_by_content_type(response_env[:body], response_env[:response_headers]['Content-Type'])
        (response_body || '').split("\n", -1).each do |line|
          puts "#{response('<')} #{line}"
        end
      end
    end

    def pretty?
      @options[:pretty].nil? ? true : @options[:pretty]
    end

    # whether to use color. if we're writing to a device, check if it's a tty; otherwise we should have a 
    # logger and just assume color.
    def color?
      if @options[:color].nil?
        @options[:outdev] ? @options[:outdev].tty? : true
      else
        @options[:color]
      end
    end

    # a mapping for each registered CodeRay scanner to the Media Types which represent 
    # that language. extremely incomplete! 
    CodeRayForMediaTypes = {
      :c => [],
      :cpp => [],
      :clojure => [],
      :css => ['text/css', 'application/css-stylesheet'],
      :delphi => [],
      :diff => [],
      :erb => [],
      :groovy => [],
      :haml => [],
      :html => ['text/html'],
      :java => [],
      :java_script => ['application/javascript', 'text/javascript', 'application/x-javascript'],
      :json => ['application/json'],
      :php => [],
      :python => ['text/x-python'],
      :ruby => [],
      :sql => [],
      :xml => ['text/xml', 'application/xml', %r(\Aapplication/.*\+xml\z)],
      :yaml => [],
    }

    # takes a body and a content type; returns the body, altered according to options.
    #
    # - with coloring (ansi colors for terminals) possibly added, if it's a recognized content type and 
    #   #color? is true 
    # - formatted prettily if #pretty? is true
    def alter_body_by_content_type(body, content_type)
      return body unless body.is_a?(String)
      content_type_attrs = ApiHammer::ContentTypeAttrs.new(content_type)
      if @options[:text].nil? ? content_type_attrs.text? : @options[:text]
        if pretty?
          case content_type_attrs.media_type
          when 'application/json'
            require 'json'
            begin
              body = JSON.pretty_generate(JSON.parse(body))
            rescue JSON::ParserError
            end
          end
        end
        if color?
          coderay_scanner = CodeRayForMediaTypes.reject{|k,v| !v.any?{|type| type === content_type_attrs.media_type} }.keys.first
          if coderay_scanner
            require 'coderay'
            body = CodeRay.scan(body, coderay_scanner).encode(:terminal)
          end
        end
      else
        body = omitted_body("[[omitted binary body (size = #{body.size})]]")
      end
      body
    end
  end
end
