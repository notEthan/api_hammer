class << Dir
  # prefix any glob-special characters in path with backslashes 
  def glob_escape(path)
    path.gsub(/[*?\[\]{}\\]/) { |match| "\\#{match}" }
  end
end

require 'pathname'
class Pathname
  # prefix any glob-special characters in this path with backslashes 
  def glob_escape
    self.class.new(Dir.glob_escape(self.to_path))
  end
end
