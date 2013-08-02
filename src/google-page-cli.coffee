fs         = require "fs"
path       = require "path"
toml       = require "toml"
http       = require "http"
googlePage = require("./google-page")

exports.run = ->
  argv = require("optimist")
    .usage(
      "Usage: google-page -c config.toml"
    ).options("c",
      alias:    "config"
      describe: "Config file"
      demand:   true
    ).options("d",
      alias:    "dir"
      describe: "Data directory (default: current dir)"
    ).options("p",
      alias:    "port"
      describe: "Port (default: $PORT or 3000)"
    ).argv

  file   = argv.c
  dir    = argv.d or process.cwd()
  port   = argv.p or process.env.PORT or 3000

  config = toml.parse(fs.readFileSync(file).toString())
  app    = googlePage.app(dir, config)

  http.createServer(app).listen port, ->
    console.log "GooglePage server listening on port " + port + ", serving " + dir
