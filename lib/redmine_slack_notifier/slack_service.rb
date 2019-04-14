module RedmineSlackNotifier
  class SlackService

    CACHE_PREFIX = 'RedmineSlackNotifier::SlackService'

    attr_reader :client

    def initialize(context={})
      @slack_service = Slack::Web::Client.new(token: api_token)
    end

    def method_missing(method, *args)
      @slack_service.send(method, *args)
    end

    def fetch_cache(key, &block)
      Rails.cache.fetch("#{CACHE_PREFIX}/#{key}", expires_in: 15.minutes) do
        block.call
      end
    end

    def api_token
      @api_token ||= Setting.plugin_redmine_slack_notifier['token'].presence || ENV['SLACK_API_TOKEN']
    end

    def find_user_by_email(email)
      fetch_cache("users_lookupByEmail/#{email}") do
        result = @slack_service.users_lookupByEmail(email: email)
        result.user
      end
    rescue Slack::Web::Api::Errors::SlackError => e
      Rails.logger.warn("lookup slack user error: #{e.to_s}  mail:#{email}")
      nil
    end

    def find_im_channel(user)
      user = find_user_by_email(user.mail)
      return nil unless user

      im = fetch_cache("im_open/#{user.id}") do
        @slack_service.im_open(user: user.id)
      end
      return im.channel.id, user
    end

  end
end
