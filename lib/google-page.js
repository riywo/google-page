(function() {
  var GoogleStrategy, app, csrf, ensureAuthenticated, express, nedb, passport, path;

  express = require("express");

  path = require("path");

  nedb = require("connect-nedb-session")(express);

  passport = require("passport");

  GoogleStrategy = require("passport-google").Strategy;

  app = express();

  app.set("port", process.env.PORT || 3000);

  app.set("views", path.join(__dirname, "..", "views"));

  app.set("view engine", "jade");

  app.set("schema", process.env.SECPAGE_SSL === "1" ? "https" : "http");

  app.set("server", process.env.SECPAGE_SERVER || "google-page.dev");

  app.set("gmail domain", process.env.SECPAGE_GMAIL_DOMAIN || "gmail.com");

  app.set("session secret", process.env.SECPAGE_SESSION_SECRET || "secret string");

  app.set("private dir", process.env.SECPAGE_PRIVATE_DIR || path.join(__dirname, "..", "private"));

  app.configure('development', function() {
    var edt;
    edt = require('express-debug');
    return edt(app, {
      depth: 10
    });
  });

  passport.use(new GoogleStrategy({
    returnURL: app.get("schema") + "://" + app.get("server") + "/auth/return",
    realm: app.get("schema") + "://" + app.get("server")
  }, function(identifier, profile, done) {
    return process.nextTick(function() {
      profile.idnetifier = identifier;
      if (profile.emails[0].value.match(RegExp("@" + app.get("gmail domain") + "$"))) {
        return done(null, profile);
      } else {
        return done(null, false, {
          message: "error"
        });
      }
    });
  }));

  passport.serializeUser(function(user, done) {
    return done(null, user);
  });

  passport.deserializeUser(function(obj, done) {
    return done(null, obj);
  });

  ensureAuthenticated = function(req, res, next) {
    if (req.isAuthenticated()) {
      return next();
    }
    req.session.request_path = req.path;
    return res.redirect('/login');
  };

  csrf = function(req, res, next) {
    res.locals_csrf = req.session._csfr;
    return next();
  };

  app.use(express.favicon());

  app.use(express.logger("dev"));

  app.use(express.bodyParser());

  app.use(express.methodOverride());

  app.use(express.cookieParser());

  app.use(express.session({
    secret: app.get("session secret"),
    key: "secpagesession",
    store: new nedb({
      filename: path.join(__dirname, "..", app.get("env") + ".nedb")
    })
  }));

  app.use(express.csrf());

  app.use(passport.initialize());

  app.use(passport.session());

  app.use(app.router);

  app.use(express["static"](__dirname + '/public'));

  if ("development" === app.get("env")) {
    app.use(express.errorHandler());
  }

  app.get("/", csrf, function(req, res) {
    return res.render("index", {
      title: "Express",
      is_auth: req.isAuthenticated(),
      token: req.session._csrf
    });
  });

  app.get("/login", passport.authenticate('google'), function(req, res) {
    return res.redirect('/');
  });

  app.get("/auth/return", passport.authenticate('google'), function(req, res) {
    path = "/";
    if (req.session.request_path) {
      path = req.session.request_path;
      delete req.session.request_path;
    }
    return res.redirect(path);
  });

  app.post('/logout', csrf, function(req, res) {
    req.logout();
    return res.redirect('/');
  });

  app.get(/(^\/.+$)/, ensureAuthenticated, function(req, res) {
    return res.sendfile(app.get("private dir") + req.params[0]);
  });

  module.exports = app;

}).call(this);
