#! /usr/bin/env ruby
#
# Simple exploration in Ruby of a propagator network. Note that this example misses out
# on logic programming style resolution and lacks backtracking.
#
# This first version creates a propnet as a DAG. Execution is via a simple round robin.
# When inputs are complete the propagator runs and feeds it to the output.
#
#

class Cell
  attr_accessor :value
  def initialize()
    @value = :nothing
  end
end

class Propagator
  attr_accessor :inputs, :output

  def initialize
    @state = :waiting # :computing or :done
  end

  # Runs the propagator when applicable and returns true on completion
  def run
    return true if @state == :done

    if @state == :waiting
      # Check inputs
      @inputs.each do | input |
        return false if input.value == :nothing
      end
      @state = :compute
      false
    end

    if @state == :compute
      if f()
        @state = :done
        return true
      end
    end
    false
  end
end

class P_Plus < Propagator
  def connect(pn, a, b, c)
    pn.append self
    @inputs = [ a, b ]
    @output = c
  end

  def f
    @output.value = inputs[0].value + inputs[1].value
    true
  end
end

def run pn
  # Run the propnet in a round robin fashion
  done = true
  try = 3 # max runs
  begin
    done = true
    # Try all propagators until they all return true
    pn.each do | propagator |
      try -= 1
      done &&= propagator.run
      p [try, propagator, done]
    end
  end until done or try <= 0
end

propnet = []

a = Cell.new()
b = Cell.new()
c = Cell.new()

p_plus = P_Plus.new()

a.value = 2
b.value = 3

p_plus.connect(propnet, a, b, c)

d = Cell.new()
e = Cell.new()

d.value = 5

p_plus2 = P_Plus.new()
p_plus2.connect(propnet, c, d, e)

run(propnet)

p propnet
p c.value
p e.value

=begin

Results:

gaeta:~/iwrk/opensource/ruby/propagator$ ./propagator.rb
[2, #<P_Plus:0x00007fd57b838a08 @state=:done, @inputs=[#<Cell:0x00007fd57b839160 @value=2>, #<Cell:0x00007fd57b838d50 @value=3>], @output=#<Cell:0x00007fd57b838c88 @value=5>>, true]
[1, #<P_Plus:0x00007fd57b838760 @state=:done, @inputs=[#<Cell:0x00007fd57b838c88 @value=5>, #<Cell:0x00007fd57b838850 @value=5>], @output=#<Cell:0x00007fd57b8387b0 @value=10>>, true]
[#<P_Plus:0x00007fd57b838a08 @state=:done, @inputs=[#<Cell:0x00007fd57b839160 @value=2>, #<Cell:0x00007fd57b838d50 @value=3>], @output=#<Cell:0x00007fd57b838c88 @value=5>>, #<P_Plus:0x00007fd57b838760 @state=:done, @inputs=[#<Cell:0x00007fd57b838c88 @value=5>, #<Cell:0x00007fd57b838850 @value=5>], @output=#<Cell:0x00007fd57b8387b0 @value=10>>]
5
10

=end
