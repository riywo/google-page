(function() {
  var app, http;

  http = require("http");

  app = require("./google-page");

  exports.run = function(argv) {
    return http.createServer(app).listen(app.get("port"), function() {
      return console.log("Express server listening on port " + app.get("port"));
    });
  };

}).call(this);
