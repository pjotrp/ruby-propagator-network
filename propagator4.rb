#! /usr/bin/env ruby
#
# Simple exploration in Ruby of a propagator network. The idea is to
# get away from traditional linear-style computations.
#
# In this final final ruby edition we prepare to use messaging to
# create propagators that connect over a network. The advantage is
# that every propagator becomes an independent network server and the
# 'scheduler' is non-blocking so computations can become parallel. In
# this example the scheduling method is changed. Here the propagator
# network runs once and then every time a propagator finishes.
#
# In this example we use a callback method. Basically the 'schedular'
# rotates through all propagators every time a propagator finishes.
# This also allows running a limited set of propagators at a time (we
# won't handle that here). We could also add a time out for every
# propagator. This simplifies the 'scheduler' and produces less output
# to boot!
#
# For the messaging setup it allows a propagator to run as long as it
# is required --- only updating the network when it is done. This
# allows for external processes to run.
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
#
# Run with something like
#
#  rub propagator4.rb

require 'ostruct'

# A cell handles state. The cell field reflects whether it holds something or :nothing
class Cell < OpenStruct
  def initialize
    super
    self.cell = :nothing
  end
end

class PropFunc < OpenStruct
end

# A propagator has input fields and an output field
class SimplePropagator < OpenStruct
end

# Runs the propagator when applicable and callbacks rerun_propnet on
# completion. It has inputs and an output.  The 'state' field tracks
# the compute state (:waiting, :compute, :done). The run fields holds
# the lambda to execute and func holds the name of the function. So:
#
#   :func   function name
#   :state  computation state (:waiting, :compute, :done)
#   :inputs list of input cells
#   :output output cell
#
def run_propagator prop, rerun_propnet, pn
  return if prop.state == :done
  if prop.state == nil or prop.state == :waiting
    # Check inputs
    prop.inputs.each do | input |
      p input.cell
      return if input.cell == :nothing
    end
    prop.state = :compute
  end

  if prop.state == :compute
    prop.output.cell = prop.propagator.run.call(prop.inputs,prop.output)
    prop.state = :done
    rerun_propnet.call(pn)
  end
end

def run_propnet pn
  # Runs propnet once and then every time a propagator completes susing the call back method
  pn.each do | propagator |
    run_propagator(propagator, method(:run_propnet), pn)
  end
end

# Create the propnet. Note that the order of creating cells and propagators should not matter!
propnet = []

a = Cell.new
b = Cell.new
c = Cell.new
d = Cell.new
e = Cell.new
f = Cell.new

p_plus = PropFunc.new( :func => :add, :run => lambda { |inputs, output| output.cell = inputs[0].cell + inputs[1].cell } )

propnet.append(SimplePropagator.new( :propagator => p_plus, :inputs => [c,d], :output => e ))
propnet.append(SimplePropagator.new( :propagator => p_plus, :inputs => [a,b], :output => c ))

p_multiply = PropFunc.new( :propagator => :multi, :run => lambda { |inputs, output| output.cell = inputs[0].cell * inputs[1].cell } )
propnet.append(SimplePropagator.new( :propagator => p_multiply, :inputs => [e,d], :output => f ))

a.cell = 2
b.cell = 3
d.cell = 5

run_propnet(propnet)

# Inspect results
p propnet
p c.cell
p e.cell
p f.cell

=begin

Resulting in:

./propagator4.rb
:nothing
2
3
5
5
10
5
[#<SimplePropagator propagator=#<PropFunc func=:add, run=#<Proc:0x00007ff95b966700 propagator4.rb:112 (lambda)>>, state=:done, inputs=[#<Cell cell=5>, #<Cell cell=5>], output=#<Cell cell=10>>, #<SimplePropagator propagator=#<PropFunc func=:add, run=#<Proc:0x00007ff95b966700 propagator4.rb:112 (lambda)>>, state=:done, inputs=[#<Cell cell=2>, #<Cell cell=3>], output=#<Cell cell=5>>, #<SimplePropagator propagator=#<PropFunc propagator=:multi, run=#<Proc:0x00007ff95b969dd8 propagator4.rb:117 (lambda)>>, state=:done, inputs=[#<Cell cell=10>, #<Cell cell=5>], output=#<Cell cell=50>>]
5
10
50


=end
