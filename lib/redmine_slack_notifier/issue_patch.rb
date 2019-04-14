require_dependency 'issue'

module RedmineSlackNotifier
  module IssuePatch # :nodoc:
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        after_create_commit :create_from_issue
      end
    end

    module ClassMethods # :nodoc:
    end

    module InstanceMethods # :nodoc:
      def create_from_issue
        Redmine::Hook.call_hook(
          :slack_notifier_issues_new_after_save,
          issue: self
        )
      end
    end
  end
end

((Rails.version > "5")? ActiveSupport::Reloader : ActionDispatch::Callbacks).to_prepare do
  unless Issue.included_modules.include? RedmineSlackNotifier::IssuePatch
    Issue.send(:include, RedmineSlackNotifier::IssuePatch)
  end
end

