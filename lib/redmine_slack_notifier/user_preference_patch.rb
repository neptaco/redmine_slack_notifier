require_dependency 'issue'

module RedmineSlackNotifier
  module UserPreferencePatch # :nodoc:

    extend ActiveSupport::Concern

    included do
      safe_attributes 'slack_notifier_notify'

      def slack_notifier_enabled; others.fetch(:slack_notifier_enabled, true); end
      def slack_notifier_enabled=(value); self[:slack_notifier_enabled]=value end

    end

    class_methods do
    end

  end
end

((Rails.version > "5")? ActiveSupport::Reloader : ActionDispatch::Callbacks).to_prepare do
  unless UserPreference.included_modules.include? RedmineSlackNotifier::UserPreferencePatch
    UserPreference.send(:include, RedmineSlackNotifier::UserPreferencePatch)
  end
end


