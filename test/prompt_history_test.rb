require File.expand_path(File.dirname(__FILE__) + "/test_helper")

class PromptHistoryTest < Test::Unit::TestCase

  def test_save_will_save_value_to_disk
    File.expects(:open).with(Dir.tmpdir + "/feature.data", "a").yields(file = mock)
    file.expects(:write).with("card 100\n")
    RakeCommit::PromptHistory.new("feature").save("card 100")
  end

  def test_last_will_return_last_saved_value
    File.expects(:exists?).with(Dir.tmpdir + "/feature.data").returns(true)
    File.expects(:read).with(Dir.tmpdir + "/feature.data").returns("card 100\ncard 101\n")
    Readline::HISTORY.expects(:push).with("card 100", "card 101").returns(["card 100", "card 101"])
    assert_equal "card 101", RakeCommit::PromptHistory.new("feature").last
  end

  def test_empty_will_return_true_with_empty_history
    File.expects(:exists?).with(Dir.tmpdir + "/feature.data").returns(false)
    Readline::HISTORY.expects(:push).with(nil).returns([])
    assert_equal true, RakeCommit::PromptHistory.new("feature").empty?
  end

  def test_empty_will_return_false_with_existent_history
    File.expects(:exists?).with(Dir.tmpdir + "/feature.data").returns(true)
    File.expects(:read).with(Dir.tmpdir + "/feature.data").returns("card 100\n")
    Readline::HISTORY.expects(:push).with("card 100").returns(["card 100"])
    assert_equal false, RakeCommit::PromptHistory.new("feature").empty?
  end
end
