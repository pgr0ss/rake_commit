require 'getoptlong'
require 'rexml/document'

Dir.glob(File.expand_path(File.dirname(__FILE__) + '/*.rb')) do |file|
  require file
end

class Commit
  def git?
    `git symbolic-ref HEAD 2>/dev/null`
    $?.success?
  end

  def git_svn?
    `git svn info 2> /dev/null`
    $?.success?
  end

  def commit
    collapse_commits = true
    incremental = false
    prompt_exclusions = []

    opts = GetoptLong.new(
      [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
      [ '--no-collapse', '-n', GetoptLong::NO_ARGUMENT ],
      [ '--incremental', '-i', GetoptLong::NO_ARGUMENT ],
      [ '--without-prompt', '-w', GetoptLong::REQUIRED_ARGUMENT]
    )
    opts.each do |opt, arg|
      case opt
      when '--help'
        usage
        return
      when '--incremental'
        incremental = true
      when '--no-collapse'
        collapse_commits = false
      when '--without-prompt'
        prompt_exclusions << arg
      end
    end

    if git_svn?
      GitSvn.new(prompt_exclusions).commit
    elsif git?
      Git.new(collapse_commits, incremental, prompt_exclusions).commit
    else
      Svn.new(prompt_exclusions).commit
    end
  end

  def usage
    puts <<-END
Usage: rake_commit [OPTION]

  --help, -h: show help
  --no-collapse, -n: do not collapse merge commits
  --incremental, -i: do not push commit to origin (git only)
    END
  end
end
