require 'word_wrap'

module RakeCommit
  class CommitMessage
    module MessageType
      MESSAGE = "message"
      WHAT_AND_WHY = "whatwhy"
    end

    SUBJECT_MAX_LENGTH = 50

    attr_reader :author, :feature, :message

    def initialize(prompt_exclusions = [], type = MessageType::MESSAGE)
      @author = RakeCommit::PromptLine.new("author", prompt_exclusions).prompt
      @feature = RakeCommit::PromptLine.new("feature", prompt_exclusions).prompt
      @message = case type
        when MessageType::MESSAGE
          RakeCommit::PromptLine.new("message", prompt_exclusions).prompt
        when MessageType::WHAT_AND_WHY
          what = RakeCommit::PromptLine.new("what", prompt_exclusions).prompt
          why = RakeCommit::PromptLine.new("why", prompt_exclusions).prompt

          subject_space_remaining = SUBJECT_MAX_LENGTH - @feature.length
          truncated_what = what[0...subject_space_remaining]
          subject = RakeCommit::PromptLine.new("subject", prompt_exclusions, truncated_what).prompt

          create_message_with_subject_what_and_why(subject, what, why)
        end
    end

    def joined_message(wrap = nil)
      message = [@feature, @message].compact.join(' - ')
      message = WordWrap.ww(message, wrap) if wrap
      message
    end

    def joined_message_with_author(wrap = nil)
      message = [@author, @feature, @message].compact.join(' - ')
      message = WordWrap.ww(message, wrap) if wrap
      message
    end

    private

    def create_message_with_subject_what_and_why(subject, what, why)
      <<-EOS
#{subject}

What
===
#{what}

Why
===
#{why}
EOS
    end
  end
end
