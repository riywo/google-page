http = require "http"
app  = require "./google-page"

exports.run = (argv) ->
  http.createServer(app).listen app.get("port"), ->
    console.log "Express server listening on port " + app.get("port")
