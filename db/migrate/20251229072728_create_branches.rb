class CreateBranches < ActiveRecord::Migration[8.0]
  def change
    create_table :branches do |t|
      t.string :code
      t.string :name

      t.timestamps
    end
    add_index :branches, :code, unique: true
  end
end
