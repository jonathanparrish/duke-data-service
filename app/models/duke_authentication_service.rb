class DukeAuthenticationService < AuthenticationService
  def get_user_for_access_token(encoded_access_token)
    begin
      access_token = JWT.decode(encoded_access_token, Rails.application.secrets.secret_key_base)[0]
      user_authentication_service = user_authentication_services.find_by(uid: access_token['uid'])
      if user_authentication_service
        user = user_authentication_service.user
        user.current_user_authenticaiton_service = user_authentication_service
        user
      else
        user = User.find_by(username: access_token['uid'])
        unless user
          user = User.new(
            id: SecureRandom.uuid,
            username: access_token['uid'],
            etag: SecureRandom.hex,
            email: access_token['email'],
            display_name: access_token['display_name'],
            first_name: access_token['first_name'],
            last_name: access_token['last_name']
          )
        end
        user_authentication_service = user.user_authentication_services.build(
          uid: access_token['uid'],
          authentication_service: self
        )
        user.current_user_authenticaiton_service = user_authentication_service
        user
      end
    rescue JWT::VerificationError, JWT::DecodeError
      raise InvalidAccessTokenException
    end
  end
end
