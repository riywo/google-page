express        = require "express"
fs             = require "fs"
path           = require "path"
passport       = require "passport"
GoogleStrategy = require("passport-google").Strategy
NedbStore      = require("connect-nedb-session")(express)

googlePage = (dir, store, config) ->
  throw new Error("Data dir('"+dir+"') doesn't exist") unless fs.existsSync(dir)
  try
    fs.openSync(store, "a")
  catch error
    throw new Error("Can't open store file('"+store+"'): "+error)
  config = config || {}

  app = express()

  app.set "views", path.join(__dirname, "..", "views")
  app.set "view engine", "jade"

  app.set "base_url",       config.base_url       or "http://google-page.dev"
  app.set "gmail_domain",   config.gmail_domain   or "gmail.com"
  app.set "session_secret", config.session_secret or "secret string"

  app.configure 'development', ->
    edt = require 'express-debug'
    edt app, { depth: 10 }

  passport.use(new GoogleStrategy {
    returnURL: app.get("base_url")+"/auth/return"
    realm:     app.get("base_url")
  }, (identifier, profile, done) ->
    process.nextTick ->
      profile.idnetifier = identifier
      if profile.emails[0].value.match RegExp("@"+app.get("gmail_domain")+"$")
        return done(null, profile)
      else
        return done(null, false)
  )
  passport.serializeUser (user, done) ->
    done(null, user)
  passport.deserializeUser (obj, done) ->
    done(null, obj)

  ensureAuthenticated = (req, res, next) ->
    return next() if req.isAuthenticated()
    req.session.request_path = req.path
    res.redirect "/login"

  csrf = (req, res, next) ->
    res.locals.token = req.session._csrf
    next()

  privateStatic = express.static(dir)

  errorHandling = (err, req, res, next) ->
    console.log "Error[" + req.url + "]: " + err
    res.redirect "/error"

  app.use express.favicon()
  app.use express.logger("dev")
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.cookieParser()
  app.use express.session
    secret: app.get("session_secret")
    store:
      new NedbStore
        filename: store
  app.use express.csrf()
  app.use passport.initialize()
  app.use passport.session()
  app.use app.router
  app.use errorHandling

  app.get "/", csrf, (req,res) ->
    res.render "index",
      base_url: app.get("base_url")
      is_auth:  req.isAuthenticated()
      email:    req.session.passport.user.emails[0].value if req.isAuthenticated()

  app.get "/login", passport.authenticate('google'), (req, res) ->
    res.redirect "/"

  app.get "/auth/return", passport.authenticate('google', { failureRedirect: "/error" }), (req, res) ->
    path = "/"
    if req.session.request_path
      path = req.session.request_path
      delete req.session.request_path
    res.redirect path

  app.post "/logout", csrf, (req, res) ->
    req.logout()
    res.redirect "/"

  app.get "/error", (req, res) ->
    res.status 500
    res.send "Error"

  app.get "*", ensureAuthenticated, (req, res, next) ->
    privateStatic(req, res, next)

  return app

exports.app = (dir, store, config) ->
  return new googlePage(dir, store, config)
