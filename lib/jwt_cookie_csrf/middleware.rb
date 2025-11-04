# frozen_string_literal: true
require 'rack/utils'

module JwtCookieCsrf
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)

      if excluded_path?(request.path) || safe_method?(request.request_method)
        response = @app.call(env)
        ensure_csrf_cookie(request, response)
        return response
      end

      jwt_token = request.cookies[JwtCookieCsrf.configuration.cookie_name]
      unless jwt_token && valid_jwt?(jwt_token)
        return unauthorized_response
      end

      csrf_cookie = request.cookies[JwtCookieCsrf.configuration.csrf_cookie_name]
      csrf_header = request.env['HTTP_X_CSRF_TOKEN']


      puts "\n--- [DEBUG] NEW CALL TO /protected ---"
      puts "[DEBUG] Cookie (raw): #{csrf_cookie.inspect}"
      puts "[DEBUG] Header (raw): #{csrf_header.inspect}"

      if csrf_cookie && csrf_header
        cookie_to_compare = csrf_cookie.strip
        header_to_compare = csrf_header.strip

        puts "[DEBUG] Encoding Cookie: #{cookie_to_compare.encoding.name}"
        puts "[DEBUG] Encoding Header: #{header_to_compare.encoding.name}"

        is_match = Rack::Utils.secure_compare(cookie_to_compare, header_to_compare)
        puts "[DEBUG] Result secure_compare: #{is_match}"

        unless is_match
          return forbidden_response("CSRF token mismatch")
        end
      else
        puts "[DEBUG] One of cookies are nil (cookie: #{csrf_cookie.nil?}, header: #{csrf_header.nil?})"
        return forbidden_response("CSRF token mismatch")
      end

      response = @app.call(env)
      rotate_csrf_cookie(response)
      response
    end

    private

    def excluded_path?(path)
      JwtCookieCsrf.configuration.excluded_paths.include?(path)
    end

    def safe_method?(method)
      %w[GET HEAD OPTIONS TRACE].include?(method)
    end

    def valid_jwt?(token)
      JWT.decode(token, JwtCookieCsrf.configuration.jwt_secret, true, algorithm: JwtCookieCsrf.configuration.jwt_algorithm)
      true
    rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::VerificationError
      false
    end

    def ensure_csrf_cookie(request, response)
      if request.cookies[JwtCookieCsrf.configuration.csrf_cookie_name].nil?
        csrf_token = SecureRandom.hex(32)
        set_cookie(response, JwtCookieCsrf.configuration.csrf_cookie_name, csrf_token, http_only: false)
      end
    end

    def rotate_csrf_cookie(response)
      csrf_token = SecureRandom.hex(32)
      set_cookie(response, JwtCookieCsrf.configuration.csrf_cookie_name, csrf_token, http_only: false)
    end

    def set_cookie(response, name, value, options = {})
      Rack::Utils.set_cookie_header!(response[1], name, { value: value, path: "/", same_site: :strict }.merge(options))
    end

    def unauthorized_response
      [401, { "content-type" => "text/plain" }, ["Unauthorized"]]
    end

    def forbidden_response(message)
      [403, { "content-type" => "text/plain" }, [message]]
    end
  end
end

