express  = require "express"
path     = require "path"
nedb     = require("connect-nedb-session")(express)

passport       = require "passport"
GoogleStrategy = require("passport-google").Strategy

app = express()

app.set "port", process.env.PORT or 3000
app.set "views", path.join(__dirname, "..", "views")
app.set "view engine", "jade"

app.set "schema",         if process.env.SECPAGE_SSL == "1" then "https" else "http"      
app.set "server",         process.env.SECPAGE_SERVER         or "google-page.dev"
app.set "gmail domain",   process.env.SECPAGE_GMAIL_DOMAIN   or "gmail.com"
app.set "session secret", process.env.SECPAGE_SESSION_SECRET or "secret string"
app.set "private dir",    process.env.SECPAGE_PRIVATE_DIR    or path.join(__dirname, "..", "private")

app.configure 'development', ->
  edt = require 'express-debug'
  edt app, { depth: 10 }

passport.use(new GoogleStrategy {
  returnURL: app.get("schema")+"://"+app.get("server")+"/auth/return"
  realm: app.get("schema")+"://"+app.get("server")
}, (identifier, profile, done) ->
  process.nextTick ->
    profile.idnetifier = identifier
    if profile.emails[0].value.match RegExp("@"+app.get("gmail domain")+"$")
      return done(null, profile)
    else
      return done(null, false, {message: "error"})
)
passport.serializeUser (user, done) ->
  done(null, user)
passport.deserializeUser (obj, done) ->
  done(null, obj)

ensureAuthenticated = (req, res, next) ->
  return next() if req.isAuthenticated()
  req.session.request_path = req.path
  res.redirect '/login'

csrf = (req, res, next) ->
  res.locals_csrf = req.session._csfr
  next()

app.use express.favicon()
app.use express.logger("dev")
app.use express.bodyParser()
app.use express.methodOverride()
app.use express.cookieParser()
app.use express.session
  secret: app.get("session secret")
  key: "secpagesession"
  store: new nedb
    filename: path.join(__dirname, "..", app.get("env")+".nedb")
app.use express.csrf()
app.use passport.initialize()
app.use passport.session()
app.use app.router
app.use express.static(__dirname + '/public')
app.use express.errorHandler() if "development" is app.get("env")

app.get "/", csrf, (req,res) ->
  res.render "index",
    title: "Express"
    is_auth: req.isAuthenticated()
    token: req.session._csrf

app.get "/login", passport.authenticate('google'), (req, res) ->
  res.redirect '/'

app.get "/auth/return", passport.authenticate('google'), (req, res) ->
  path = "/"
  if req.session.request_path
    path = req.session.request_path
    delete req.session.request_path
  res.redirect path

app.post '/logout', csrf, (req, res) ->
  req.logout()
  res.redirect '/'

app.get /(^\/.+$)/, ensureAuthenticated, (req, res) ->
  res.sendfile app.get("private dir") + req.params[0]

module.exports = app
