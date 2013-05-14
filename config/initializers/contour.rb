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
  config.menu_items =
  [
    {
      name: 'Login', display: 'not_signed_in', path: 'new_user_session_path', position: 'right',
      links: [{ name: 'Sign Up', path: 'new_user_registration_path' },
              { divider: true },
              { authentications: true }]
    },
    {
      name: 'current_user.name', eval: true, display: 'signed_in', position: 'right',
      links: [{ html: '"<div class=\"small\" style=\"color:#bbb\">"+current_user.email+"</div>"', eval: true },
              { name: 'Settings', path: 'settings_path' },
              { name: 'Authentications', path: 'authentications_path', condition: 'not PROVIDERS.blank?' },
              { divider: true },
              { name: 'Logout', path: 'destroy_user_session_path' }]
    },
    {
      name: 'Search', display: 'signed_in', path: 'root_path', position: 'left'
    },
    {
      name: 'History', display: 'signed_in', path: 'queries_path', position: 'left'
    },
    {
      name: 'Dictionaries', display: 'signed_in', path: 'dictionaries_path', position: 'left', condition: 'current_user.system_admin?'
    },
    {
      name: 'Sources', display: 'signed_in', path: 'sources_path', position: 'left', condition: 'current_user.system_admin?'
    },
    {
      name: '@source.name', eval: true, display: 'signed_in', path: 'source_path(@source)', position: 'left',
      condition: '@source and not @source.new_record?',
      links: [{ name: 'Rules', path: 'source_rules_path(source_id: @source.id)' },
              { name: 'File Types', path: 'source_file_types_path(source_id: @source.id)' },
              { name: 'Joins', path: 'source_joins_path(source_id: @source.id)' }]
    },
    {
      name: 'Users', display: 'signed_in', path: 'users_path', position: 'left', condition: 'current_user.system_admin?'
    },
    {
      name: 'About', display: 'always', path: 'about_path', position: 'left'
    }
  ]

  # Enter an address of a valid RSS Feed if you would like to see news on the sign in page.
  config.news_feed = 'https://sleepepi.partners.org/category/informatics/hybrid/feed/rss'

  # Enter the max number of items you want to see in the news feed.
  config.news_feed_items = 3

  # The following three parameters can be set as strings, which will rotate through the colors on a daily basis, selecting an index using (YearDay % ArraySize)

  # A string or array of strings that represent a CSS color code for generic link color
  # config.link_color = nil

  # A string or array of strings that represent a CSS color code for the body background color
  # config.body_background_color = nil

  # A string or array of strings that represent an image url for the body background image
  # config.body_background_image = nil

  # A hash where the key is a string in "month-day" format where values are a hash of the link_color, body_background_color and/or body_background_image
  # An example might be (April 1st), { "4-1" => { body_background_image: 'aprilfools.jpg' } }
  # Note the lack of leading zeros!
  # Special days take precendence over the rotating options given above
  # config.month_day = {}

  # An array of hashes that specify additional fields to add to the sign up form
  # An example might be [ { attribute: 'first_name', type: 'text_field' }, { attribute: 'last_name', type: 'text_field' } ]
  config.sign_up_fields = [ { attribute: 'first_name', type: 'text_field' }, { attribute: 'last_name', type: 'text_field' } ]

  # An array of text fields used to trick spam bots using the honeypot approach. These text fields will not be displayed to the user.
  # An example might be [ :url, :address, :contact, :comment ]
  config.spam_fields = [ :url, :address, :contact, :comment ]
end
