# Propagator networks are Unix pipes on *steroids*.

What is not to love about Unix pipes - they allow programs to forward information and run in parallel: when data arrives the next program can start processing. This facilitiy is at the heart of the success of Unix and its small tool paradigm.
Over ten years ago I wrote up the [small tools manifesto](https://github.com/pjotrp/bioinformatics) to counter trends towards bigger monolithic solutions.

Despite the success story, Unix pipes are probably not the last word on dealing with intercomputational information sharing. I forgot who talked about the future concept of a 'wall of chips' and the computational challenges. Maybe it was Sussman. Anyway, we are going to have a future of walls of heterogeneous chips, including in RAM compute! How do you write software for such an environment that is useful and efficient?

What if Unix pipes could:

* Run in parallel on heterogeneous and mixed hardware
* Allow for bidirectional communication
* Allow for a run-graph rather than a linear path, even though propagators are linear themselves
* Deal with degeneration of results
* Allow for improving on results coming from multiple directions
* Track changes
* Allow for flexibe composing of logic
* Introduce lazy, on-demand, logic-programming back-tracking type schedulers?

Say HI to 'propagator networks'. And even though the concept sounds complicated the implementation can be as straightforward as
that of Unix pipes.

For a very minimalist implementation in Ruby, see the header of [propagator.rb](./propagator.rb).
The next numbered files in that repo are using lambda in propagator2.rb and OpenStruct in propagator3.rb.
propagator4.rb uses an on-demand callback 'scheduler' that is suitable for running external processes because the
execution path is now linear.

Other, a little more complicated, examples are:

* In the [ravanan](https://git.systemreboot.net/ravanan/tree/ravanan/propnet.scm) CWL runner Arun uses a propagator network to organize CWL jobs on slurm/PBS.
. To use ravanan with CWL you don't need to understand it. It just works (TM).
  * Dave Thompsom replaced Javascript's React with a propagator network that runs on web-assembly (WASM). It is a really nice [writeup](https://dthompson.us/posts/functional-reactive-user-interfaces-with-propagators.html).

Thanks Arun for driving home the importance of propagator networks (propnets) at the Elixir Biohackathon 2024.
