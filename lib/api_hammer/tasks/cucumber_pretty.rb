namespace :cucumber do
  desc "replaces json in pystrings in feature files with pretty-printed json"
  task :pretty_json do
    require 'json'

    features = Dir['features/**/*.feature']

    features.each do |feature_file|
      any_changes = false
      feature = File.read(feature_file)
      line_blocks = [[]]
      feature.split("\n", -1).each do |line|
        triq = line =~ /\A\s*"""\s*\z/
        line_blocks << [] if triq
        line_blocks.last << line
        line_blocks << [] if triq
      end

      line_blocks.each_slice(4) do |steps, triq1, quoted_string_parts, triq2|
        next unless triq1 # last one
        quoted_string = quoted_string_parts.join("\n")
        ws = triq1.first[/\A\s*/]
        ws += '  '

        begin
          object = JSON.parse(quoted_string)
          # I don't like how JSON prettifies empty arrays and objects - special case these 
          if object == []
            pretty_json = '[]'
          elsif object == {}
            pretty_json = '{}'
          else
            pretty_json = JSON.pretty_generate(object)
          end
          pretty_quoted_string_parts = pretty_json.split("\n", -1).grep(/\S/).map{|jline| "#{ws}#{jline}" }
          unless pretty_quoted_string_parts == quoted_string_parts
            quoted_string_parts.replace(pretty_quoted_string_parts)
            any_changes = true
          end
        rescue JSON::ParserError
          # that wasn't json. leave it alone. 
        end

      end

      if any_changes
        STDERR.puts "prettifying json: #{feature_file}"
        File.open(feature_file, 'w') do |f|
          f.write(line_blocks.inject([], &:+).join("\n"))
        end
      end
    end
  end

  desc "removes trailing whitespace from feature files"
  task :trailing_whitespace do
    features = Dir['features/**/*.feature']
    features.each do |feature_file|
      feature = File.read(feature_file)
      lines = feature.split("\n", -1)
      ntwslines = lines.map { |line| line =~ /\s+\z/ ? $` : line }
      ntwslines.pop while ntwslines.last.empty?

      feature_no_tws = ntwslines.join("\n") + "\n"

      if feature != feature_no_tws
        STDERR.puts "removing trailing whitespace: #{feature_file}"
        File.open(feature_file, 'w') do |f|
          f.write(feature_no_tws)
        end
      end
    end
  end
end
