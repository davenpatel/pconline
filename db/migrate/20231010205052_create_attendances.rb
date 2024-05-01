class CreateAttendances < ActiveRecord::Migration[7.1]
  def change
    create_table :attendances do |t|
      t.string :source
      t.string :entity_identifier
      t.datetime :sign_in_time
      t.datetime :sign_out_time
      t.string :site_identifier

      t.timestamps
    end
  end
end
