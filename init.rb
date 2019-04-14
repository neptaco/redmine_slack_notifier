require 'redmine'

require_dependency 'redmine_slack_notifier/hooks'
require_dependency 'redmine_slack_notifier/issue_patch'
require_dependency 'redmine_slack_notifier/journal_patch'
require_dependency 'redmine_slack_notifier/project_patch'
require_dependency 'redmine_slack_notifier/user_preference_patch'

Redmine::Plugin.register :redmine_slack_notifier do
  name 'Redmine Slack Notifier plugin'
  author 'neptaco'
  description 'notify to slack'
  version '0.0.1'
  url 'https://github.com/neptaco/redmine_slack_notifier'
  author_url 'https://github.com/neptaco'

  settings \
    default: {
      channel: nil,
      token: nil,
    },
    partial: 'settings/slack_notifier_settings'

end

