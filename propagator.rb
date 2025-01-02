#! /usr/bin/env ruby
#
# Simple exploration in Ruby of a propagator network. The idea is to
# get away from traditional linear-style computations.
#
# Note that this example misses out on logic programming style
# resolution and lacks backtracking. Also it ignores incremental
# updating of cells and/or ranges. For a full implementation better
# check Raduls original thesis on Propagation Networks and more recent
# resources, including Sussman's book on "Software Design for
# Flexibility: How to Avoid Programming Yourself into a Corner".  As
# an example I particularly like Dave Thompson's alternative for
# react-type frameworks:
#
#    https://dthompson.us/posts/functional-reactive-user-interfaces-with-propagators.html
#
# This first example in Ruby creates a propnet as a DAG. Execution is
# via a simple round robin.  When inputs are complete the propagator
# runs and feeds it to the output. When outputs are complete we are
# done.  Note that it does not matter in what order we formulate the
# computation and there there is no if-then logic for computation
# paths. As state is contained in Cells it is perfectly viable to run
# computations in parallel.

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
      p self
      @inputs.each do | input |
        p input.value
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

class P_Multiply < Propagator
  def connect(pn, a, b, c)
    pn.append self
    @inputs = [ a, b ]
    @output = c
  end

  def f
    @output.value = inputs[0].value * inputs[1].value
    true
  end
end

def run pn
  # Run the propnet in a round robin fashion
  done = true
  try = 10 # max runs
  begin
    result = []
    # Try all propagators until they all return true
    pn.each do | propagator |
      try = try-1
      result.push propagator.run
      p [try, propagator]
    end
    p result
    done = !result.index(false)
  end until done or try <= 0
end

# Create the propnet. Note that the order of creating cells and propagators should not matter!
propnet = []

a = Cell.new()
b = Cell.new()
c = Cell.new()
d = Cell.new()
e = Cell.new()
f = Cell.new()

p_plus2 = P_Plus.new()
p_plus2.connect(propnet, c, d, e)

p_plus = P_Plus.new()
p_plus.connect(propnet, a, b, c)

p_multiply = P_Multiply.new()
p_multiply.connect(propnet, e, d, f)

a.value = 2
b.value = 3
d.value = 5

run(propnet)

# Inspect results
p propnet
p c.value
p e.value
p f.value

=begin

Resulting in:

gaeta:~/iwrk/opensource/ruby/propagator$ ./propagator.rb
#<P_Plus:0x00007fccf9117948 @state=:waiting, @inputs=[#<Cell:0x00007fccf9117fd8 @value=:nothing>, #<Cell:0x00007fccf9117f88 @value=5>], @output=#<Cell:0x00007fccf9117bf0 @value=:nothing>>
:nothing
[9, #<P_Plus:0x00007fccf9117948 @state=:waiting, @inputs=[#<Cell:0x00007fccf9117fd8 @value=:nothing>, #<Cell:0x00007fccf9117f88 @value=5>], @output=#<Cell:0x00007fccf9117bf0 @value=:nothing>>]
#<P_Plus:0x00007fccf91175b0 @state=:waiting, @inputs=[#<Cell:0x00007fccf9110080 @value=2>, #<Cell:0x00007fccf9110008 @value=3>], @output=#<Cell:0x00007fccf9117fd8 @value=:nothing>>
2
3
[8, #<P_Plus:0x00007fccf91175b0 @state=:done, @inputs=[#<Cell:0x00007fccf9110080 @value=2>, #<Cell:0x00007fccf9110008 @value=3>], @output=#<Cell:0x00007fccf9117fd8 @value=5>>]
#<P_Multiply:0x00007fccf9117448 @state=:waiting, @inputs=[#<Cell:0x00007fccf9117bf0 @value=:nothing>, #<Cell:0x00007fccf9117f88 @value=5>], @output=#<Cell:0x00007fccf9117b00 @value=:nothing>>
:nothing
[7, #<P_Multiply:0x00007fccf9117448 @state=:waiting, @inputs=[#<Cell:0x00007fccf9117bf0 @value=:nothing>, #<Cell:0x00007fccf9117f88 @value=5>], @output=#<Cell:0x00007fccf9117b00 @value=:nothing>>]
[false, true, false]
#<P_Plus:0x00007fccf9117948 @state=:waiting, @inputs=[#<Cell:0x00007fccf9117fd8 @value=5>, #<Cell:0x00007fccf9117f88 @value=5>], @output=#<Cell:0x00007fccf9117bf0 @value=:nothing>>
5
5
[6, #<P_Plus:0x00007fccf9117948 @state=:done, @inputs=[#<Cell:0x00007fccf9117fd8 @value=5>, #<Cell:0x00007fccf9117f88 @value=5>], @output=#<Cell:0x00007fccf9117bf0 @value=10>>]
[5, #<P_Plus:0x00007fccf91175b0 @state=:done, @inputs=[#<Cell:0x00007fccf9110080 @value=2>, #<Cell:0x00007fccf9110008 @value=3>], @output=#<Cell:0x00007fccf9117fd8 @value=5>>]
#<P_Multiply:0x00007fccf9117448 @state=:waiting, @inputs=[#<Cell:0x00007fccf9117bf0 @value=10>, #<Cell:0x00007fccf9117f88 @value=5>], @output=#<Cell:0x00007fccf9117b00 @value=:nothing>>
10
5
[4, #<P_Multiply:0x00007fccf9117448 @state=:done, @inputs=[#<Cell:0x00007fccf9117bf0 @value=10>, #<Cell:0x00007fccf9117f88 @value=5>], @output=#<Cell:0x00007fccf9117b00 @value=50>>]
[true, true, true]
[#<P_Plus:0x00007fccf9117948 @state=:done, @inputs=[#<Cell:0x00007fccf9117fd8 @value=5>, #<Cell:0x00007fccf9117f88 @value=5>], @output=#<Cell:0x00007fccf9117bf0 @value=10>>, #<P_Plus:0x00007fccf91175b0 @state=:done, @inputs=[#<Cell:0x00007fccf9110080 @value=2>, #<Cell:0x00007fccf9110008 @value=3>], @output=#<Cell:0x00007fccf9117fd8 @value=5>>, #<P_Multiply:0x00007fccf9117448 @state=:done, @inputs=[#<Cell:0x00007fccf9117bf0 @value=10>, #<Cell:0x00007fccf9117f88 @value=5>], @output=#<Cell:0x00007fccf9117b00 @value=50>>]
5
10
50

=end
