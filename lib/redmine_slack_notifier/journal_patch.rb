require_dependency 'journal'

module RedmineSlackNotifier
  module JournalPatch  # :nodoc:
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        after_create_commit :create_from_journal
      end
    end

    module ClassMethods # :nodoc:
    end

    module InstanceMethods # :nodoc:
      def create_from_journal
        Redmine::Hook.call_hook(
          :slack_notifier_journal_new_after_save,
          issue: self.issue, journal: self
        )
      end
    end
  end
end

((Rails.version > "5")? ActiveSupport::Reloader : ActionDispatch::Callbacks).to_prepare do
  unless Journal.included_modules.include? RedmineSlackNotifier::JournalPatch
    Journal.send(:include, RedmineSlackNotifier::JournalPatch)
  end
end