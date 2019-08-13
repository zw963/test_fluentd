class HardWorker
  include Sidekiq::Worker

  def perform(id)
    http = HTTP.use(instrumentation: { instrumenter: ActiveSupport::Notifications.instrumenter })

    (1..10).map do |i|
      res = http.get "https://www.google.com.hk/search?q=test#{i}"
      return logger.info "Wrong things was happened." if res.code != 200
    end

    logger.warn "Done parse."

    # raise 'failed!'
    post = Post.find(id)
    post.update_column(:res_correct, true)
  end
end
