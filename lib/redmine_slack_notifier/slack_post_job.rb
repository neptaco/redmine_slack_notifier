require_dependency 'redmine_slack_notifier/slack_service'

module RedmineSlackNotifier
  class SlackPostJob < ActiveJob::Base
    queue_as :slack_notifier

    def slack_service
      @slack_service ||= SlackService.new
    end

    def perform(params)
      to = params[:to]
      payload = params[:payload]

      post_to_slack(to, payload)
    end

    def post_to_slack(to, payload)
      @slack_service = SlackService.new

      if to.is_a?(User)
        im_channel, _ = slack_service.find_im_channel(to)
        if im_channel
          post(im_channel, payload)
        end
      elsif to.present?
        post(to.to_s, payload)
      end

    end

    def post(channel, payload)
      payload[:channel] = channel
      Rails.logger.debug("Post to slack: #{payload.inspect}")
      @slack_service.chat_postMessage(payload)
    rescue StandardError => e
      Rails.logger.warn(e)
    end


  end
end