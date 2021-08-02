# Kc::Auth

## Overview

Ruby gem to provide easy integration of inter-service communication between various xfers services (Rails, Kyc service, keycloak, etc).

There are two parts to the gem:
- Auth: Module to handle the incoming requests from other services
- Client: Module to make requests to other services protected by keycloak.

Keycloak will have an `Internal Services` realm which will manage the api keys of various service clients (xfers core services).

It will assign the appropriate scope/role to each service which will provide the necessary access control. All admins will be present in this realm with only `Sign in with google` option to login to the various admin dashboards.
## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kc-auth', git: 'https://github.com/chingjubb/kc-auth.git'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install kc-auth

## Usage
### 1.1 Auth Module

- Configuration

    ```
    • → Mandatory
    * → Optional
    ```

    - `• auth_server_url`: Auth server host
    - `• realm_ids`: Realms to validate requests from
    - `• context_key`: The name of the variable where the `Context` object will be placed in the request
    - `* skip_paths`: List of paths which needs to be skipped from validation
    - `* post_validation`: Block to perform additional validations or add additional context attributes.

        ```ruby
        Kc::Auth.post_validation { |context|
          user = IdentityUser.find_by(kc_id: context.kc_id).user
        	if !user throw UserNotFoundError
          context.set_attr("user_id",  user.id)
          context.set_attr("user",  user)
        	context.set_attr("merchant",  user&.merchant)
        }
        # Note: The attributes set are immutable and
        # hence will not update any attrs that are already defined

        # use `props` to store mutable information on the context object
        # https://www.notion.so/xfers/KC-Auth-Gem-38e219e8fa88415e93cab60e1b852e7b#e49acab09e34437f8475c5a51f4a78a0
        ```

    - `* authorization`: Boolean flag to enable or disable policy based authorization
        - `* additional_attributes`: Block to pass additional attributes/parameters when using policy based authorization.

            ```ruby
            Kc::Auth.additional_attributes { |context|
            	{
            		current_user_limit: User.find(context.user_id).transaction_limit
              }
            }
            ```

    - `* token_expiration_tolerance_in_seconds`: Buffer period to allow tokens past their expiry time. Default = 5 mins
    - `* public_key_cache_ttl`: Cache expiry of the public key being used to validate the tokens. Default = 1 day
    - `* logger`: The logger object to be used for logging. Default = Rails.logger
    - `* log_attributes`: The list of Context attributes that needs to be logged

        ```ruby
        log_attributes = {
        	user_id: "user_id",
        	merchant_id: "user.merchant.id",
        }

        # Use dot notation to access attributes of context objects
        ```

- Context object

    An env object available on every request which will hold information about the user/client making the request. The available attributes and methods are:

    - Attributes
        - `raw_token` - The raw JWT token sent as part of the header.
        - `token` - The parsed token saved as a hash to fetch specific properties.

            The parsed token will have the standard claims as https://tools.ietf.org/html/rfc7519#section-4.1
            along with the additional claims set by each service.

        - `attributes` - All the attributes of the token + attributes set in the context during the configuration phase (Immutable)
        - `props` - Mutable properties that needs to be saved in the context object.
    - Methods
        - `set_attr` - Method to set immutable data attributes on the context object. This is mostly used at the initial level

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).


