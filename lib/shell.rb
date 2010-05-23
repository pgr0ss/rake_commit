class Shell
  def self.system(cmd)
    Kernel.system(cmd) or raise
  end

  def self.backtick(cmd)
    output = `#{cmd}`
    raise "Command failed: #{cmd.inspect}" unless $?.success?
    output
  end
end
