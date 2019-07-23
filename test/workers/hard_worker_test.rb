require 'test_helper'

class HardWorkerTest < MiniTest::Unit::TestCase
  def test_example
    post = Post.create(name: 'name', content: 'content')
    assert_equal false, post.res_correct
    HardWorker.perform_async(post.id)
    assert_equal true, post.reload.res_correct
  end
end
