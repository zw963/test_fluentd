class AppLogger < Ougai::Logger
  include ActiveSupport::LoggerThreadSafeLevel
  include LoggerSilence

  def initialize(host = 'localhost', port = 24224, opts = {})
    super
    after_initialize if respond_to? :after_initialize
    # @log = Fluent::Logger::FluentLogger.new(nil, host: host, port: port)
    # @tag_field = :tag
    # @time_field = :time
  end

  def create_formatter
    if Rails.env.development? || Rails.env.test?
      Ougai::Formatters::Readable.new
    else
      Ougai::Formatters::Bunyan.new
    end
  end

  # def write(data)
  #   tag = data.delete(:tag)
  #   time = data.delete(:tie)

  #   unless @log.post_with_time(tag, data, time)
  #     p @log.last_error
  #   end
  # end

  # def close
  #   @log.close
  # end
end

module ActiveSupport::TaggedLogging::Formatter
  def call(severity, time, progname, data)
    data = { msg: data.to_s } unless data.is_a?(Hash)
    data[:tags] = current_tags

    super(severity, time, progname, data)
  end
end
