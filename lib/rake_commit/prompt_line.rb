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
        break unless (input.empty? && saved_data.empty?)
      end

      unless input.empty?
        save(input)
        return input
      end

      puts "using: #{saved_data}"
      return saved_data
    end

    def message
      previous = saved_data
      previous_message = "\n"
      previous_message += "previous #{@attribute}: #{previous}\n" unless previous.empty?
      puts previous_message
      "#{@attribute}: "
    end

    def save(input)
      File.open(path(@attribute), "w") {|f| f.write(input) }
    end

    private
    def saved_data
      @saved_data ||= File.exists?(path(@attribute)) ? File.read(path(@attribute)) : ""
    end

    def path(attribute)
      File.expand_path(Dir.tmpdir + "/#{attribute}.data")
    end

  end
end
