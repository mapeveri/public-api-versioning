# API Version

A robust Ruby on Rails library for managing API versioning through request and response transformations. It allows you to evolve your API without breaking changes by defining transformations between versions.

## Features

This library supports a wide range of transformations for both **Request Payload** and **Response Body**:

### Field Operations
- **Add Field**: Add new fields with default values or calculated blocks.
- **Remove Field**: Remove fields that are no longer needed.
- **Rename Field**: Rename fields to match new schemas.
- **Change to Mandatory**: Ensure a field exists, providing a default if missing.
- **Transform**: Apply custom logic to modify a field's value based on the entire object.

### Structural Transformations
- **Nest**: Transform flat structures into nested objects.
- **Move Field**: Move fields to any depth within the JSON structure, creating intermediate keys as needed.
- **Split**: Split a single field into multiple fields (e.g., `name` -> `first_name`, `last_name`).
- **Combine**: Combine multiple fields into one (e.g., `first_name`, `last_name` -> `name`).

### Collections
- **Each**: Iterate over arrays and apply transformations to each element.

### Endpoint Management
- **Deprecate Endpoint**: Mark endpoints as deprecated (adds `Warning` header).
- **Remove Endpoint**: Mark endpoints as removed (returns `410 Gone`).

---

## Configuration

### 1. Initializer
Create an initializer (e.g., `config/initializers/api_version.rb`) to configure the current version and version files.

```ruby
# config/initializers/api_version.rb

# Set the current stable version for each API namespace (v1, v2, etc.)
Rails.application.config.x.api_current_versions = {
  "v1" => "2025-11-01", # /api/v1/* uses this as current version
  "v2" => "2025-11-27"  # /api/v2/* uses this as current version
}

# Map versions to their specific transformation classes
# Grouped by API namespace to ensure versions are scoped correctly
Rails.application.config.x.version_files = {
  "v1" => {
    "2025-01-01" => [ "Api::V1::Versions::Version202501010001CombineFirstAndLastNameToNameInUser" ],
    "2025-11-01" => [] # Current version usually has no transformations
  },
  "v2" => {
    "2025-11-27" => []
  }
}
```

**How it works:**
- The system detects the API namespace from the request path (e.g., `/api/v1/users` → `"v1"`)
- Uses the corresponding current version from `api_current_versions`
- Version files are scoped to their API namespace (V1 versions cannot be used in V2 and vice versa)
- If an invalid version is requested via `X-API-Version` header, returns 400 Bad Request

### 2. Controller Setup
Include the `ApiVersion::ApiVersionable` concern in your base API controller.

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  include ApiVersion::ApiVersionable
end
```

---

## Generating Version Files

Use the built-in generator to create new version transformation files:

```bash
# Basic usage (defaults to app/controllers/versions)
rails generate api_version users

# Specify custom path for different API versions
rails generate api_version users --path=app/controllers/api/v1/versions

# This creates a file like:
# app/controllers/api/v1/versions/version202511231845_users.rb
```

The generator will:
- Create a timestamped version file
- Set up the correct namespace based on the path
- Include a basic template for `payload` and `response` blocks

---

## Usage Examples

Define version classes inheriting from `ApiVersion::Version`. Use `payload` blocks to transform incoming requests and `response` blocks to transform outgoing responses.

### Basic Transformations

```ruby
class Api::V1::Versions::Version20250101 < ApiVersion::Version
  resource :users
  timestamp "2025-01-01"

  payload do |t|
    # Incoming request: { "name": "John Doe" }
    # Transformed to: { "first_name": "John", "last_name": "Doe" }
    t.split_field :name, into: [:first_name, :last_name]
  end

  response do |t|
    # Outgoing response: { "first_name": "John", "last_name": "Doe" }
    # Transformed to: { "name": "John Doe" }
    t.combine_fields :first_name, :last_name, into: :name do |first, last|
      "#{first} #{last}".strip
    end

    # Custom transformation with full access to the item
    # Useful for complex calculations or conditional logic
    t.transform(:status) do |item|
      if item[:paid] && item[:shipped]
        "completed"
      elsif item[:paid]
        "processing"
      else
        "pending"
      end
    end
  end
end
```

### Advanced Transformations (Nested, Collections, Move)

```ruby
class Api::V1::Versions::Version20250501 < ApiVersion::Version
  resource :orders
  timestamp "2025-05-01"

  payload do |t|
    # Nested transformation
    # Input:  { "shipping_address": { "zip_code": "12345" } }
    # Output: { "shipping_address": { "postal_code": "12345" } }
    t.nest :shipping_address do |address|
      address.rename_field :zip_code, :postal_code
    end

    # Collection transformation
    # Input:  { "items": [{ "price": 100 }] }
    # Output: { "items": [{ "price": 100, "currency": "USD" }] }
    t.each :items do |item|
      item.add_field :currency, default: "USD"
    end

    # Move field to a nested structure
    # Input:  { "legacy_tracking_id": "TRACK-123" }
    # Output: { "meta": { "tracking": { "id": "TRACK-123" } } }
    t.move_field :legacy_tracking_id, to: [:meta, :tracking, :id]

    # Flatten a nested field (move to root)
    # Input:  { "meta": { "tracking": { "id": "TRACK-123" } } }
    # Output: { "legacy_tracking_id": "TRACK-123" }
    t.move_field [:meta, :tracking, :id], to: :legacy_tracking_id
  end

  response do |t|
    # Nested transformation in response (also works!)
    # Input:  { "user_data": { "old_field": "value" } }
    # Output: { "user_data": { "new_field": "value" } }
    t.nest :user_data do |data|
      data.rename_field :old_field, :new_field
    end
  end
end
```

### Endpoint Management

```ruby
class Api::V1::Versions::Version20250601 < ApiVersion::Version
  resource :products
  timestamp "2025-06-01"

  # Adds "Warning: 299 - Endpoint Deprecated" header
  endpoint_deprecated :products, :index

  # Returns 410 Gone
  endpoint_removed :products, :delete
end
```

---

## Version Validation

The library validates API versions requested via the `X-API-Version` header:

- **Valid version**: Applies transformations for that version
- **Invalid version**: Returns `400 Bad Request` with error message listing available versions
- **No header**: Uses the current version for that API namespace (no transformations)

**Example:**
```bash
# Valid version
curl -H "X-API-Version: 2025-01-01" http://localhost:3000/api/v1/users
# → Returns transformed response

# Invalid version
curl -H "X-API-Version: 9999-99-99" http://localhost:3000/api/v1/users
# → Returns 400 Bad Request with error message

# No header
curl http://localhost:3000/api/v1/users
# → Uses current version (2025-11-01)
```
