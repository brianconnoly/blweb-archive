*deps: rpc, loginService, notificationCenter, localStorageService
*scope: true
*replace: true

elem = $ element

# Directive state
scope.state = state =
    # Login credentials
    login: ""
    password: ""
    rulesAccepted: false
    # Check if login available
    canLogin: true
    canForget: false
    canRegister: false

scope.$watch ->
    loginService.state.mode
, (nVal) ->
    if nVal == 'blLogin'
        $('input.login').focus()

scope.$watch 'state.canLogin', (nVal) ->
    if $('input:focus').hasClass 'pass'
        setTimeout ->
            $('input.pass:visible').focus()
        , 0

scope.loginChanged = ->
    scope.showHelperLogins = false
    if scope.state.login?.length > 0
        scope.showHelperLogins = true

        no107 = false
        for login in scope.helperLogins
            if login.indexOf(scope.state.login) > -1
                no107 = true

        rpc.call
            method: 'auth.isLoginAvailable'
            data: scope.state.login
            error: (res) ->
                scope.state.canForget = false
                scope.state.canLogin = true
                if res?.code == 108
                    scope.state.canForget = true
                    scope.state.canLogin = true
                    return false
                if res?.code == 107 and no107
                    scope.state.canForget = false
                    scope.state.canLogin = true
                    return false
                true
            success: (res) ->
                if res == true
                    scope.state.canLogin = false
                    scope.state.canForget = false

scope.backToSocial = ->
    loginService.state.mode = 'default'

scope.doLogin = ->
    notificationCenter.messages.length = 0

    if state.canLogin
        # Try Login
        # if !state.canForget
        #     notificationCenter.addMessage
        #         text: 'rpc_error_107'
        #         error: true
        #     return

        if state.password.length < 6
            notificationCenter.addMessage
                text: 'rpc_error_105'
                error: true
            return

        addHelperLogin state.login
        loginService.auth state, null, elem.parents('.newSocial').length > 0

    else
        # Try Register
        if state.password.length < 6
            notificationCenter.addMessage
                text: 'rpc_error_105'
                error: true
            return

        if !state.rulesAccepted
            notificationCenter.addMessage
                text: 'bl_register_accept_rules'
                error: true
            return

        addHelperLogin state.login
        loginService.register state, null, elem.parents('.newSocial').length > 0

scope.forgetPassword = ->
    if scope.state.login
        scope.state.canForget = false
        rpc.call
            method: 'user.forgotPass'
            data: state.login.toLowerCase()
            success: (res) ->
                notificationCenter.addMessage
                    text: 'register_forget_watch_email'

# Login helpers
try
    scope.helperLogins = JSON.parse localStorageService.get 'helperLogins'
catch
    scope.helperLogins = []

if !scope.helperLogins?.length?
    scope.helperLogins = []

scope.showHelperLogins = false
scope.setHelperLogin = (login) ->
    state.login = login
    scope.loginChanged()
    scope.showHelperLogins = false

addHelperLogin = (login) ->
    if login not in scope.helperLogins
        scope.helperLogins.push login
        localStorageService.add 'helperLogins', JSON.stringify scope.helperLogins

scope.removeHelperLogin = (login, e) ->
    removeElementFromArray login, scope.helperLogins
    localStorageService.add 'helperLogins', JSON.stringify scope.helperLogins
    e.stopPropagation()
    e.preventDefault()
