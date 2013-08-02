fs         = require "fs"
path       = require "path"
toml       = require "toml"
http       = require "http"
googlePage = require("./google-page")

exports.run = (argv) ->
  file   = argv.c or throw new Error("-c is required")
  dir    = argv.d or process.cwd()
  port   = argv.p or process.env.PORT or 3000

  config = toml.parse(fs.readFileSync(file).toString())
  app    = googlePage.app(dir, config)

  http.createServer(app).listen port, ->
    console.log "Express server listening on port " + port
