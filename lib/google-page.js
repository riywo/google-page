(function() {
  var GoogleStrategy, NedbStore, express, googlePage, passport, path;

  express = require("express");

  path = require("path");

  passport = require("passport");

  GoogleStrategy = require("passport-google").Strategy;

  NedbStore = require("connect-nedb-session")(express);

  googlePage = function(dir, store, config) {
    var app, csrf, ensureAuthenticated;
    if (!dir) {
      throw new Error("dir is required");
    }
    app = express();
    app.set("views", path.join(__dirname, "..", "views"));
    app.set("view engine", "jade");
    app.set("base_url", config.base_url || "http://google-page.dev");
    app.set("gmail_domain", config.gmail_domain || "gmail.com");
    app.set("session_secret", config.session_secret || "secret string");
    app.configure('development', function() {
      var edt;
      edt = require('express-debug');
      return edt(app, {
        depth: 10
      });
    });
    passport.use(new GoogleStrategy({
      returnURL: app.get("base_url") + "/auth/return",
      realm: app.get("base_url")
    }, function(identifier, profile, done) {
      return process.nextTick(function() {
        profile.idnetifier = identifier;
        if (profile.emails[0].value.match(RegExp("@" + app.get("gmail_domain") + "$"))) {
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
      secret: app.get("session_secret"),
      store: new NedbStore({
        filename: store
      })
    }));
    app.use(express.csrf());
    app.use(passport.initialize());
    app.use(passport.session());
    app.use(app.router);
    app.use(express["static"](path.join(__dirname, "..", "public")));
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
      return res.sendfile(dir + req.params[0]);
    });
    return app;
  };

  exports.app = function(dir, store, config) {
    config = config || {};
    return new googlePage(dir, store, config);
  };

}).call(this);
