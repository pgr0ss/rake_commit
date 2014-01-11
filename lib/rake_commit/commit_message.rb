module RakeCommit
  class CommitMessage

    attr_reader :author, :feature, :message

    def initialize(prompt_exclusions = [])
      @author = RakeCommit::PromptLine.new("author", prompt_exclusions).prompt
      @feature = RakeCommit::PromptLine.new("feature", prompt_exclusions).prompt
      @message = RakeCommit::PromptLine.new("message", prompt_exclusions).prompt
    end

    def joined_message
      [@author, @feature, @message].compact.join(' - ')
    end
  end
end
