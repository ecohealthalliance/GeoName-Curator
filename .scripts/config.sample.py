meteor_db_name = "meteor"
meteor_mongo_port = 3001
fields_spreadsheet_id = "abcd"
events_spreadsheet_id = "abcd"
zotero_library_id = '1234'
zotero_library_type='group'
zotero_api_key = 'abcd'
google_refresh_token = "abcd"
google_client_id = "abcd.apps.googleusercontent.com"
google_client_secret = "abcd"

# If the google refresh token has been revoked or lost, you can obtain a new one,
# but note that requesting new tokens may make the old ones stop working.

# run python -m SimpleHTTPServer 3000
# visit https://accounts.google.com/o/oauth2/auth?response_type=code&client_id={{ google_client_id }}&scope=https://www.googleapis.com/auth/drive&access_type=offline&redirect_uri=http://localhost:3000/_oauth/google
# sign in as jenkinsdart@gmail.com
# watch SimpleHTTPServer stdout for credentials in oauth redirect url
# eg "GET /_oauth/google?code={{ code }} HTTP/1.1" 404 -
# extract the code and use it to make a post request: curl --data "code={{ code }}&client_id={{ google_client_id }}&client_secret={{ google_client_secret }}&grant_type=authorization_code&redirect_uri=http://localhost:3000/_oauth/google" https://www.googleapis.com/oauth2/v3/token
# the post will return json containing an access token and a refresh token
# replace google_refresh_token in config file