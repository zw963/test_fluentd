# subscribe httprb request event.

# Following subscribe have a fixed block paramater format defined by
# ActiveSupport::Notifications.

class HTTPLogger < AppLogger
  def self.logger
    logger = super
    logger.with_fields = {tag: 'http.worker'}
    logger
  end
end

ActiveSupport::Notifications.subscribe('start_request.http') do |name, start, finish, id, request|
  HTTPLogger.logger.info(name: name, start: start, finish: finish, id: id, payload: request)
end

ActiveSupport::Notifications.subscribe('done_request.http') do |name, start, finish, id, response|
  HTTPLogger.logger.info(name: name, start: start, finish: finish, id: id, payload: response)
end
