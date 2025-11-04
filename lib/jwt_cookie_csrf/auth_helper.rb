# frozen_string_literal: true

module JwtCookieCsrf
  module AuthHelper
    def generate_jwt(payload, expires_in: 3600)
      exp = Time.now.to_i + expires_in
      payload[:exp] = exp
      JWT.encode(payload, JwtCookieCsrf.configuration.jwt_secret, JwtCookieCsrf.configuration.jwt_algorithm)
    end

    def set_auth_cookie(response, jwt_token)
      set_cookie(response, JwtCookieCsrf.configuration.cookie_name, jwt_token, http_only: true, secure: true)
    end

    def set_csrf_cookie(response, csrf_token)
      set_cookie(response, JwtCookieCsrf.configuration.csrf_cookie_name, csrf_token, http_only: false, secure: true)
    end

    private

    def set_cookie(response, name, value, options = {})
      Rack::Utils.set_cookie_header!(response.headers, name, { value: value, path: "/", same_site: :strict }.merge(options))
    end
  end
end