class CommitMessage

  attr_reader :pair, :feature, :message

  def initialize(prompt_exclusions = [])
    @pair = PromptLine.new("pair", prompt_exclusions).prompt
    @feature = PromptLine.new("feature", prompt_exclusions).prompt
    @message = PromptLine.new("message", prompt_exclusions).prompt
  end

  def joined_message
    [@pair, @feature, @message].compact.join(' - ')
  end
end
