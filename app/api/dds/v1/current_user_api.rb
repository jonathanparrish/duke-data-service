module DDS
  module V1
    class CurrentUserAPI < Grape::API
      desc 'current_user' do
        detail 'allows a user to get their User object with a valid api_token'
        named 'current_user'
        failure [
          [200, "Success"],
          [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"]
        ]
      end
      get '/current_user', root: false do
        authenticate!
        current_user
      end

      desc 'current_user usage' do
        detail 'get data about user projects, files, and storage usage'
        named 'current_user usage'
        failure [
          [200, "Success"],
          [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"]
        ]
      end
      get '/current_user/usage', serializer: UserUsageSerializer do
        authenticate!
        current_user
      end

      desc 'manage current_user api_key' do
        detail 'create or recreate the current_user api_key'
        named 'manage current_user api_key'
        failure [
          [201, "Success"],
          [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"]
        ]
      end
      put '/current_user/api_key', serializer: ApiKeySerializer do
        authenticate!
        Audited.audit_class.as_user(current_user) do
          ApiKey.transaction do
            if current_user.api_key
              current_user.api_key.destroy!
            end
            current_user.build_api_key(key: SecureRandom.hex)
            current_user.save
            annotate_audits [current_user.api_key.audits.last]
          end
        end
        current_user.api_key
      end
    end
  end
end
