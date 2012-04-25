require 'optparse'
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
    options = {
      :collapse_commits => true,
      :incremental => false,
      :prompt_exclusions => []
    }

    if File.exists?(".rake_commit")
      defaults = File.read(File.join(Dir.pwd, ".rake_commit"))
      options = parse_options(defaults.split(" "), options)
    end
    options = parse_options(ARGV, options)

    if git_svn?
      GitSvn.new(options[:prompt_exclusions]).commit
    elsif git?
      Git.new(options[:collapse_commits], options[:incremental], options[:prompt_exclusions]).commit
    else
      Svn.new(options[:prompt_exclusions]).commit
    end
  end

  def parse_options(args, options)
    parser = OptionParser.new do |opts|
      opts.banner = "Usage: rake_commit [OPTIONS]"
      opts.on("-h", "--help", "Show this message") do
        puts opts
        exit
      end
      opts.on("-i", "--incremental", "Prompt for a local commit") do
        options[:incremental] = true
      end
      opts.on("-n", "--no-collapse", "Run the build and push without collapsing commits") do
        options[:collapse_commits] = false
      end
      opts.on("-w", "--without-prompt PROMPT", "Skips the given prompt (author, feature, message)") do |prompt_exclusion|
        options[:prompt_exclusions] << prompt_exclusion
      end
    end

    parser.parse(args)
    options
  end
end
