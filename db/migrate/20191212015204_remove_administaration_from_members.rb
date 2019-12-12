class RemoveAdministarationFromMembers < ActiveRecord::Migration[6.0]
  def change
    rename_column :members, :administration, :administrator
  end
end
