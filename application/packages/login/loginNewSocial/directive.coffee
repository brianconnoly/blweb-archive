*deps: loginService

scope.state =
    rulesAccepted: false

scope.doLogin = ->
    loginService.newSocial()