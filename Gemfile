source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in counter.gemspec.
gemspec

group :development do
  gem "sqlite3"
  gem "standardrb"
  gem "annotate"
end

group :test do
  gem "minitest-reporters"
end

# To use a debugger
gem "byebug", group: [:development, :test]
