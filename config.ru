# config.ru

require "bundler/setup"
require "jwt_cookie_csrf"
require "rack"
require "securerandom"
require "json"

JwtCookieCsrf.configure do |config|
  config.jwt_secret = "example_secret"
  config.excluded_paths = ["/login"]
end

class ExampleApp
  include JwtCookieCsrf::AuthHelper

  def call(env)
    request = Rack::Request.new(env)

    case request.path
    when "/login"
      if request.post?
        payload = { user_id: 1 }
        jwt_token = generate_jwt(payload)
        csrf_token = SecureRandom.hex(32)

        response = Rack::Response.new({ message: "Logged in" }.to_json, 200, { "content-type" => "application/json" })
        set_auth_cookie(response, jwt_token)
        set_csrf_cookie(response, csrf_token)
        response.finish
      else
        [405, { "content-type" => "text/plain" }, ["Method Not Allowed"]]
      end
    when "/protected"
      if request.post?
        [200, { "content-type" => "application/json" }, [{ message: "Protected resource accessed" }.to_json]]
      else
        [405, { "content-type" => "text/plain" }, ["Method Not Allowed"]]
      end
    else
      [404, { "content-type" => "text/plain" }, ["Not Found"]]
    end
  end
end

app = Rack::Builder.new do
  use JwtCookieCsrf::Middleware
  run ExampleApp.new
end

run app
