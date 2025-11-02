class Api::V1::Versions::Version202501010001CombineFirstAndLastNameToNameInUser < ApiVersion::Version
  resource :users
  timestamp 202501010001

  def change_set
    lambda do |t|
      t.add_field :name, :string
      t.transform :name do |user|
        "#{user[:first_name]} #{user[:last_name]}".strip
      end
      t.remove_field :first_name
      t.remove_field :last_name
    end
  end
end
