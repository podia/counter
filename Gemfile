source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in counter.gemspec.
gemspec

group :development do
  gem "sqlite3"
  gem "annotate"
  gem "ruby-lsp-rails"
  gem "standard"
end

group :test do
  gem "minitest-reporters"
end

# To use a debugger
gem "debug", group: [:development, :test]
