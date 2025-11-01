module ApiTransformations
  module UserTransformations
    def self.transform(user_hash, version)
      case version
      when "2025-11-01"
        user_hash
      when "2024-05-10"
        first_name, last_name = user_hash[:full_name].split(" ", 2)
        user_hash.merge(first_name: first_name, last_name: last_name).except(:full_name)
      else
        user_hash
      end
    end
  end
end
