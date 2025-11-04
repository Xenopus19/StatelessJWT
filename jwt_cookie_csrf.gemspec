# jwt_cookie_csrf.gemspec

# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "jwt_cookie_csrf"
  spec.version       = "0.1.0"
  spec.authors       = ["Olha Moskovska"]
  spec.email         = ["moskovskaya.olga10@gmail.com"]

  spec.summary       = "A Ruby gem for stateless JWT authentication in cookies with CSRF protection using double submit/nonce method."
  spec.description   = "Implements stateless JWT stored in signed cookies, combined with CSRF protection via double submit cookie (nonce) for API endpoints."
  spec.homepage      = "https://github.com/Xenopus19/jwt_cookie_csrf"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir["lib/**/*.rb", "spec/**/*.rb"]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "jwt", "~> 2.8"
  spec.add_dependency "rack", "~> 3.1"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end