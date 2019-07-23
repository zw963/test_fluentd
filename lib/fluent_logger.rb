class AppLogger < Ougai::Logger
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

class FluentLoggerDevice
  def initialize(host = 'localhost', port = 24224, opts = {})
    @logger = Fluent::Logger::FluentLogger.new(nil, host: host, port: port)
  end

  def write(data)
    tag = data.delete(:tag)
    time = data.delete(:time)

    unless @logger.post_with_time(tag, data, time)
      p @log.last_error
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

class OTALogger
  include Singleton
  attr_accessor :logger

  def initialize
    logger = AppLogger.new(FluentLoggerDevice.new('152.32.134.198', 24224))
    logger.with_fields = { tag: 'OTA.worker' }
    self.logger = logger
  end

  def self.logger
    instance.logger
  end
end
