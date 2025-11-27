class Api::V2::Versions::Version202501010001Users < ApiVersion::Version
  resource :users
  timestamp "2025-01-01"

  payload do |t|
  end

  response do |t|
    t.rename_field :email, :contact_email
  end
end
