http       = require "http"
googlePage = require("./google-page")

app = googlePage.app()

exports.run = (argv) ->
  http.createServer(app).listen app.get("port"), ->
    console.log "Express server listening on port " + app.get("port")
