class FluentLoggerDevice
  def initialize(host, port)
    @logger = Fluent::Logger::FluentLogger.new(nil, host: host, port: port)
  end

  def write(data)
    data = { msg: data.to_s } unless data.is_a?(Hash)
    tag = data.delete(:tag) || 'default_tag'
    time = data.delete(:time) || Time.now

    unless @logger.post_with_time(tag, data, time)
      p @logger.last_error
    end
  end

  def close
    @log.close
  end
end

module ActiveSupport::TaggedLogging::Formatter
  def call(severity, time, progname, data)
    data = { msg: data.to_s } unless data.is_a?(Hash)
    data[:tags] = current_tags

    super(severity, time, progname, data)
  end
end

class AppLogger
  include Singleton
  attr_accessor :logger

  def initialize
    logger = Base.new(FluentLoggerDevice.new('152.32.134.198', 24224))
    logger.with_fields = { tag: 'app.worker' }
    self.logger = logger
  end

  def self.logger
    ActiveSupport::TaggedLogging.new(instance.logger)
  end

  class Base < Ougai::Logger
    include ActiveSupport::LoggerThreadSafeLevel
    include LoggerSilence

    def initialize(*args)
      super
      after_initialize if respond_to? :after_initialize
    end

    def create_formatter
      if Rails.env.development? || Rails.env.test?
        Ougai::Formatters::Readable.new
      else
        logger_formatter = Ougai::Formatters::Bunyan.new
        logger_formatter.jsonize = false
        logger_formatter
      end
    end
  end
end

class SidekiqLogger < AppLogger
  def self.logger
    super.with_fields = {tag: 'sidekiq.worker'}
  end
end

require 'sidekiq'

Sidekiq::Logging.logger = SidekiqLogger.logger

Sidekiq.configure_server do |config|
  # logging with sidekiq context
  Sidekiq::Logging.logger.before_log = lambda do |data|
    ctx = Thread.current[:sidekiq_context]
    break unless ctx
    items = ctx.map {|c| c.split(' ') }.flatten
    data[:sidekiq_context] = items if items.any?
  end

  # Replace default error handler
  config.error_handlers.pop
  config.error_handlers << lambda do |ex, ctx|
    Sidekiq::Logging.logger.warn(ex, job: ctx[:job]) # except job_str
  end
end
