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
      input = nil
      loop do
        input = readline(message).chomp
        break unless (input.empty? && !previous_input)
      end

      unless input.empty?
        save_history(input)
        return input
      end

      puts "using: #{previous_input}"
      return previous_input
    end

    def message
      previous_message = "\n"
      previous_message += "previous #{@attribute}: #{previous_input}\n" if previous_input
      puts previous_message
      "#{@attribute}: "
    end

    def save_history(input)
      File.open(history_file, "w") { |f| f.puts(history.push(input)) }
    end

    private
    def previous_input
      @previous_input ||= history.last
    end

    def history
      @history ||= load_history
    end

    def load_history
      HISTORY.clear
      HISTORY.push(*File.read(history_file).split("\n")) if File.exists?(history_file)
      HISTORY.to_a
    end

    def history_file
      @history_file ||= File.expand_path(Dir.tmpdir + "/#{@attribute}.data")
    end

  end
end
