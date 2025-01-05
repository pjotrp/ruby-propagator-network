#! /usr/bin/env ruby
#
# Simple exploration in Ruby of a propagator network. The idea is to
# get away from traditional linear-style computations.
#
# In this edition we want to write the simple example in propagator.rb
# in a more functional programming (NP) style, by getting rid of the
# classes and introducing lambda.
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

# Runs the propagator when applicable and returns true on completion
def run_propagator prop
  return true if prop[:state] == :done
  if prop[:state] == :waiting
    # Check inputs
    prop[:inputs].each do | input |
      p input[:cell]
      return false if input[:cell] == :nothing
    end
    prop[:state] = :compute
    false
  end

  if prop[:state] == :compute
    prop[:output][:cell] = prop[:propagator][:run].call(prop[:inputs],prop[:output])
    prop[:state] = :done
    return true
  end
  false
end

def run_propnet pn
  # Run the propnet in a round robin fashion
  done = true
  try = 10 # max runs
  begin
    result = []
    # Try all propagators until they all return true
    pn.each do | propagator |
      try = try-1
      result.push run_propagator propagator
      p [try, propagator]
    end
    p result
    done = !result.index(false)
  end until done or try <= 0
end

# Create the propnet. Note that the order of creating cells and propagators should not matter!
propnet = []

a = { :cell => :nothing }
b = { :cell => :nothing }
c = { :cell => :nothing }
d = { :cell => :nothing }
e = { :cell => :nothing }
f = { :cell => :nothing }

p_plus = { :func => :add, :run => lambda { |inputs, output| output[:cell] = inputs[0][:cell] + inputs[1][:cell] } }

propnet.append({ :propagator => p_plus, :state => :waiting, :inputs => [c,d], :output => e} )
propnet.append({ :propagator => p_plus, :state => :waiting, :inputs => [a,b], :output => c} )

p_multiply = { :propagator => :multi, :run => lambda { |inputs, output| output[:cell] = inputs[0][:cell] * inputs[1][:cell] } }
propnet.append({ :propagator => p_multiply, :state => :waiting, :inputs => [e,d], :output => f} )

a[:cell] = 2
b[:cell] = 3
d[:cell] = 5

run_propnet(propnet)

# Inspect results
p propnet
p c[:cell]
p e[:cell]
p f[:cell]

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
