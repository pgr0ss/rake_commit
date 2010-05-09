class GitSvn
  def commit
    git = Git.new
    git.add
    git.status
    git_svn_commit_with_message
    rebase
    Shell.system "rake"
    if ok_to_check_in?
      dcommit
    end
  end

  def git_svn_commit_with_message
    commit_message = CommitMessage.new
    message = "#{commit_message.pair} - #{commit_message.feature} - #{commit_message.message}"
    Shell.system "git commit -m #{message.inspect}"
  end

  def rebase
    Shell.system "git svn rebase"
  end

  def dcommit
    Shell.system "git svn dcommit"
  end
end
