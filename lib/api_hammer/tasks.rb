require 'pathname'
Pathname.new(__FILE__).dirname.join('tasks').children.select { |c| c.to_s =~ /\.rb\z/ }.each do |taskfile|
  require taskfile
end
