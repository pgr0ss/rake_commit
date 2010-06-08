require 'English'

class Shell
  def self.system(cmd, raise_on_failure = true)
    successful = Kernel.system(cmd)
    raise if raise_on_failure && !successful
  end

  def self.backtick(cmd, raise_on_failure = true)
    output = `#{cmd}`
    raise "Command failed: #{cmd.inspect}" if raise_on_failure && !$CHILD_STATUS.success?
    output
  end
end
