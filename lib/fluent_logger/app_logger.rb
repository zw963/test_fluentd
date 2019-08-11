require_relative './tagged_logging_json'

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
    ActiveSupport::TaggedLoggingJSON.new(instance.logger)
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
