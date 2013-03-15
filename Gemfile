source 'https://rubygems.org'

gem 'rails',                '4.0.0.beta1'

# Database Adapter
# Install instructions for Windows: http://blog.mmediasys.com/2011/07/07/installing-mysql-on-windows-7-x64-and-using-ruby-with-it/
gem 'mysql2',               '0.3.11'
gem 'thin',                 '~> 1.5.0',           platforms: [ :mswin, :mingw ]
gem 'eventmachine',         '~> 1.0.0',           platforms: [ :mswin, :mingw ]

# Gems used by project
gem 'contour',              '2.0.0.beta.3'
gem 'devise',               '~> 2.2.3',           github: 'plataformatec/devise',             ref: 'd29b744'   # , branch: 'rails4'
gem 'kaminari',             '~> 0.14.1'
gem 'ruby-ntlm-namespace',  '~> 0.0.1'

# Data File and Data Source connections
gem 'aqueduct',             '~> 0.2.0.pre',       github: 'remomueller/aqueduct',             ref: '6ca6b08'
gem 'aqueduct-elastic',     '~> 0.2.0.pre',       github: 'remomueller/aqueduct-elastic',     ref: '2f99711'
gem 'aqueduct-ftp',         '~> 0.2.0.pre',       github: 'remomueller/aqueduct-ftp',         ref: 'e2ec908'
gem 'aqueduct-mounted',     '~> 0.2.0.pre',       github: 'remomueller/aqueduct-mounted',     ref: '026b74c'
gem 'aqueduct-mysql',       '~> 0.2.0.pre',       github: 'remomueller/aqueduct-mysql',       ref: '66f0add'
gem 'aqueduct-i2b2',        '~> 0.2.0.pre',       github: 'remomueller/aqueduct-i2b2',        ref: 'a55788a'
gem 'aqueduct-postgresql',  '~> 0.2.0.pre',       github: 'remomueller/aqueduct-postgresql',  ref: 'ba62b89'
gem 'pg',                   '0.14.1'
# gem 'aqueduct-mssql2008',   '~> 0.1.0'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',         '~> 4.0.0.beta1'
  gem 'coffee-rails',       '~> 4.0.0.beta1'
  gem 'uglifier',           '>= 1.0.3'
end

gem 'jquery-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 1.0.2'

# Testing
group :test do
  # Pretty printed test output
  gem 'win32console',                             platforms: [ :mswin, :mingw ]
  gem 'turn',               '~> 0.9.6'
  gem 'simplecov',          '~> 0.7.1',           require: false
  gem 'artifice'
end
