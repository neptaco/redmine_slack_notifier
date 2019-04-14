class CreateSlackProjectPreference < ActiveRecord::Migration[5.1]
  def change
    create_table :slack_project_preferences do |t|
      t.references :project, index: true, unique: true
      t.string :token
      t.string :channel
    end
  end
end