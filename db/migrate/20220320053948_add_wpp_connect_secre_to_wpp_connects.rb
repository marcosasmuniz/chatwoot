class AddWppConnectSecreToWppConnects < ActiveRecord::Migration[6.1]
  def change
    add_column :wpp_connects, :status_connection, :string, default: 'disconnected', null: false
    add_column :wpp_connects, :wppconnect_secret, :string, default: '', null: false
  end
end
