require 'readline'
require 'tmpdir'

module RakeCommit
  class PromptLine
    include Readline

    def initialize(attribute, prompt_exclusions = [])
      @attribute = attribute
      @prompt_exclusions = prompt_exclusions
    end

    def prompt
      return nil if @prompt_exclusions.include?(@attribute)

      puts "\n"
      puts "previous #{@attribute}: #{previous_input}" if previous_input

      input = nil
      loop do
        input = readline("#{@attribute}: ").chomp
        break unless (input.empty? && !previous_input)
      end

      unless input.empty?
        save_history(input)
        return input
      end

      puts "using: #{previous_input}"
      return previous_input
    end


    def save_history(input)
      File.open(history_file, "a") { |f| f.puts(input) }
    end

    private
    def previous_input
      @previous_input ||= history.last
    end

    def history
      @history ||= load_history
    end

    def load_history
      HISTORY.pop until HISTORY.empty?
      HISTORY.push(*saved_history)
      HISTORY.to_a
    end

    def saved_history
      File.exists?(history_file) ? File.read(history_file).split("\n") : []
    end

    def history_file
      @history_file ||= File.expand_path(Dir.tmpdir + "/#{@attribute}.data")
    end

  end
end
