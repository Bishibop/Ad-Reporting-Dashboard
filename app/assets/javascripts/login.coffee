# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
clientID = 'kO0tWhIUJshfIB37j9fN15XrOPRIo8De'
domain = 'bishibop.auth0.com'

lock = new Auth0LockPasswordless(clientID, domain)

lock.magiclink(
  callbackURL: 'https://ad-reports-staging.herokuapp.com/auth/auth0/callback',
  authParams:
    scope: 'openid email'
  closable: false
  primaryColor: "#00AEEF"
  icon: '/assets/netsearch-logo-small.png'
  gravatar: false
  dict:
    title: "Reporting Dashboard Login"
    email:
      headerText: "Enter your email address below, and we will send you a link to sign into your dashboard."
    emailSent:
      success: "We've emailed you a link to sign into your dashboard. Check your inbox at {email} to find it."
)
