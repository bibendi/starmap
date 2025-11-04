class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      # Devise fields
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip
      t.boolean  :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email

      # LDAP fields
      t.string :ldap_dn
      t.string :ldap_uid
      t.text   :ldap_data

      # Application fields
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :display_name
      t.string :employee_id
      t.string :department
      t.string :position
      t.string :phone
      t.string :avatar_url

      # Role-based access control
      t.string :role, null: false, default: 'engineer'
      t.integer :team_id  # Will add foreign key constraint later

      # Status and flags
      t.boolean :active, default: true
      t.boolean :admin, default: false
      t.datetime :last_ldap_sync_at

      t.timestamps
    end

    # Indexes for performance
    add_index :users, :email, unique: true
    add_index :users, :ldap_uid, unique: true
    add_index :users, :ldap_dn
    add_index :users, :role
    add_index :users, :team_id
    add_index :users, :active
  end
end
