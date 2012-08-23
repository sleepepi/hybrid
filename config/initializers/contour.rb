# Use to configure basic appearance of template
Contour.setup do |config|

  # Enter your application name here. The name will be displayed in the title of all pages, ex: AppName - PageTitle
  config.application_name = DEFAULT_APP_NAME

  # If you want to style your name using html you can do so here, ex: <b>App</b>Name
  # config.application_name_html = ''

  # Enter your application version here. Do not include a trailing backslash. Recommend using a predefined constant
  config.application_version = Hybrid::VERSION::STRING

  # Enter your application header background image here.
  config.header_background_image = ''

  # Enter your application header title image here.
  # config.header_title_image = ''

  # Enter the items you wish to see in the menu
  config.menu_items = [
    {
      name: 'Login', display: 'not_signed_in', path: 'new_user_session_path', position: 'right',
      links: [{ name: 'Sign Up', path: 'new_user_registration_path' }]
    },
    {
      name: 'current_user.name', eval: true, display: 'signed_in', path: 'user_path(current_user)', position: 'right',
      links: [{ html: '"<div class=\"small\" style=\"color:#bbb\">"+current_user.email+"</div>"', eval: true },
              { name: 'Settings', path: 'settings_path' },
              { name: 'Authentications', path: 'authentications_path', condition: 'not PROVIDERS.blank?' },
              { html: '<br />' },
              { name: 'Logout', path: 'destroy_user_session_path' }]
    },
    {
      name: 'Search', display: 'signed_in', path: 'root_path', position: 'left',
      links: [{ name: 'History', path: 'queries_path' },
              { html: '<br />' },
              { name: 'About', path: 'about_path' }]
    },
    {
      name: '@source.name', eval: true, display: 'signed_in', path: 'source_path(@source)', position: 'left',
      condition: '@source and not @source.new_record?',
      links: [{ name: 'Rules', path: 'source_rules_path(source_id: @source.id)' },
              { name: 'File Types', path: 'source_file_types_path(source_id: @source.id)' },
              { name: 'Joins', path: 'source_joins_path(source_id: @source.id)' }]
    },
    {
      name: 'Dictionaries', display: 'signed_in', path: 'dictionaries_path', position: 'left', condition: 'current_user.system_admin?',
      links: []
    },
    {
      name: 'Sources', display: 'signed_in', path: 'sources_path', position: 'left', condition: 'current_user.system_admin?',
      links: []
    },
    {
      name: 'Users', display: 'signed_in', path: 'users_path', position: 'left', condition: 'current_user.system_admin?',
      links: []
    },
    {
      name: 'About', display: 'always', path: 'about_path', position: 'left',
      links: []
    }
  ]

  # Enter an address of a valid RSS Feed if you would like to see news on the sign in page.
  config.news_feed = 'https://sleepepi.partners.org/category/informatics/hybrid/feed/rss'

  # Enter the max number of items you want to see in the news feed.
  config.news_feed_items = 3
end
