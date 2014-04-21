class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string :pod
      t.string :error
      t.string :command
      t.string :trigger

      t.timestamps
    end
  end
end
