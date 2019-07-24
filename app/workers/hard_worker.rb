class HardWorker
  include Sidekiq::Worker

  def perform(id)
    (1..10).map do |i|
      res = HTTP.get "https://www.google.com.hk/search?q=test#{i}"
      return logger.info "Wrong things was happened." if res.code != 200
    end

    logger.info "Done parse."

    # raise 'failed!'
    post = Post.find(id)
    post.update_column(:res_correct, true)
  end
end
