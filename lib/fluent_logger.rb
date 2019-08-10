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
    @logger.close
  end
end

module ActiveSupport::TaggedLogging::Formatter
  def call(severity, time, progname, data)
    if Rails.env.production?
      data = { msg: data.to_s } unless data.is_a?(Hash)
      data[:tags] ||= []
      data[:tags].concat current_tags
    end

    super(severity, time, progname, data)
  end
end

class AppLogger
  include Singleton
  attr_accessor :logger

  def initialize
    if Rails.env.development? || Rails.env.test?
      logger = Base.new(STDOUT)
    else
      logger = Base.new(FluentLoggerDevice.new('152.32.134.198', 24224))
    end

    # with_fields is ignored if use STDOUT.
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
    logger = super
    logger.with_fields = {tag: 'sidekiq.worker'}
    logger
  end
end

require 'sidekiq'

Sidekiq::Logging.logger = SidekiqLogger.logger
ActiveSupport::LogSubscriber.colorize_logging = false
# Sidekiq::Logging.logger.level = Logger::WARN

Sidekiq.configure_server do |config|
  # logging with sidekiq context
  Sidekiq::Logging.logger.before_log = lambda do |data|
    ctx = Thread.current[:sidekiq_context]

    break unless ctx

    items = ctx.map {|c| c.split(' ') }.flatten
    data[:sidekiq_context] = items if items.any?

    tid = Sidekiq::Logging.tid

    data[:tags] = ["TID-#{tid}"] unless tid.nil?
    true
  end

  # Replace default error handler
  config.error_handlers.pop
  config.error_handlers << lambda do |ex, ctx_hash|
    Sidekiq::Logging.logger.warn(ex, job: ctx_hash[:job]) # except job_str
  end
end
