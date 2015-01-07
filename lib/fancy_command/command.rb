require 'thread'
require 'open3'

module FancyCommand
  class Command
    class Failed < StandardError
      attr_reader :command, :status, :output

      def initialize(command:, status:, output:)
        @command = command
        @status = status
        @output = output
        super("'#{command}' failed with status #{status} and output:\n#{output}")
      end
    end

    attr_reader :string, :accum, :in, :out, :err, :output, :status, :pid

    def initialize(string, must_succeed: false, **opts)
      @string = string
      @verbose = opts.fetch(:verbose, false)
      @accum = opts.fetch(:accum) { [] }
      @in = opts[:in]
      @output = ""
      @out = nil
      @err = nil
      @status = nil
      @pid = nil
      @must_succeed = must_succeed
      @output_mutex = Mutex.new

      if block_given?
        append_in yield
      end
    end

    def append_in(string)
      @in ||= ""
      @in << string
      self
    end

    def must_succeed?
      !!@must_succeed
    end

    def verbose?
      !!@verbose || ENV["VERBOSE"]
    end

    def call
      puts "$ #{string}" if verbose?

      @in.freeze

      Open3.popen3(string) do |i, o, e, t|
        unless @in.nil?
          i.print @in
          i.close
        end

        @out, @err = [o, e].map do |stream|
          Thread.new do
            lines = []
            until (line = stream.gets).nil? do
              lines << line
              @output_mutex.synchronize do
                @accum << line
                @output << line
              end
            end
            lines.join
          end
        end.map(&:value)

        @pid = t.pid
        @status = t.value
      end

      [@out, @err, @output].each(&:freeze)

      if must_succeed? && !success?
        raise Failed, command: string, status: status.exitstatus, output: output
      end

      self
    end

    def success?
      status.success?
    end

    def exitstatus
      status.exitstatus
    end

    def then(&blk)
      if blk.arity == 1
        blk.call(self)
      else
        blk.call
      end

      self
    end

    def if_success_then(&blk)
      if success?
        if blk.arity == 1
          blk.call(self)
        else
          blk.call
        end
      end

      self
    end

    def unless_success_then(&blk)
      unless success?
        if blk.arity == 1
          blk.call(self)
        else
          blk.call
        end
      end

      self
    end

    def pipe(command_or_string)
      command = if String === command_or_string
        self.class.new(command_or_string, accum: accum, verbose: verbose?)
      else
        command_or_string
      end

      command.append_in(output).()
    end

    alias_method :|, :pipe
  end
end
