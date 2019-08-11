require 'sidekiq'

class ActiveRecordSlowQueryLogger < AppLogger
  def self.logger
    logger = super
    logger.with_fields = {tag: 'active_record.worker'}
    logger
  end
end

ActiveSupport::Notifications.subscribe "sql.active_record" do |name, start_time, finish_time, id, payload|
  duration = (finish_time-start_time)*1000

  # slow than 3 second
  if duration > 3000
    log = {
      name: 'active_record.slow_query',
      start: start_time,
      finish: finish_time,
      cost_time: duration,
      msg: "#{payload[:name]} (#{duration.to_i}ms): #{payload[:sql]}",
      tags: [id]
    }

    ActiveRecordSlowQueryLogger.logger.warn log
  end
end
