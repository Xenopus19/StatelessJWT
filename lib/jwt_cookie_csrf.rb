# frozen_string_literal: true

require "jwt"
require "rack"
require_relative "jwt_cookie_csrf/version"
require_relative "jwt_cookie_csrf/middleware"
require_relative "jwt_cookie_csrf/auth_helper"

module JwtCookieCsrf
  class Error < StandardError; end

  class Configuration
    attr_accessor :jwt_secret, :jwt_algorithm, :cookie_name, :csrf_cookie_name, :csrf_header_name, :excluded_paths

    def initialize
      @jwt_secret = ENV["JWT_SECRET"] || "your_secret_key"
      @jwt_algorithm = "HS256"
      @cookie_name = "auth_token"
      @csrf_cookie_name = "csrf_token"
      @csrf_header_name = "X-CSRF-Token"
      @excluded_paths = ["/login", "/logout"]
    end
  end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end