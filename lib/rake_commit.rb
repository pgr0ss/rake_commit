module RakeCommit
end

Dir.glob(File.expand_path(File.dirname(__FILE__) + '/rake_commit/*.rb')) do |file|
  require file
end