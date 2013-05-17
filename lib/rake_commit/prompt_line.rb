require 'readline'
require 'tmpdir'

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
        save(input)
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

    def save(input)
      File.open(path(@attribute), "a") { |f| f.write(input + "\n") }
    end

    private
    def history
      @history ||= Readline::HISTORY.push(*saved_data).to_a
    end

    def previous_input
      @previous_input ||= history.last
    end

    def saved_data
      File.exists?(path(@attribute)) ? File.read(path(@attribute)).split("\n") : []
    end

    def path(attribute)
      File.expand_path(Dir.tmpdir + "/#{attribute}.data")
    end
  end
end
