class CreateConnections < ActiveRecord::Migration[7.0]
  def change
    create_table :connections do |t|
      t.string :name, null: false, default: ""
      t.string :status, null: false, default: "active"
      t.string :wppconnect_session, null: false
      t.string :wppconnect_token, null: false
      t.string :wppconnect_endpoint, null: false
      t.integer :chatwoot_inbox_id, null: false
      t.integer :chatwoot_account_id, null: false
      t.string :chatwoot_account_token, null: false
      t.string :chatwoot_endpoint, null: false

      t.timestamps
    end
  end
end
