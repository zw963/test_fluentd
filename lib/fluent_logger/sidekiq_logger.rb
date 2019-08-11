require 'sidekiq'

class SidekiqLogger < AppLogger
  def self.logger
    logger = super
    logger.with_fields = {tag: 'sidekiq.worker'}
    logger
  end
end

Sidekiq::Logging.logger = SidekiqLogger.logger
ActiveSupport::LogSubscriber.colorize_logging = false
# Sidekiq::Logging.logger.level = Logger::WARN

Sidekiq.configure_server do |config|
  # logging with sidekiq context
  Sidekiq::Logging.logger.before_log = lambda do |data|
    ctx = Thread.current[:sidekiq_context]

    break unless ctx

    items = ctx.map {|c| c.split(' ') }.flatten
    # data[:sidekiq_context] = items if items.any?

    tid = Sidekiq::Logging.tid
    data[:tags] = ["TID-#{tid}"] unless tid.nil?

    name, jid = items if items.any?
    data[:name] = "sidekiq (#{name})" unless name.nil?
    data[:jid] = jid unless jid.nil?
    true
  end

  # Replace default error handler
  config.error_handlers.pop
  config.error_handlers << lambda do |ex, ctx_hash|
    Sidekiq::Logging.logger.warn(ex, job: ctx_hash[:job]) # except job_str
  end
end
