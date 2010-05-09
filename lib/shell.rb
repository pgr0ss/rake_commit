class Shell
  def self.system(cmd)
    Kernel.system(cmd) or raise
  end

  def self.backtick(cmd)
    output = `#{cmd}`
    raise unless $?.success?
    output
  end
end
