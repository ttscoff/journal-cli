# frozen_string_literal: true

require_relative "lib/makenew-rbgem/version"

Gem::Specification.new do |spec|
  spec.name = "makenew-rbgem"
  spec.version = MakenewRbgem::VERSION
  spec.author = "Evan Sosenko"
  spec.email = "razorx@evansosenko.com"

  spec.summary = "Ruby Gem Project Skeleton"
  spec.description = "Project skeleton for a Ruby gem."
  spec.homepage = "https://github.com/makenew/rbgem"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["bug_tracker_uri"] = "#{spec.metadata["source_code_uri"]}/issues"
  spec.metadata["changelog_uri"] = "#{spec.metadata["source_code_uri"]}/blob/master/CHANGELOG.md"
  spec.metadata["github_repo"] = "git@github.com:makenew/rbgem.git"

  spec.bindir = "bin"
  spec.executables = spec.files.grep(%r{\A#{spec.bindir}/}) { |f| File.basename(f) }

  spec.files = Dir["lib/**/*{[!_spec]}.rb"]
  spec.files += Dir["[A-Z]*"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "gem-release", "~> 2.2"
  spec.add_development_dependency "parse_gemspec-cli", "~> 1.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "simplecov", "~> 0.21"
  spec.add_development_dependency "simplecov-console", "~> 0.9"
  spec.add_development_dependency "standard", "~> 1.3"
end
