module RakeCommit
  class GitSvn
    def initialize(prompt_exclusions = [], precommit = nil)
      @prompt_exclusions = prompt_exclusions
      @precommit = precommit
    end

    def commit
      RakeCommit::Shell.system(@precommit) unless @precommit.nil?
      git = RakeCommit::Git.new
      git.add
      git.status
      git_svn_commit_with_message
      rebase
      RakeCommit::Shell.system "rake"
      dcommit
    end

    def git_svn_commit_with_message
      message = RakeCommit::CommitMessage.new(@prompt_exclusions).joined_message_with_author
      RakeCommit::Shell.system "git commit -m #{message.inspect}"
    end

    def rebase
      RakeCommit::Shell.system "git svn rebase"
    end

    def dcommit
      RakeCommit::Shell.system "git svn dcommit"
    end
  end
end
