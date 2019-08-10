# subscribe httprb request event.

# Following subscribe have a fixed block paramater format defined by
# ActiveSupport::Notifications.

if defined? AppLogger
  class HTTPLogger < AppLogger
    def self.logger
      logger = super
      logger.with_fields = {tag: 'http.worker'}
      logger
    end
  end

  def text_request_body?(content_type)
    if content_type.is_a? String
      if content_type.start_with?("application/") or content_type.start_with?("text/")
        true
      end
    end
  end

  ActiveSupport::Notifications.subscribe('start_request.http') do |name, start_time, finish_time, tag, request|
    req = request.dig(:request)
    verb = req.verb.upcase.to_s

    log = {
      name: 'start_request.http',
      start: start_time,
      finish: finish_time,
      cost_time: finish_time - start_time,
      msg: "#{verb} #{req.uri}",
      tags: [tag],
      headers: req.headers.to_h.to_json
    }

    if verb == 'POST' and text_request_body?(req.headers.to_h.dig('Content-Type'))
      log.update(body: req.body.source)
    end

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
end
