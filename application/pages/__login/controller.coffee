buzzlike
    .controller 'LoginCtrl', ($scope, $rootScope, stateManager, socketAuth, notificationCenter) ->

        $scope.fVersion = window.frontVersion
        # $rootScope.setBg 'login'

        stateManager.applyState
            enter: 'default'
            name: 'login'
            noMenu: true
            hideRight: true

        $scope.screen = 'default'
        $scope.mode = 'default'

        $scope.agreementsUrl = location.origin + '/static/terms_ru.html .html-content'

        # Forget -----------------------
        $scope.noUser = false
        timeoutHandler = null
        $scope.sendedForget = false
        $scope.$watch 'login', (nVal) ->
            if nVal?.length > 0
                if timeoutHandler?
                    clearTimeout timeoutHandler

                timeoutHandler = setTimeout ->
                    if $scope.login?.length > 0
                        rpc.call 'auth.isLoginAvailable', $scope.login, (res) ->
                            $scope.sendedForget = false
                            if res.err and res.code == 108 
                                $scope.noUser = true
                            else
                                $scope.noUser = false
                        , true
                , 200

        $scope.forgetPassword = ->
            if $scope.login
                $scope.sendedForget = true
                rpc.call 'user.forgotPass', $scope.login.toLowerCase(), (res) ->
                    if !res.err
                        notificationCenter.addMessage
                            text: 'register_forget_watch_email'
                    else 
                        $scope.error = res.err

        # Mode switcher -----------------
        $scope.showRules = () ->
            if $scope.mode != 'text'
                $scope.mode = 'text'

                stateManager.applyState
                    child: true
                    'escape': -> 
                        $scope.mode = 'default'
                        stateManager.goBack()

            true

        # Show buzz login ---------------
        $scope.buzzLogin = false
        $scope.showForm = -> 
            $scope.buzzLogin = true

            $('.loginInput input').focus()

            stateManager.applyState
                child: true
                'escape': -> 
                    $scope.buzzLogin = false
                    stateManager.goBack()

            true

        $scope.backToSocial = ->
            stateManager.faderClick()
            true

        # Show buzz registration ---------------
        $scope.buzzReg = false
        $scope.goRegistration = ->
            $scope.buzzReg = true

            $('.loginInput input').focus()

            stateManager.applyState
                child: true
                'escape': -> 
                    $('.loginInput input').focus()
                    
                    $scope.buzzReg = false
                    stateManager.goBack()

            true

        # Hide password --------------
        $scope.passHidden = false
        $scope.switchPasswordView = ->
            $scope.passHidden = !$scope.passHidden
            true

        # Check rules -----------------
        $scope.rulesAccepted = false
        $scope.checkRulesAccepted = ->
            $scope.rulesAccepted = !$scope.rulesAccepted
            true

        # Actions -----
        $scope.doLogin = (cb) ->
            if $scope.login && $scope.password
                socketAuth.authBuzzlike
                    login: $scope.login.toLowerCase()
                    password: $scope.password
                , (result) ->
                    if result.err == true
                        console.log 'Auth error:', result
                        return false

                    cb? result
        
        $scope.canRegister = -> $scope.login?.length > 0 and $scope.password?.length >= 6 and $scope.rulesAccepted == true
        $scope.doRegister = ->
            if $scope.canRegister()

                rpc.call 'auth.register',
                    login: $scope.login.toLowerCase()
                    password: $scope.password
                , ->
                    $scope.doLogin()

            true

        $scope.doRegisterSocial = ->
            if $scope.rulesAccepted == true
                rpc.call 'auth.registerGuestSN', {}, (err) ->
                    if !err then socketAuth.fetchSession()

        $scope.doMerge = (acc) ->
            if $scope.login && $scope.password
                $scope.doLogin (user) ->
                    rpc.call 'social.addAccountToUser', {acc}, (account) ->
                        # $scope.user.accounts.push account
                        socketAuth.fetchSession()

        true

    .directive 'colorRotator', () ->
        restrict: 'C'
        link: (scope, element, attrs) ->

            scope.$on '$destroy', ->
                clearInterval intervalHandler

            elem = $ element

            prev = null
            currentColor = getRandomInt 0, 3

            nextColor = ->
                if prev?
                    elem.removeClass prev

                currentColor++
                if currentColor > 3
                    currentColor = 1

                prev = 'color' + currentColor
                elem.addClass prev

            intervalHandler = setInterval nextColor, 15000
            nextColor()


    true