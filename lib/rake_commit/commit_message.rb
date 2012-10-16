module RakeCommit
  class CommitMessage

    attr_reader :pair, :feature, :message

    def initialize(prompt_exclusions = [])
      @pair = RakeCommit::PromptLine.new("pair", prompt_exclusions).prompt
      @feature = RakeCommit::PromptLine.new("feature", prompt_exclusions).prompt
      @message = RakeCommit::PromptLine.new("message", prompt_exclusions).prompt
    end

    def joined_message
      [@pair, @feature, @message].compact.join(' - ')
    end
  end
end