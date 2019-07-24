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

ActiveSupport::Notifications.subscribe('start_request.http') do |name, start_time, finish_time, tag, request|
  req = request.dig(:request)

  log = {
    name: 'start_request.http',
    start: start_time,
    finish: finish_time,
    cost_time: finish_time - start_time,
    msg: "#{req.verb.upcase} #{req.uri}",
    tags: [tag],
    headers: req.headers.to_h.to_json
  }

  HTTPLogger.logger.info(log)
end

ActiveSupport::Notifications.subscribe('request.http') do |name, start_time, finish_time, tag, response|
  res = response.dig(:response)
  code = res.code

  log = {
    name: 'done_request.http',
    start: start_time,
    finish: finish_time,
    cost_time: finish_time - start_time,
    msg: res.uri.to_s,
    tags: [tag],
    headers: res.headers.to_h.to_json
  }

  if code != 200
    log.update(status_code: code, reason: res.reason, body: res.body.to_s)
    level = 'warn'
  else
    level = 'info'
  end

  HTTPLogger.logger.send(level, log)
end
