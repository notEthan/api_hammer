require 'json'
module ApiHammer
  module JsonScriptEscapeHelper
    # takes an object which can be used to generate JSON, and formats it 
    # so that it may be safely be inserted inside a <script> tag. 
    #
    # example: safely assigning the javascript variable foo to what's currently in the ruby variable foo.
    #
    #     <script>
    #     foo = <%= json_script_escape(foo) %>;
    #     </script>
    #
    # the string is expressed as JSON, which applies proper escaping to any characters special to 
    # javascript, and then further escapes any <, >, and / characters which may otherwise introduce 
    # such things as </script> tags.
    #
    # this is aliased as #j, which replaces the j helper built into rails which requires quotes to 
    # be added around strings and does not support objects other than strings.
    def json_script_escape(object)
      encoded = JSON.generate(object, :quirks_mode => true)
      escaped = encoded.gsub(%r([<>/])) { |x| x.codepoints.map { |p| "\\u%.4x" % p }.join }
      escaped.respond_to?(:html_safe) ? escaped.html_safe : escaped
    end
    module_function :json_script_escape

    alias j json_script_escape
    module_function :j
  end
end
