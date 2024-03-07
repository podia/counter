require_relative "lib/counter/version"

Gem::Specification.new do |spec|
  spec.name = "counterwise"
  spec.version = Counter::VERSION
  spec.authors = ["Jamie Lawrence"]
  spec.email = ["jamie@ideasasylum.com"]
  spec.homepage = "https://github.com/podia/counter"
  spec.summary = "Counters and the counting counters that count them"
  spec.description = "Counting and aggregation library for Rails."
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/podia/counter"
  spec.metadata["changelog_uri"] = "https://github.com/podia/counter/CHANGELOG.md"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", ">= 7"
end
