# FancyCommand

Wrapper around Open3 making it easier to live-stream command output and
chain commands together. See [Usage](#usage) below for code examples.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fancy_command'
```

And then execute:

```sh
$ bundle
```

Or install it yourself as:

```sh
$ gem install fancy_command
```

## Usage

The best way to explain this is with some example code:

```ruby
require 'fancy_command'
include FancyCommand

namespace :bower do
  task :setup do
    run("which bower").unless_success_then do
      run "npm install -g bower", must_succeed: true
    end
  end

  task :install => :setup do
    run "bower install", must_succeed: true
  end
end
```

There are a few things to note here:

* Including `FancyCommand` adds a `#run` method
* There are chaining methods (run returns the command itself)
* The `must_succeed` flag

### Including

The `FancyCommand` module impliments two includable methods:

* `#run(string, **opts, &blk)`
* `#command(string, **opts, &blk)`

`#command` will instantiate a new `FancyCommand::Command` and `#run`
will instantiate and then `#call` that command.

### Chaining

There are three methods that can be used to chain commands together:

* `#then`
* `#if_success_then`
* `#unless_success_then`

The all accept a block expecting either one or zero arguments. If one
argument is expected then it will be the instance of the previous
command.

### `must_succeed: true`

When this flag is set then any non-zero `exitstatus` will cause an
exception to be raised (`FancyCommand::Command::Failed`). The exception
impliments `#command` (the string), `#status` (the `exitstatus`), and
`#output` (a string of the combined stdout and stderr).

- - -

Another example to show off is:

```ruby
require 'fancy_command'
include FancyCommand

# get the date

command = run("date") | "awk '{ print $2 }'"
puts command.output

# find the Gemfiles

run("ls") | command("grep Gem", accum: $stdout)

# live stream build logs

require 'some_websocket_client_library'
require 'bugsnag'
require 'bugsnag_configuration'
socket = SomeWebsocketClientLibrary.new(ENV["WEBSOCKET_URL"])
run("build_script.sh", accum: socket).unless_success_then do |command|
  Bugsnag.notify(RuntimeError.new("'#{command.string}' failed", {
    command: command.string,
    stout: command.out,
    sterr: command.err,
    status: command.exitstatus,
    pid: command.pid
  })
end
```

A few things to notice:

* One can `#|` (or `#pipe`) commands to each other
* Commands have `#output`
* There is an `accum:` argument
* A command has `#out`, `#err`, `#exitstatus`, etc

### Piping

All `FancyCommand::Command` instances impliment `#pipe` (and `#|`)
which:

1. Instantiates a command from a string copying the `#accum` (unless it's already a command)
2. Copies the output of the first command to the input of the second
3. Calls and returns the second command

This is not exactly like a unix pipe, so infinite pipes will not work.
Each command waits until it has fully executed to go on to the next one.
If you really want to use real pipes either use `Open3.pipeline` or just
make a command string with the pipes in it.

### Output and accum

The combined result of stdout and stderr is accessible as `#output`.
However, the is also an additional object one can use to accumulate
output as it streams in:

For each line of stdout or stderr, the `accum` object receives the `#<<`
message with the line as an argument (the line will have a \n
character). The accumulator object does not need to be threadsafe, a
mutex is used to make sure that the `#<<` message is never delivered
twice at once. The easiest example is to provide `$stdout` as the
accumulator, which will output every resulting line as it streams in.

I built this feature so I could stream build logs over websockets.

### Other methods

The important methods are:

* `#out` only stdout
* `#err` only stderr
* `#output` combined stdout and stderr (also should be interleaved into
  the order of delivery from the command)
* `#exitstatus` is the integer exit code from the command
* `#success?` will be true only for zero exit codes

### Verbose

There also is a `verbose:` argument that can be passed in as true. All
it does right now is output the command to stdout right before it is
executed. If you want to output the command's result just use `$stdout`
as `accum:`.

Here is an example:

```
>> include FancyCommand
=> Object
>> c = run("date", verbose: true, accum: $stdout) | "awk '{ print $2 }'"
$ date
Wed Jan  7 08:53:02 CET 2015
$ awk '{ print $2 }'
Jan
=> #<FancyCommand::Command:0x007fc2ad7c5b10 @string="awk '{ print $2 }'", @verbose=true, @accum=#<IO:<STDOUT>>, @in="Wed Jan  7 08:53:02 CET 2015\n", @output="Jan\n", @out="Jan\n", @err="", @status=#<Process::Status: pid 90340 exit 0>, @pid=90340, @must_succeed=false, @output_mutex=#<Mutex:0x007fc2ad7c5570>>
```

## Tests

I am very sorry that there are no tests yet. I am using this in a real
application, but yeah it needs some tests.

## Contributing

1. Fork it ( https://github.com/myobie/fancy_command/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
