# spec/jwt_cookie_csrf/auth_helper_spec.rb

# frozen_string_literal: true

require 'spec_helper'
require 'jwt_cookie_csrf'
RSpec.describe JwtCookieCsrf::AuthHelper do
  let(:dummy_class) { Class.new { include JwtCookieCsrf::AuthHelper } }
  let(:instance) { dummy_class.new }
  let(:response) { Rack::Response.new }

  before do
    JwtCookieCsrf.configure do |config|
      config.jwt_secret = "test_secret"
    end
  end

  describe "#generate_jwt" do
    it "generates a valid JWT" do
      token = instance.generate_jwt({ user_id: 1 }, expires_in: 3600)
      payload = JWT.decode(token, "test_secret", true, algorithm: "HS256").first
      expect(payload["user_id"]).to eq(1)
      expect(payload["exp"]).to be > Time.now.to_i
    end
  end

  describe "#set_auth_cookie" do
    it "sets HttpOnly and Secure auth cookie" do
      instance.set_auth_cookie(response, "token")
      cookies = response.headers["Set-Cookie"]
      expect(cookies).to include("auth_token=token")
      expect(cookies).to include("httponly")
      expect(cookies).to include("secure")
      expect(cookies).to include("samesite=strict")
    end
  end

  describe "#set_csrf_cookie" do
    it "sets non-HttpOnly Secure CSRF cookie" do
      instance.set_csrf_cookie(response, "csrf")
      cookies = response.headers["Set-Cookie"]
      expect(cookies).to include("csrf_token=csrf")
      expect(cookies).not_to include("httponly")
      expect(cookies).to include("secure")
      expect(cookies).to include("samesite=strict")
    end
  end
end