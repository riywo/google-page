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
      describe: "Config TOML file"
      demand:   true
    ).options("d",
      alias:    "dir"
      describe: "Data directory (default: current dir)"
    ).options("p",
      alias:    "port"
      describe: "Port number    (default: $PORT or 3000)"
    ).options("s",
      alias:    "session"
      describe: "Session store  (default: dir/.google-page.nedb)"
    ).argv

  file   = argv.c
  dir    = argv.d or process.cwd()
  port   = argv.p or process.env.PORT or 3000
  store  = argv.s or path.join(dir, ".google-page.nedb")

  process.env.NODE_ENV = process.env.NODE_ENV or "production"

  config = toml.parse(fs.readFileSync(file).toString())
  app    = googlePage.app(dir, store, config)

  http.createServer(app).listen port, ->
    console.log "GooglePage server listening on port " + port + ", serving " + dir
