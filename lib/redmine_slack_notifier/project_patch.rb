require_dependency 'issue'

module RedmineSlackNotifier
  module ProjectPatch # :nodoc:

    extend ActiveSupport::Concern

    included do
      has_one :slack_project_preference, dependent: :destroy
      safe_attributes :slack_project_preference_attributes
      accepts_nested_attributes_for :slack_project_preference

    end

    def slack_channel
      slack_project_preference.try(:channel)
    end

    class_methods do
    end

  end
end

((Rails.version > "5")? ActiveSupport::Reloader : ActionDispatch::Callbacks).to_prepare do
  unless Project.included_modules.include? RedmineSlackNotifier::ProjectPatch
    Project.send(:include, RedmineSlackNotifier::ProjectPatch)
  end
end


