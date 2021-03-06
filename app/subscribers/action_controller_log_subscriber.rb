# = ActionControllerLogSubscriber
# Subscribes to the ActionController notifications, and captures the 'Completed 200 OK' log event
# and redirects it to the user via ActionCable
class ActionControllerLogSubscriber < ActiveSupport::LogSubscriber
  def process_action(event)
    payload   = event.payload
    additions = ActionController::Base.log_process_action(payload)

    status = payload[:status]
    if status.nil? && payload[:exception].present?
      status = Rack::Utils.status_code(ActionDispatch::ExceptionWrapper.new({}, payload[:exception]).status_code)
    end
    message = "Completed #{status} #{Rack::Utils::HTTP_STATUS_CODES[status]} in %.0fms" % event.duration
    message << " (#{additions.join(" | ")})" unless additions.blank?

    ActionCable.server.broadcast 'logger_output', type: 'controller', message: message
  end
end
