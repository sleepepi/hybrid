source 'https://rubygems.org'

gem 'rails',                '3.2.3'

# Database Adapter
# Install instructions for Windows: http://blog.mmediasys.com/2011/07/07/installing-mysql-on-windows-7-x64-and-using-ruby-with-it/
gem 'mysql2',               '0.3.11'
gem 'thin',                 '~> 1.4.1',           :platforms => [ :mswin, :mingw ]
gem 'eventmachine',         '~> 1.0.0.rc.4',      :platforms => [ :mswin, :mingw ]

# Gems used by project
gem 'contour',              '~> 0.10.2'
gem 'contour-minimalist',   '~> 0.1.4'

# gem 'contour',              '~> 0.11.0.pre'
# gem 'contour-minimalist',   '~> 0.2.0.pre'
gem 'kaminari'
# Builder: For Building XML messages for Web service based data sources
gem 'builder',              '~> 3.0.0'

# Data File and Data Source connections
gem 'aqueduct',             '~> 0.1.0'
gem 'aqueduct-elastic',     '~> 0.1.0'
gem 'aqueduct-ftp',         '~> 0.1.0'
gem 'aqueduct-mounted',     '~> 0.1.0'
gem 'aqueduct-mysql',       '~> 0.1.0'
# gem 'aqueduct-mssql2008',   '~> 0.1.0'
gem 'aqueduct-i2b2',        '~> 0.1.0'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',         '~> 3.2.5'
  gem 'coffee-rails',       '~> 3.2.2'
  gem 'uglifier',           '>= 1.0.3'
end

gem 'jquery-rails'

# Testing
group :test do
  # Pretty printed test output
  gem 'win32console',                             :platforms => [ :mswin, :mingw ]
  gem 'turn',               '~> 0.9.6'
  gem 'simplecov',          '~> 0.6.4',           :require => false
  gem 'artifice'
end
