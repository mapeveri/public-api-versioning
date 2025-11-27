class Api::V2::Versions::Version202511270001Users < ApiVersion::Version
  resource :users
  timestamp "2025-11-27"

  payload do |t|
  end

  response do |t|
    t.rename_field :email, :contact_email
  end
end
