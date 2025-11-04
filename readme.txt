To test library first run bundle exec rackup -p 3000 to start a server.
Than execute curl.exe -v -X POST http://localhost:3000/login to get
tokens (in second terminal).
Than do curl.exe -v -X POST http://localhost:3000/protected -H "X-CSRF-Token: $CSRF" -b "auth_token=$JWT; csrf_token=$CSRF"
in second terminal, where $CSRF is last token showed after login call and $JWT is the first one.

If done, Protected resource accessed message should display after second command.
If tokens don't match, 403 Forbidden error rises.