module Kernel
  # this is the Y-combinator, which allows anonymous recursive functions. for a simple example, 
  # to define a recursive function to return the length of an array:
  #
  #  length = ycomb do |len|
  #    proc{|list| list == [] ? 0 : 1 + len.call(list[1..-1]) }
  #  end
  #
  # see https://secure.wikimedia.org/wikipedia/en/wiki/Fixed_point_combinator#Y_combinator
  # and chapter 9 of the little schemer, available as the sample chapter at http://www.ccs.neu.edu/home/matthias/BTLS/
  def ycomb
    proc { |f| f.call(f) }.call(proc { |f| yield proc{|*x| f.call(f).call(*x) } })
  end
  module_function :ycomb
end
