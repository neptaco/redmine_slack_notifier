require_dependency 'redmine_slack_notifier/slack_post_job'
require_dependency 'redmine_slack_notifier/slack_service'

module RedmineSlackNotifier
  class Hooks < Redmine::Hook::ViewListener

    include SlackHelper
    include GravatarHelper

    render_on :view_my_account_preferences, partial: 'slack_notifier/preferences'
    render_on :view_projects_form, partial: 'slack_notifier/projects_form'

    def slack_service
      @slack_service ||= SlackService.new
    end

    def share_channel(context)
      pref = SlackProjectPreference.find_by_context(context)
      return pref.channel if pref&.channel.present?

      Setting.plugin_redmine_slack_notifier['channel']
    end

    def slack_notifier_issues_new_after_save(context = {})
      issue = context[:issue]

      post_user = post_user(issue.author)

      channel = share_channel(context)
      if channel.present? && !issue.is_private?
        process(:post_new_issue,channel, post_user, issue)
      end

      users = issue.notified_users | issue.notified_watchers
      users.each do |user|
        next unless notifiable?(user, issue: issue)
        process(:post_new_issue, user, post_user, issue)
      end

    end

    def slack_notifier_journal_new_after_save(context = {})
      issue = context[:issue]
      journal = context[:journal]

      post_user = post_user(journal.user)

      channel = share_channel(context)
      if channel.present? && !journal.private_notes?
        process(:post_edit_issue, channel, post_user, journal)
      end

      users = journal.notified_users | journal.notified_watchers
      users.each do |user|
        next unless notifiable?(user, journal: journal)

        if journal.notes? || journal.visible_details(user).any?
          process(:post_edit_issue, user, post_user, journal)
        end
      end
    end


    private

    def post_user(user)

      slack_user = slack_service.find_user_by_email(user.mail)
      icon_url = slack_user.try(:profile).try(:image_48) ||
                 "https:#{gravatar_url(user.mail, default: 'identicon')}"

      {
        username: user.name,
        icon_url: icon_url,
      }
    end

    def notifiable?(user, context={})
      return false unless user.pref.slack_notifier_enabled
      return false if user.pref.no_self_notified

      true
    end

    def process(action, *args)
      to = args.first
      if to.is_a?(String)
        send(action, *args)
      elsif to.is_a?(User)
        user = to
        initial_user = User.current
        initial_language = ::I18n.locale
        begin
          User.current = user

          lang = find_language(user.language) if user.logged?
          lang ||= Setting.default_language
          set_language_if_valid(lang)

          send(action, *args)
        ensure
          User.current = initial_user
          ::I18n.locale = initial_language
        end

      else
        raise ArgumentError, "First argument has to be a user or channel, was #{to.inspect}"
      end
    end

    def post_new_issue(to, post_user, issue)
      msg = <<~MSG
        #{l(:notice_issue_successful_create, id: "##{issue.id}")}
        #{issue_title_link(issue)}
      MSG

      fields = [
        make_field('field_tracker', issue.tracker || '-'),
        make_field('field_assigned_to', issue.assigned_to || '-'),
        make_field('field_priority', issue.priority || '-')
      ]

      attachment = make_attachment(
        fields: fields,
        ts: issue.updated_on.to_i
      )
      attachment[:text] = escape(issue.description) if issue.description

      payload = post_user.merge(
        text: msg,
        attachments: [attachment]
      )

      SlackPostJob.perform_later(
        to: to, payload: payload
      )
    end

    def post_edit_issue(to, post_user, journal)
      issue = journal.issue
      msg = <<~MSG
        #{issue_title_link(issue)}
      MSG

      body = journal.notes ? "#{journal.notes}\n\n" : ''
      body << journal.visible_details.map do |d|
        "• #{detail_text(d)}"
      end.join("\n")

      attachment = make_attachment(
        text: body,
        ts: journal.created_on.to_i,
      )

      payload = post_user.merge(
        text: msg,
        attachments: [attachment]
      )
      SlackPostJob.perform_later(
        to: to, payload: payload
      )
    end


    # Default URL options for generating URLs in emails based on host_name and protocol
    # defined in application settings.
    def self.default_url_options
      options = {protocol: Setting.protocol}
      if Setting.host_name.to_s =~ /\A(https?\:\/\/)?(.+?)(\:(\d+))?(\/.+)?\z/i
        host, port, prefix = $2, $4, $5
        options.merge!(
          host: host, port: port, script_name: prefix
        )
      else
        options[:host] = Setting.host_name
      end
      options
    end

  end
end

