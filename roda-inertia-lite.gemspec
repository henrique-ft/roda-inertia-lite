Gem::Specification.new do |spec|
  spec.name = "roda-inertia-lite"
  spec.version = "0.1.0"
  spec.authors = ["Henrique F. Teixeira"]
  spec.email = ["hriqueft@gmail.com"]

  spec.summary = "Standalone Inertia.js adapter for Roda"
  spec.description = "Inertia.js adapter for Roda, without views or other plugins dependency"
  spec.homepage = "https://github.com/henrique-ft/roda-inertia-lite"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/henrique-ft/roda-inertia-lite"
  spec.metadata["changelog_uri"] = "https://github.com/henrique-ft/roda-inertia-lite/blob/main/CHANGELOG.md"

  spec.files = Dir["lib/**/*", "LICENSE.txt", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "roda", "~> 3.0"
  spec.add_dependency "oj", "~> 3.0"

  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rack-test", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "standard", "~> 1.0"
end
