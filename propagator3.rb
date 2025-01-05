#! /usr/bin/env ruby
#
# Simple exploration in Ruby of a propagator network. The idea is to
# get away from traditional linear-style computations.
#
# In this final ruby edition we want to write the simple example in
# propagator2.rb using openstruct. Openstruct, despite being a class,
# represents a record underneath. This leads to some more elegant
# sugar, e.g. a[:cell] becomes a.cell. The downside is some more
# openstruct noise in the debugging output.
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

require 'ostruct'

class Cell < OpenStruct
  def initialize
    super
    self.cell = :nothing
  end
end

class PropFunc < OpenStruct
end

class SimplePropagator < OpenStruct
end

# Runs the propagator when applicable and returns true on completion
def run_propagator prop
  return true if prop.state == :done
  if prop.state == :waiting
    # Check inputs
    prop.inputs.each do | input |
      p input.cell
      return false if input.cell == :nothing
    end
    prop.state = :compute
    false
  end

  if prop.state == :compute
    prop.output.cell = prop.propagator.run.call(prop.inputs,prop.output)
    prop.state = :done
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
      result.push run_propagator(propagator)
      p [try, propagator]
    end
    p result
    done = !result.index(false)
  end until done or try <= 0
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

propnet.append(SimplePropagator.new( :propagator => p_plus, :state => :waiting, :inputs => [c,d], :output => e ))
propnet.append(SimplePropagator.new( :propagator => p_plus, :state => :waiting, :inputs => [a,b], :output => c ))

p_multiply = PropFunc.new( :propagator => :multi, :run => lambda { |inputs, output| output.cell = inputs[0].cell * inputs[1].cell } )
propnet.append(SimplePropagator.new( :propagator => p_multiply, :state => :waiting, :inputs => [e,d], :output => f ))

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

 ./propagator2.rb
:nothing
[9, {:propagator=>{:func=>:add, :run=>#<Proc:0x00007f3355dde3b8 ./propagator2.rb:77 (lambda)>}, :state=>:waiting, :inputs=>[{:cell=>:nothing}, {:cell=>5}], :output=>{:cell=>:nothing}}]
2
3
[8, {:propagator=>{:func=>:add, :run=>#<Proc:0x00007f3355dde3b8 ./propagator2.rb:77 (lambda)>}, :state=>:done, :inputs=>[{:cell=>2}, {:cell=>3}], :output=>{:cell=>5}}]
:nothing
[7, {:propagator=>{:propagator=>:multi, :run=>#<Proc:0x00007f3355dde228 ./propagator2.rb:82 (lambda)>}, :state=>:waiting, :inputs=>[{:cell=>:nothing}, {:cell=>5}], :output=>{:cell=>:nothing}}]
[false, true, false]
5
5
[6, {:propagator=>{:func=>:add, :run=>#<Proc:0x00007f3355dde3b8 ./propagator2.rb:77 (lambda)>}, :state=>:done, :inputs=>[{:cell=>5}, {:cell=>5}], :output=>{:cell=>10}}]
[5, {:propagator=>{:func=>:add, :run=>#<Proc:0x00007f3355dde3b8 ./propagator2.rb:77 (lambda)>}, :state=>:done, :inputs=>[{:cell=>2}, {:cell=>3}], :output=>{:cell=>5}}]
10
5
[4, {:propagator=>{:propagator=>:multi, :run=>#<Proc:0x00007f3355dde228 ./propagator2.rb:82 (lambda)>}, :state=>:done, :inputs=>[{:cell=>10}, {:cell=>5}], :output=>{:cell=>50}}]
[true, true, true]
[{:propagator=>{:func=>:add, :run=>#<Proc:0x00007f3355dde3b8 ./propagator2.rb:77 (lambda)>}, :state=>:done, :inputs=>[{:cell=>5}, {:cell=>5}], :output=>{:cell=>10}}, {:propagator=>{:func=>:add, :run=>#<Proc:0x00007f3355dde3b8 ./propagator2.rb:77 (lambda)>}, :state=>:done, :inputs=>[{:cell=>2}, {:cell=>3}], :output=>{:cell=>5}}, {:propagator=>{:propagator=>:multi, :run=>#<Proc:0x00007f3355dde228 ./propagator2.rb:82 (lambda)>}, :state=>:done, :inputs=>[{:cell=>10}, {:cell=>5}], :output=>{:cell=>50}}]
5
10
50

=end
