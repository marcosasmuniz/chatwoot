class CreateWppConnects < ActiveRecord::Migration[6.1]
  def change
    create_table :wpp_connects do |t|
      t.string :name, null: false, default: ""
      t.string :status, null: false, default: "active"
      t.jsonb :status_sync, null: false, default: {}
      t.string :wppconnect_session, null: false
      t.string :wppconnect_token, null: false
      t.string :wppconnect_endpoint, null: false
      t.integer :channel_api_id, null: false
      t.timestamps
    end
  end
end
