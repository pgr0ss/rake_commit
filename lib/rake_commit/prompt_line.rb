require 'readline'
require 'tmpdir'

module RakeCommit
  class PromptLine
    include Readline

    def initialize(attribute, prompt_exclusions = [], default_value = nil)
      @attribute = attribute
      @prompt_exclusions = prompt_exclusions
      @default_value = default_value
    end

    def prompt
      return nil if @prompt_exclusions.include?(@attribute)

      puts "\n"
      puts "previous #{@attribute}: #{previous_input}" if previous_input

      set_readline_default_input(@default_value) if @default_value
      set_readline_history

      input = nil
      loop do
        input = readline("#{@attribute}: ").chomp
        break unless (input.empty? && !previous_input)
      end

      unless input.empty?
        append_history(input)
        return input
      end

      puts "using: #{previous_input}"
      return previous_input
    end

    private

    def append_history(input)
      File.open(history_file, "a") { |f| f.puts(input) }
    end

    def set_readline_default_input(default_input)
      Readline.pre_input_hook = lambda do
        Readline.insert_text(default_input)
        Readline.redisplay
        Readline.pre_input_hook = nil
      end
    end

    def previous_input
      @previous_input ||= history.last
    end

    def history
      @history ||= load_history
    end

    def set_readline_history
      HISTORY.pop until HISTORY.empty?
      HISTORY.push(*history)
    end

    def load_history
      File.exists?(history_file) ? File.read(history_file).split("\n") : []
    end

    def history_file
      @history_file ||= File.expand_path(Dir.tmpdir + "/#{@attribute}.data")
    end

  end
end
