(function() {
  var app, googlePage, http;

  http = require("http");

  googlePage = require("./google-page");

  app = googlePage.app();

  exports.run = function(argv) {
    return http.createServer(app).listen(app.get("port"), function() {
      return console.log("Express server listening on port " + app.get("port"));
    });
  };

}).call(this);
