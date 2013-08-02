(function() {
  var fs, googlePage, http, path, toml;

  fs = require("fs");

  path = require("path");

  toml = require("toml");

  http = require("http");

  googlePage = require("./google-page");

  exports.run = function(argv) {
    var app, config, dir, file, port;
    file = argv.c || (function() {
      throw new Error("-c is required");
    })();
    dir = argv.d || process.cwd();
    port = argv.p || process.env.PORT || 3000;
    config = toml.parse(fs.readFileSync(file).toString());
    app = googlePage.app(dir, config);
    return http.createServer(app).listen(port, function() {
      return console.log("Express server listening on port " + port);
    });
  };

}).call(this);
