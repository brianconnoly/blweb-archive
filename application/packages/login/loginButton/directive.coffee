*deps: browserPopup, loginService
*replace: true

scope.doAuth = ->
    loginService.doLogin scope.item.type