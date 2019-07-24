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

ActiveSupport::Notifications.subscribe('start_request.http') do |name, start_time, finish_time, id, request|
  req = request.dig(:request)

  payload = {headers: req.headers, request_verb: req.verb}

  HTTPLogger.logger.info(
    name: 'start_request.http',
    start: start_time,
    finish: finish_time,
    cost_time: finish_time - start_time,
    msg: req.uri.to_s,
    id: id,
    payload: payload
  )
end

ActiveSupport::Notifications.subscribe('request.http') do |name, start_time, finish_time, id, response|
  res = response.dig(:response)
  code = res.code

  payload = {headers: res.headers, status_code: code, reason: res.reason}

  if code != 200
    payload.update(body: res.body.to_s)
  end

  HTTPLogger.logger.info(
    name: 'done_request.http',
    start: start_time,
    finish: finish_time,
    cost_time: finish_time - start_time,
    msg: res.uri.to_s,
    id: id,
    payload: payload
  )
end
