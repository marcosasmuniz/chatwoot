module WppConnects::Sync::Contact
  def sync_old_contact(chat)
    contact = Contact.find_by(phone_number: "+#{chat['id']['user']}" )
    if contact == nil
      contact_id = Contact.insert({
        account_id: @wpp_connect.channel_api.account_id,
        phone_number: "+#{chat['id']['user']}",
        name: "#{chat['contact']['name']}",
        identifier: "#{chat['id']['_serialized']}",
        created_at: DateTime.now,
        updated_at: DateTime.now,
      }).rows.first.first
      contact = Contact.find(contact_id)
    end
    contact
  end
  
  def sync_new_contact(chat)
    contact = Contact.find_by(phone_number: "+#{chat['id']['user']}" )
    if contact == nil
      contact = Contact.create({
        account_id: @wpp_connect.channel_api.account_id,
        phone_number: "+#{chat['id']['user']}",
        name: "#{chat['contact']['name']}",
        identifier: "#{chat['id']['_serialized']}"
      })
    end
    contact
  end
end