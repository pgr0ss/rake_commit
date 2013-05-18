require 'readline'
require 'tmpdir'

module RakeCommit
  class PromptHistory

    def initialize(attribute)
      @attribute = attribute
    end

    def save(input)
      File.open(save_path, "a") { |f| f.write(input + "\n") }
    end

    def previous_input
      history.last
    end

    private
    def history
      @history ||= Readline::HISTORY.push(*saved_data).to_a
    end

    def saved_data
      File.exists?(save_path) ? File.read(save_path).split("\n") : []
    end

    def save_path
      @save_path ||= File.expand_path(Dir.tmpdir + "/#{@attribute}.data")
    end
  end
end
