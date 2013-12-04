## 0.15.2

### Enhancements
- **Gem Changes**
  - Updated to rails 4.0.2
  - Updated to contour 2.2.0.rc2
  - Updated to kaminari 0.15.0
  - Updated to coffee-rails 4.0.1
  - Updated to sass-rails 4.0.1
  - Updated to simplecov 0.8.2
  - Updated to mysql 0.3.14

## 0.15.1 (September 3, 2013)

### Enhancements
- **General Changes**
  - The interface now uses [Bootstrap 3](http://getbootstrap.com/)
  - Reorganized Menu
- **Gem Changes**
  - Updated to contour 2.1.0.rc
  - Updated to pg 0.16.0 and aqueduct-postgresql 0.2.2
  - Updated to mysql 0.3.13

## 0.15.0 (July 26, 2013)

### Enhancements
- PostgreSQL is now the database of choice for the Sleep Portal
- Queries can now be constructed by chosing concepts in another data source that are linked to the original query data source
- Individual Data Source columns now display available concepts if the automap picks up more than one mapping candidate
- Data Source tables can now be named to specify the encounter or visit
  - This allows the same concept to be mapped in multiple tables
- Modified interface for selecting boolean and categorical search criteria
- Creating and editing a source join now provides underlying table and column information
- Adding new criteria to search now shows the total count available without specifying a value
- Use of Ruby 2.0.0-p247 is now recommended
- **Gem Changes**
  - Updated to rails 4.0.0
  - Updated to contour 2.0.0

### Refactoring
- Renamed queries to searches
- Renamed query concepts to criteria
- Removed references to external concepts and datasets
- Source Joins have been removed
  - To link across sources `identifier` variables are now required to be mapped in each source
- Source Rules and Source Files interfaces updated to be more consistent
- Mappings no longer have status, deleted, or units
- Generic concepts have been changed into variables and domains for better integration using the [Spout JSON Data Dictionary Gem](https://github.com/sleepepi/spout)

### Bug Fix
- Resolved an issue that created aliasing in line charts caused by truncating graph values before inserting the variables into buckets

## 0.14.2 (June 19, 2013)

### Enhancements
- Use of Ruby 2.0.0-p195 is now recommended
- **Gem Changes**
  - Updated to rails 4.0.0.rc2

### Refactoring
- Removed uri, namespace, and name from concepts for simpler imports and exports
- Data Dictionary import simplified, imports CSV data by column header name
- Concept folders and subfolders are now separated by `/` instead of `:`
- Sources with large amounts of tables and columns now load more quickly

### Bug Fix
- Fixed a data dictionary import failure caused by concept status column

## 0.14.1 (May 14, 2013)

### Enhancements
- **Gem Changes**
  - Updated to rails 4.0.0.rc1
  - Updated to contour 2.0.0.beta.8
  - Updated to pg 0.15.1

## 0.14.0 (April 10, 2013)

### Enhancements
- Added a tool to perform frequency-based matching

### Bug Fix
- Dataset concepts now properly show concept popup information when clicked

## 0.13.2 (April 4, 2013)

### Bug Fix
- Fixed a bug preventing new users from being added to source rules

## 0.13.1 (March 20, 2013)

### Enhancements
- **Gem Changes**
  - Updated to Contour 2.0.0.beta.4

## 0.13.0 (March 19, 2013)

### Enhancements
- Use of Ruby 2.0.0-p0 is now recommended
- **Gem Changes**
  - Updated to Rails 4.0.0.beta1
  - Updated to Contour 2.0.0.beta.3
- Sources can now additionally be specified as PostgreSQL databases
- Dictionary imports simplified, `similar_concepts`, and `equivalent_concepts` columns removed
- Updated popup used for searching and viewing data sources and concepts
- Removed unused `view data source mappings` rule

## 0.12.6 (February 13, 2013)

### Security Fix
- Updated Rails to 3.2.12

### Enhancements
- Updated to Contour 1.2.0.pre7 with jQuery 1.9.1
- ActionMailer can now be configured to use the NTLM protocol used by Microsoft Exchange Server
- Removed references to `.dup` to make Ruby 2.0.0 compatible

## 0.12.5 (January 9, 2013)

### Enhancements
- Updated to Contour 1.1.2 and use Contour pagination theme
- Updated Thin Server to 1.5.0

## 0.12.4 (January 8, 2013)

### Security Fix
- Updated Rails to 3.2.11

## 0.12.3 (January 3, 2013)

### Security Fix
- Updated Rails to 3.2.10

### Bug Fix
- User activation emails are no longer sent out when a user's status is changed from pending to inactive

## 0.12.2 (November 27, 2012)

### Enhancements
- Gem updates including Rails 3.2.9 and Ruby 1.9.3-p327
- File types now allow simple HTML formatting
- Updated to Contour 1.1.1 and replaced inline JavaScript with Unobtrusive JavaScript
- Search boxes for data sources and data concepts now use Select2 JavaScript plugin

### Bug Fix
- Create New Rule button from the Source Rules index now correctly directs the user to the New Rule page for the selected data source

## 0.12.1 (October 16, 2012)

### Bug Fix
- Fixed a bug that prevented dictionary CSV files from being added to a dictionary
- Fixed a bug that prevented users from being granted access to data source rules

## 0.12.0 (September 13, 2012)

### Enhancements
- Major GUI update using Twitter Bootstrap
- Updated to Rails 3.2.8 and Contour 1.0.5
- Updated Devise configuration files for devise 2.1.0
- Links with confirm: now use `data: { confirm: }` to account for deprecations in Rails 4.0
- Removed deprecated use of update_attribute for Rails 4.0 compatibility
- About page reformatted to include links to github and contact information

### Refactoring
- Consistent sorting of all objects, (queries, dictionaries, sources, concepts, etc)

### Testing
- Use ActionDispatch for Integration tests instead of ActionController

## 0.11.9 (August 24, 2012)

### Enhancements
- Cleaning up and preparations for upcoming 0.12.0 release
- Email Changes:
  - Default application name is now added to the from: field for emails
  - Email subjects no longer include the application name

## 0.11.8 (April 3, 2012)

### Enhancements
- Allows service accounts to create activated users with a JSON web service request
- Updated to Rails 3.2.3

## 0.11.7 (March 26, 2012)

### Bug Fix
- Non-breaking spaces no longer appear when indenting and grouping search concepts

## 0.11.6 (March 20, 2012)

### Enhancements
- Updated to Rails 3.2.2 and Contour 0.10.2 and Ruby 1.9.3-p125
- Minor GUI fix for report configuration table when reports are very wide

### Bug Fix
- Reports that load results from databases that return dates with time now group and stratify correctly

## 0.11.5

### Refactoring
- Minor GUI change

## 0.11.4 (February 22, 2012)

### Enhancements
- Updating style using Contour Minimalist Theme
- Streamlined building of Datasets and Reports now underneath the search

## 0.11.3

### Bug Fix
- Deleting a report/dataset no longer triggers the popup window

## 0.11.2

### Bug Fix
- Creating a report/dataset now correctly configures the popup window

## 0.11.1 (February 3, 2012)

### Enhancements
- Repositories can now be dynamically added through the Gemfile
- Date concepts can now be searched
- Reporting improvements:
  - Dates reporting can now be down by year, by month (default), calendar year week, or day
  - Rows with 0 overall results are no longer displayed in reports
  - Reports and Datasets popup now shows up immediately after creating report/dataset
- Popup expand and collapse buttons now show up individually

### Bug Fix
- Table columns for data sources are now reloaded properly after using the automap feature
- Reports now correctly calculate min/max/avg statistics when the data source reports the values as strings
- Fixed continuous graphs rendering blank values as zero
- Elastic File server status fixed
- Derived mappings should be generated for each column in a data source

### Refactoring
- Updated to Rails 3.2.1

## 0.11.0 (January 24, 2012)

### Enhancements
- i2b2 Wrapper can now return datasets for searches
- i2b2 Wrapper prototype in place for dynamic reporting
- Elastic Wrapper now uses JSON and now associates the user with the file downloader

### Refactoring
- Gem dependencies updated:
  - Rails 3.2.0
  - Contour ~> 0.9.3
- Devise migration and configuration file updated
- Environment files updated to be in sync with Rails 3.2.0
- Updated Devise locales files for Devise 2.0.0.rc2

## 0.10.1

### Bug Fix
- Generating reports for partial categorical mappings with NULL values now correctly sorts the array of values

## 0.10.0 (November 17, 2011)

### Enhancements
- A in-page tutorial has been added that highlights the important sections the search interface
- Mouseover tooltips added to aid researchers in creating their search
- Value ranges can now be set using >=, >, =, <=, <, or (a:b), [a:b], (a:b], [a:b)
- Undo and redo history is now tracked while building searches for adding, updating and removing search concepts
- Searches can now be copied, allowing them to be used as templates for other searches
- `Tab` and `Enter` now select items from the autocomplete list when searching for data sources and concepts
- Previous search history can now be filtered and sorted, and is also paginated
- A search term's categorical values can now be selected using Select All and Deselect All

### Testing
- Test Coverage now at 90%

## 0.9.1

### Bug Fix
- Fixed elastic file downloads for compatibility with Ruby 1.9.3

## 0.9.0 (November 4, 2011)

### Enhancements
- i2b2 data source wrapper functionality expanded and a researcher can now:
  - Explore concepts associated with the connected i2b2 data source
  - Add concepts to a search
  - Retrieve individual and aggregate counts for searches

### Testing
- Analyzing test coverage using SimpleCov gem, test coverage now at 82%

## 0.8.0 (October 17, 2011)

### Enhancements
- Search Concepts can now be selected and unselected which allows:
  - Increase and decrease indentation for better grouping of concepts
  - Copying of multiple concepts to build complex searches more quickly
  - Removing multiple concepts at a time
- ANDs and ORs can now be directly modified by clicking on them in the search
  - Modifying ANDs and ORs will automatically set and group concepts based on their current indentation level
- Numbers for search results now contain delimiters, ex: 1000 records now written as 1,000 records
- Added Wireframe Mono Icons from gentleface.com with Creative Commons (Attribution-Noncommercial 3.0 Unported) License
- Searches now provide better feedback when a sensitive concept is added and the user does not have "view data distribution" or "download dataset"
- Searching for concepts now provides feedback if no data sources have been selected and if the search term does not find a corresponding concept

### Bug Fix
- Report Table and Dataset generation no longer fail if a user adds a sensitive concept in the search, the sensitive concept is simply omitted from the report or dataset

### Testing
- CriteriaController test updated to include actions for selecting, indenting, copying, and removing search concepts

## 0.7.0 (October 10, 2011)

### Enhancements
- Update to Rails 3.1.1
- The login page now displays the latest news from the Sleep Portal RSS Feed, (gem Contour 0.5.6)
- Reports now reload when opening the report and when adding or removing concepts to the report
- Users can now delete a concept directly from a report
- Percent and Count options can now be set for categorical and boolean concepts allowing the percentages to be downloaded in their own column
- FTP File Repository support added for data sources
- Concept Folder View changes:
  - Commonly Used Concepts are now emphasized in the folder search view for concepts
  - Uncategorized Concepts are no longer displayed
- Concept for queries and reports now have a visual indicator to show that they can be dragged
- File downloads now give messages to the user if the user does not have the 'file download' access rule for a particular data source
- Added [Sleep Portal] to subject for registration and password reset emails sent by Devise
- The data source popup box now displays:
  - Summary Count information: Counts for mapped concepts that are marked as identifiers, (ie: Patient IDs, Record IDs, Study IDs)
  - Cross-Linked Data Sources: Sources that are linked using a cross-data source join (unique key)
  - Associated Dictionaries: Lists of the dictionaries that have concepts mapped to the data source

### Bug Fix
- Concepts with a Source PDF document now correctly append the request script_name to correctly link to the associated PDF
- The MySQL Wrapper was incorrectly rounding float values of records to the closest integer when doing comparisons, comparisons are now correctly using the full float value
- New searches should redirect to the root url so that a new search isn't created when the page is refreshed
- Updated Contour gem to 0.5.5 which fixes incorrect message for users when registering
- Boolean concepts that are children of categorical concepts, such as Male (boolean concept) under Gender (categorical)
  - now correctly generate boolean results in reports and datasets
  - render correctly as graphs using True, False, and Unknown as values
- Reports for queries that return an empty set now generate an error message that states that the underlying query needs to be modified to generate a report table

### Documentation
- Added a sample dictionary file (CSV) to `test/support/dictionaries/tiny_dictionary.csv`
- Added a sample database file (SQL Dump) to `test/support/dictionaries/tiny_sleep.sql`

### Testing
- Updated Report Concept tests to assure that the positions are correctly updated when a report is modified
- Reordering Report Concepts tests to make sure the stratified variables (rows) are always put before the other variables (columns)
- Dictionary controller functional test now tests that CSV files are imported correctly

## 0.6.0 (September 30, 2011)

### Enhancements
- Categorical and Boolean concepts no longer need to be fully mapped to be available in the search
- Filtering partial mappings in the source mapper now displays the missing values
- Automap now correctly updates mappings to reflect partial mappings if new column values have been added in the underlying data source
- Errors in the query building process now display warning icons with error messages next to the associated query concept
- Reports now have formatted columns to better view the information
- Datasets are now cleaner, concepts returned are given their human name as opposed to the full length concept uri

### Bug Fix
- Reports now correctly render boolean concepts and mappings that contain NULL values that have been mapped to unknown
- Derived mappings now return correct count results, and are available in datasets and reports

## 0.5.0 (September 8, 2011)

### Enhancements
- Update to Rails 3.1.0 and Devise 1.4.4
- Authentication and layout is now provided by Contour 0.5.0
- Concepts are now filtered by the query's sources and linked sources
  - in the tree hierarchy popup
  - in the autocomplete search
- Source popup information now displays the available file types for download
- Source popup information now displays the current user's data access rules
- Source Rules can now be given a name and a description
- Reports and Datasets can now be
  - renamed
  - copied from existing templates
- Report rows and columns can now be specified to customize a report

### Bug Fix
- Pie charts that display data from multiple sources now correctly instead of overlapping the data

## 0.4.0 (August 25, 2011)

### Enhancements
- Query Concepts can now be reordered by dragging and dropping them
- Allow users to set their email preferences on the settings page
- Users can now view and access a History of their searches
- When a user does not select a data source for the search, the search now returns an empty set
- Menu bar now sticks to the top of the window when the user scrolls down the page
- Concept graphs now show all values for individual associated mappings
- Data Sources can now generate their derived mappings to leverage relationships across and within dictionaries
- Sensitive variables can now be identified in the dictionary and can only be viewed by users with source access rule:
  - view data distribution
  - edit data source mappings
- Non-sensitive variables can be seen by users with source access rule:
  - view limited data distribution
- Sensitive variables can now be downloaded in datasets by users with source access rule:
  - download dataset
- Non-sensitive variables can now be downloaded in datasets by users with source access rule:
  - download limited dataset
- File Types are now associated to individual data sources

### Deployment
- GEMFILE now groups gems for data source wrappers so that they can be included or excluded during an install
  - `bundle install   # Install all gems`
  - `bundle update    # Updates all gems`
  - `bundle install --without oracle # Will install without Oracle specific gems`
  - `bundle install --without mssql  # Will install without MSSQL specific gems`
  - `bundle install --without oracle mssql # Without Oracle or MSSQL gems`
- Support for MSSQL 2008 data sources added back in

### Documentation
- Added documentation for installing gems needed for Oracle and MSSQL wrappers
- Updated installation instructions for Windows 7 environments

### Bug Fixes
- Concepts mapped directly to table column values now have their status correctly marked as 'mapped'
- Fixed graphs having negative axis even when no negative values existed

### Testing
- Updated navigation test to make it less dependent on changes in internationalization
- Test cases created for file types and source file types

## 0.3.2

### Bug Fixes
- File downloading popup now correctly generates server request using proper web address

## 0.3.1

### Enhancements
- Elastic file repository support for multiple folder locations

## 0.3.0 (August 12, 2011)

### Enhancements
- Modified the authentication system so that it can authenticate correctly when behind a reverse proxy and within a firewall.

## 0.2.1

### Bug Fixes
- Popups for adding a Concept and for adding Source to a Query now correctly add the selected item to the query

## 0.2.0 (July 29, 2011)

### Enhancements
- 1-Click Multi-File downloading support through Elastic File Service
- Streamlined the addition and removal of both concepts and sources to be more consistent
- Data source auto map feature has been improved to easily map the entire data source instead of table by table
- Data source mappings can be now cleared in aggregate with a single click
- Data source mappings are now displayed in an overview
- Various minor GUI updates to improve a user's experience

### Bug Fixes
- JavaScript bug fixed that caused report and dataset creation to fail
- Boolean and Categorical concepts now correctly return a correct result when negating the elements even with mapped NULLs in the underlying dataset
- Password fields are no longer discarded when data source meta-information is updated

## 0.1.0 (July 12, 2011)

### Enhancements
- IE7 JavaScript and CSS fixes and improvements
- Queries have been simplified and no longer require a Show (select identifier) to be set
- Update Rails to 3.1
- Update Devise to 1.3.4 and Omniauth 0.2.6
- Report and Dataset generation simplified
- FileType created and file downloading simplified

### Refactoring
- JavaScript rewritten using CoffeeScript

### Test Coverage
- Integration tests added to check that
  - Valid users are forwarded to the correct url after login
  - Pending users aren't allowed to login
  - Deleted users aren't allowed to login
- FileType and Report tests updated

## 0.0.0 (July 1, 2011)

* Servers can securely register as service accounts in other instances
- Communication between servers transparent
* Source Rules are now easier to assign to a user or a group of users
- Access rules can also be defined across servers
* Queries can now do cross-source joins for longitudinal or related data sets
- Provide Dataset creation and retrieval
- Provide Report Generation
- Queries can be specified by any combination of ANDs, ORs, and brackets
* Files can be shared via different methods dependent on the data source
- Elastic File downloading for generating secure P2P file downloading
- FTP for backwards compatibility
- Mounted files for easier installation
* Installation has been made easier by making specific branches available
* HighCharts used for client-side interactive charts

### Test Coverage
- Initial test coverage to make sure all fixtures, and unit/functional tests are set up correctly
