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
# In the previous example we used a callback method. That solution
# was elegant, but flawed. Here we introduce an event handler.
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
# Run request handler
#
#   ruby propagator5.rb
#
# Killall
#
#   kill $(ps aux | grep 'ruby\ propagator5.rb' | awk '{print $2}')

require 'ffi-rzmq'
require 'ostruct'

ADDRESS = "ipc:///tmp/test"
$pidlist = []

def assure(rc)
  raise "Last API call failed at #{caller(1)}" unless rc >= 0
end

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
def run_propagator num, prop
  return true if prop.state == :runnning or prop.state == :done
  if prop.state == nil or prop.state == :waiting
    # Check inputs
    prop.inputs.each do | input |
      # p input.cell
      return false if input.cell == :nothing
    end
    prop.state = :prepare_compute
  end

  if prop.state == :prepare_compute
    prop.state = :running
    pid = fork do
      p [num, :client, ADDRESS]
      ctx = ZMQ::Context.new
      s   = ctx.socket ZMQ::REQ
      assure(rc  = s.connect(ADDRESS))
      p [:client_send]
      msg = ":hello"
      assure(s.send_string(msg, 0))
      msg = ''
      p [:client_waiting]
      assure(s.recv_string(msg, 0))
      p [num, "opened", :client_received, msg]
      # in this forked process the inputs are available, but the
      # output needs to be passed back with a pid to destroy the
      # process. Note we assume the values are stringifiable ints.
      # Propagators are indexed by num.
      prop.output.cell = prop.propagator.run.call(prop.inputs,prop.output)
      msg = ":done"
      s.send_string(msg, ZMQ::SNDMORE)
      s.send_string(num.to_s, ZMQ::SNDMORE)
      s.send_string(prop.output.cell.to_s, 0)
      p [:client_waiting]
      assure(s.recv_string(msg, 0))
      p [num, :client_received, msg]
      s.close
      ctx.terminate
      sleep 5 # prevent invalidating 0MQ queue on exit
    end
    Process.detach(pid)
    $pidlist.push pid
  end
  false
end

def run_propnet pn
  # Run the propnet in a round robin fashion
  p [:server,ADDRESS]
  ctx = ZMQ::Context.new
  s   = ctx.socket ZMQ::REP
  rc  = s.setsockopt(ZMQ::SNDHWM, 100)
  rc  = s.setsockopt(ZMQ::RCVHWM, 100)
  assure(rc  = s.bind(ADDRESS))
  # Fire up all propagators that are ready
  p [:round_robin_propnet_bootstrap]
  pn.each_with_index do | propagator, num |
    # fire up propagators
    run_propagator(num, propagator)
  end

  # Run the event loop
  while true
    p [:server_waiting]
    msg = ""
    assure(s.recv_string msg)
    p [:server_received, msg]
    case msg
    when ':hello'
      assure(s.send_string "World", 0)
    when ':progress'
      msg = ""
      assure(s.recv_string msg)
      p [:progress, msg]
      assure(s.send_string ":OK", 0)
    when ':done'
      assure(s.recv_string msg)
      prop_num = msg.to_i
      assure(s.recv_string msg)
      result = msg.to_i
      prop = pn[prop_num]
      prop.output.cell = result
      prop.state = :done
      p [:prop_num,prop_num,:prop_output,result]
      assure(s.send_string ":OK", 0)
      pn[prop_num] = prop

      # Fire up all propagators that are ready
      p [:round_robin_propnet,prop_num]
      still_running = false
      pn.each_with_index do | propagator, num |
        p [:num, num, :state, propagator.state, propagator]
        # try to fire up propagator
        run_propagator(num, propagator)
        still_running = true if propagator.state != :done
      end
      break if not still_running

    else
      raise "Unknown client message"
    end
  end
  s.close
  ctx.terminate
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

$pidlist.each do |client_pid|
  begin
    Process.kill('HUP',client_pid)
  rescue
    p [client_pid, " pid already got killed"]
  end
end

# p("Killing children")
# pidlist.each do |pid|
#   begin
#     Process.kill('HUP',pid)
#   rescue
#     p [pid, "already got killed"]
#   end
# end

=begin

Resulting in:

./propagator3.rb
:nothing
[9, #<SimplePropagator propagator=#<PropFunc func=:add, run=#<Proc:0x00007fe2521ca778 ./propagator3.rb:94 (lambda)>>, state=:waiting, inputs=[#<Cell cell=:nothing>, #<Cell cell=5>], output=#<Cell cell=:nothing>>]
2
3
[8, #<SimplePropagator propagator=#<PropFunc func=:add, run=#<Proc:0x00007fe2521ca778 ./propagator3.rb:94 (lambda)>>, state=:done, inputs=[#<Cell cell=2>, #<Cell cell=3>], output=#<Cell cell=5>>]
:nothing
[7, #<SimplePropagator propagator=#<PropFunc propagator=:multi, run=#<Proc:0x00007fe2521cde78 ./propagator3.rb:99 (lambda)>>, state=:waiting, inputs=[#<Cell cell=:nothing>, #<Cell cell=5>], output=#<Cell cell=:nothing>>]
[false, true, false]
5
5
[6, #<SimplePropagator propagator=#<PropFunc func=:add, run=#<Proc:0x00007fe2521ca778 ./propagator3.rb:94 (lambda)>>, state=:done, inputs=[#<Cell cell=5>, #<Cell cell=5>], output=#<Cell cell=10>>]
[5, #<SimplePropagator propagator=#<PropFunc func=:add, run=#<Proc:0x00007fe2521ca778 ./propagator3.rb:94 (lambda)>>, state=:done, inputs=[#<Cell cell=2>, #<Cell cell=3>], output=#<Cell cell=5>>]
10
5
[4, #<SimplePropagator propagator=#<PropFunc propagator=:multi, run=#<Proc:0x00007fe2521cde78 ./propagator3.rb:99 (lambda)>>, state=:done, inputs=[#<Cell cell=10>, #<Cell cell=5>], output=#<Cell cell=50>>]
[true, true, true]
[#<SimplePropagator propagator=#<PropFunc func=:add, run=#<Proc:0x00007fe2521ca778 ./propagator3.rb:94 (lambda)>>, state=:done, inputs=[#<Cell cell=5>, #<Cell cell=5>], output=#<Cell cell=10>>, #<SimplePropagator propagator=#<PropFunc func=:add, run=#<Proc:0x00007fe2521ca778 ./propagator3.rb:94 (lambda)>>, state=:done, inputs=[#<Cell cell=2>, #<Cell cell=3>], output=#<Cell cell=5>>, #<SimplePropagator propagator=#<PropFunc propagator=:multi, run=#<Proc:0x00007fe2521cde78 ./propagator3.rb:99 (lambda)>>, state=:done, inputs=[#<Cell cell=10>, #<Cell cell=5>], output=#<Cell cell=50>>]
5
10
50

=end
