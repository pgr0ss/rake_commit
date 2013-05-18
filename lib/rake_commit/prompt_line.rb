require 'readline'

module RakeCommit
  class PromptLine

    def initialize(attribute, prompt_exclusions = [])
      @attribute = attribute
      @prompt_exclusions = prompt_exclusions
    end

    def prompt
      return nil if @prompt_exclusions.include?(@attribute)
      input = nil
      loop do
        input = Readline.readline(message).chomp
        break unless (input.empty? && history.empty?)
      end

      unless input.empty?
        history.save(input)
        return input
      end

      puts "using: #{previous_input}"
      return previous_input
    end

    def message
      previous_message = "\n"
      previous_message += "previous #{@attribute}: #{previous_input}\n" unless previous_input.nil?
      puts previous_message
      "#{@attribute}: "
    end

    private
    def history
      @history ||= PromptHistory.new(@attribute)
    end

    def previous_input
      @previous_input ||= history.last
    end
  end
end
