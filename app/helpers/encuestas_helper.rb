module EncuestasHelper
  def live_polls
    controller.portal.poll.current
  end
end
