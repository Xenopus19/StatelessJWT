# frozen_string_literal: true

require 'spec_helper'
require 'jwt_cookie_csrf'

RSpec.describe JwtCookieCsrf::Middleware do
  include Rack::Test::Methods

  let(:app) do
    inner_app = proc { |env| [200, { "Content-Type" => "text/plain" }, ["OK"]] }
    JwtCookieCsrf::Middleware.new(inner_app)
  end

  before do
    JwtCookieCsrf.configure do |config|
      config.jwt_secret = "test_secret"
      config.excluded_paths = ["/login"]
      config.cookie_name = "auth_token"
      config.csrf_cookie_name = "csrf_token"
      config.csrf_header_name = "HTTP_X_CSRF_TOKEN" # Rack преобразует 'X-CSRF-Token'
    end
  end

  def generate_jwt(payload)
    JWT.encode(payload, "test_secret", "HS256")
  end

  describe "GET requests" do
    it "allows GET without tokens" do
      get "/"
      expect(last_response.status).to eq(200)
    end

    it "generates CSRF token if missing" do
      get "/"
      expect(last_response.status).to eq(200)
      expect(last_response.headers["Set-Cookie"]).to include("csrf_token=")
    end
  end

  describe "POST requests" do
    it "rejects without JWT" do
      post "/"
      expect(last_response.status).to eq(401)
    end

    it "rejects with invalid JWT" do
      header "Cookie", "auth_token=invalid"
      post "/"
      expect(last_response.status).to eq(401)
    end

    # ИСПРАВЛЕННЫЙ ТЕСТ: Нам не нужен CSRF в JWT
    it "rejects without CSRF header" do
      jwt = generate_jwt({ user_id: 1 }) # Обычный JWT
      csrf = SecureRandom.hex(32)

      # Устанавливаем cookie, но не заголовок
      header "Cookie", "auth_token=#{jwt}; csrf_token=#{csrf}"

      post "/"
      expect(last_response.status).to eq(403)
    end

    # ИСПРАВЛЕННЫЙ ТЕСТ: Нам не нужен CSRF в JWT
    it "rejects with mismatched CSRF" do
      jwt = generate_jwt({ user_id: 1 }) # Обычный JWT
      right_csrf = SecureRandom.hex(32)

      # Cookie правильный, заголовок - нет
      header "Cookie", "auth_token=#{jwt}; csrf_token=#{right_csrf}"
      header "X-CSRF-Token", "wrong-token" # 'X-CSRF-Token' преобразуется в HTTP_X_CSRF_TOKEN

      post "/"
      expect(last_response.status).to eq(403)
    end

    # ИСПРАВЛЕННЫЙ ТЕСТ (Главный фикс)
    it "allows with valid JWT and matching CSRF" do
      # 1. Валидный JWT (пейлоад не важен для CSRF)
      jwt = generate_jwt({ user_id: 1 })

      # 2. Рандомный CSRF-токен
      csrf = SecureRandom.hex(32)

      # 3. Устанавливаем cookie и заголовок в ОДНО И ТО ЖЕ значение
      header "Cookie", "auth_token=#{jwt}; csrf_token=#{csrf}"
      header "X-CSRF-Token", csrf

      post "/"

      # Теперь проверка (csrf_cookie == csrf_header) должна пройти
      expect(last_response.status).to eq(200)

      # И мы проверяем, что токен был ротирован (установлен новый)
      expect(last_response.headers["Set-Cookie"]).to include("csrf_token=")
      # Убедимся, что это не тот же самый токен
      expect(last_response.headers["Set-Cookie"]).not_to include("csrf_token=#{csrf};")
    end

    it "allows excluded paths without tokens" do
      post "/login"
      expect(last_response.status).to eq(200)
    end
  end
end

