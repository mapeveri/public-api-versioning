class Api::V1::Versions::Version202501010001CombineFirstAndLastNameToNameInUser < ApiVersion::Version
  resource :users
  timestamp 202501010001

  payload do |t|
    t.split_field :name, into: [ :first_name, :last_name ]
  end

  response do |t|
    t.combine_fields :first_name, :last_name, into: :name do |first, last|
      "#{first} #{last}".strip
    end
  end
end
