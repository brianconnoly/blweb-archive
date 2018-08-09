LoginCtrl = (socketAuth, account, overlayManager, socketService, $scope, $rootScope, user, $location, $state, stateManager, contentService, combService, env, $http, properties, localStorageService) ->
    $scope.password = ''
    $scope.password2 = ''
    $scope.user = account.user
    $scope.error = ''
    #$scope.status = ''
    $scope.screen = 'login'
    $scope.popup = ''

    $scope.login = (cb) ->
        #$scope.isEmptyLogForm()
        if $scope.user.login && $scope.password
            socketAuth.authBuzzlike
                login: $scope.user.login.toLowerCase()
                password: $scope.password
            , (result) ->
                if result.err == true
                    console.log 'Auth error:', result
                    return false

                cb? result

    $scope.checkMailReadyToRedirect = ->
        allowed = [
            'mail.ru', 'bk.ru',
            'yandex.ru', 'ya.ru',
            'rambler.ru',
            'google.com', 'gmail.com'
        ]
        domain = $scope.username.split('@')[1] if $scope.username?.indexOf("@")+1
        if allowed.indexOf(domain)+1 then true else false

    $scope.showAgreements = () ->
        overlayManager.loadOverlay 'agreements'

    socketService.on 'authResult', (data) -> true
    #    switch data.status
    #        when 'new-social'
    #            $scope.screen = data.status
    #            $scope.user.login = data.account.login
    #            $scope.$apply()
    #            $scope.snAccount = data.account

    $scope.newSnAccountStatus = 'enabled'
    $scope.newSnAccount = () ->
        rpc.call 'auth.registerGuestSN', {}, (err) ->
            if !err then socketAuth.fetchSession()

    $scope.loginAndAddNewAccount = (acc) ->
        $scope.login (user) ->
            rpc.call 'social.addAccountToUser', {acc}, (account) ->
                $scope.user.accounts.push account

    $scope.isLoginAvailable = (cb) ->
        errCode = 'forgot'
        if $scope.user.login
            rpc.call 'auth.isLoginAvailable', $scope.user.login, (res) ->
                if !res
                    $scope.error = errCode
                    return #cb? false
                if $scope.error == errCode
                    $scope.error = ''
                cb? true
        else
            cb? true

    $scope.isLoginAvailableLog = (cb) -> # особая проверка имейла на экране логина
        errCode = 'loginFree'
        if $scope.user.login
            rpc.call 'auth.isLoginAvailable', $scope.user.login, (res) ->
                if res
                    $scope.error = errCode
                    return #cb? false
                if $scope.error == errCode
                    $scope.error = ''
                cb? true
        else
            cb? true

    $scope.checkPassword = ->
        if $scope.error not in ['forgot', 'loginFree']
            $scope.error = do ->
                if !$scope.password then return 'emptyPassword'
                if $scope.password.length<6 then return 'shortPassword'
                if $scope.password2 && $scope.password != $scope.password2 then return 'passwordsNotEqual'
                ''
        return !$scope.error

    $scope.showRegScreen = () ->
        regScreen = ->
            $scope.screen = 'register'
            setTimeout -> # apply already in progress
                document.forms.registerForm.login.focus()
            , 0

        if $scope.user.login
            $scope.isLoginAvailable regScreen
        else regScreen()
        true

    $scope.validRegForm = ->
        if !$scope.login or !$scope.password then return false
        if $scope.checkPassword()
            return $scope.agree

    $scope.register = ->
        rpc.call 'auth.register',
            firstName: $scope.user.firstName
            lastName: $scope.user.lastName
            login: $scope.user.login.toLowerCase()
            password: $scope.password

        $scope.screen = 'register-confirm'
        $scope.password = $scope.password2 = ''

    $scope.endRegistration = -> $scope.screen = 'login'

    $scope.forgotPass = ->
        if $scope.user.login
            rpc.call 'user.forgotPass', $scope.user.login.toLowerCase()
            , (res) ->
                if !res.err
                    $scope.screen = 'login-forgot'
                else $scope.error = res.err # errors: loginFree,
        else
            $scope.error = 'emptyLogin'



    $scope.bVersion = "2.0.0a (hardcode)"
    $scope.fVersion = window.frontVersion