(function() {
  var fs, googlePage, http, path, toml;

  fs = require("fs");

  path = require("path");

  toml = require("toml");

  http = require("http");

  googlePage = require("./google-page");

  exports.run = function() {
    var app, argv, config, dir, file, optimist, port, store;
    optimist = require("optimist").usage("Usage: google-page -c config.toml").options("c", {
      alias: "config",
      describe: "Config TOML file",
      demand: true
    }).options("d", {
      alias: "dir",
      describe: "Data directory (default: current dir)"
    }).options("p", {
      alias: "port",
      describe: "Port number    (default: $PORT or 3000)"
    }).options("s", {
      alias: "session",
      describe: "Session store  (default: dir/.google-page.nedb)"
    }).options("h", {
      alias: "help",
      describe: "Show help"
    });
    argv = optimist.argv;
    if (argv.h) {
      optimist.showHelp();
      process.exit(0);
    }
    file = argv.c;
    dir = argv.d || process.cwd();
    port = argv.p || process.env.PORT || 3000;
    store = argv.s || path.join(dir, ".google-page.nedb");
    process.env.NODE_ENV = process.env.NODE_ENV || "production";
    config = toml.parse(fs.readFileSync(file).toString());
    app = googlePage.app(dir, store, config);
    return http.createServer(app).listen(port, function() {
      return console.log("GooglePage server listening on port " + port + ", serving " + dir);
    });
  };

}).call(this);
