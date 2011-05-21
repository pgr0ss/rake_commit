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
      when '--no-collapse'
        collapse_commits = false
      when '--incremental'
        incremental = true
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


def ok_to_check_in?
  return true unless self.class.const_defined?(:CCRB_RSS)
  cruise_status = CruiseStatus.new(CCRB_RSS)
  cruise_status.pass? ? true : are_you_sure?( "Build FAILURES: #{cruise_status.failures.join(', ')}" )
end

def are_you_sure?(message)
  puts "\n", message
  input = ""
  while (input.strip.empty?)
    input = Readline.readline("Are you sure you want to check in? (y/n): ")
  end
  return input.strip.downcase[0,1] == "y"
end
