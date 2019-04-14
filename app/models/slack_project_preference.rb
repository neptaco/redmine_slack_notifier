class SlackProjectPreference < ActiveRecord::Base

  belongs_to :project

  def self.find_by_context(context)
    project_id = nil
    project_id = context[:issue].project.id if context[:issue]
    project_id = context[:journal].project.id if context[:journal]

    if project_id
      find_by(project_id: project_id)
    end

  end
end
