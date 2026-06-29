class AddUrgentToContactSubmissions < ActiveRecord::Migration[7.2]
  def change
    add_column :contact_submissions, :urgent, :boolean, default: false, null: false
  end
end
