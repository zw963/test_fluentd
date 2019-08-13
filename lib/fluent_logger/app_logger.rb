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

module ActiveSupport::TaggedLogging::Formatter
  def call(severity, time, progname, data)
    data = { msg: data.to_s } unless data.is_a?(Hash)
    data[:tags] ||= []
    data[:tags].concat current_tags

    super(severity, time, progname, data)
  end
end

class AppLogger
  include Singleton
  attr_accessor :logger

  def initialize
    if Rails.env.development? || Rails.env.test?
      self.logger = Base.new(STDOUT)
    else
      logger = Base.new(FluentLoggerDevice.new('152.32.134.198', 24224))
      logger.with_fields = { tag: 'app.worker' }
      self.logger = logger

      old_logger = ActiveSupport::Logger.new('log/production.log')
      old_logger.formatter = proc do |severity, datetime, progname, msg|
        ::Logger::Formatter.new.call(severity, datetime, progname, msg.to_json)
      end
      logger.extend ActiveSupport::Logger.broadcast(old_logger)
    end
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
