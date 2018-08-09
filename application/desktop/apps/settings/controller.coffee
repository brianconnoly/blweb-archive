buzzlike.controller 'settingsCtrl', (notificationCenter, timezone, $scope, $rootScope, confirmBox, account, desktopService, browserPopup, localization, localStorageService, env) ->

    $scope.session.expandedHeader = false

    $scope.stateTree.applyState
        'escape': $scope.stepBack

    $scope.sections = [
        'personal'
        'accounts'
        'appearance'
        'billing'
        'other'
    ]

    $scope.state =
        currentSection: $scope.session.section or $scope.sections[0]

    process = $scope.progress.add()
    account.update ->
        $scope.progress.finish process
        $scope.$apply()

    $scope.user = account.user

    #
    # States
    #

    $scope.canGoBack = -> $scope.stepStack.indexOf($scope.currentStep) > 1
    $scope.stepBack = ->
        if $scope.stepStack.length > 0
            $scope.stepStack.pop()
            $scope.currentStep = $scope.stepStack[$scope.stepStack.length - 1]
            $scope.state.currentSection = $scope.currentStep.section

    $scope.stepStack = []
    $scope.currentStep = 
        translateTitle: 'settingsApp_title'

    $scope.stepStack.push $scope.currentStep

    $scope.currentStep =
        translateTitle: 'settingsApp_' + $scope.state.currentSection
        section: $scope.state.currentSection

    $scope.stepStack.push $scope.currentStep

    $scope.selectSection = (section) ->
        $scope.state.currentSection = section

        if $scope.stepStack.length > 1
            $scope.stepStack.splice 1, $scope.stepStack.length - 1

        $scope.currentStep =
            translateTitle: 'settingsApp_' + $scope.state.currentSection
            section: $scope.state.currentSection
        $scope.stepStack.push $scope.currentStep
        true

    $scope.selectSublevel = (section) ->
        $scope.state.currentSection = section

        $scope.currentStep =
            translateTitle: 'settingsApp_' + $scope.state.currentSection
            section: $scope.state.currentSection
        $scope.stepStack.push $scope.currentStep

    $scope.onJumpStep = (step) ->
        if $scope.stepStack.indexOf(step) == 0
            $scope.currentStep = $scope.stepStack[1]

        $scope.state.currentSection = $scope.currentStep.section

    #
    # State saver
    #

    $scope.stateSaver.add 'stepStack', ->
        # Saver
        stack: $scope.stepStack
        current: $scope.stepStack.indexOf($scope.currentStep)
    , (data) ->
        $scope.stepStack.length = 0
        # Loader
        for step in data.stack
            $scope.stepStack.push step

        $scope.currentStep = $scope.stepStack[data.current*1]
        $scope.state.currentSection = $scope.currentStep.section

    $scope.$watch 'currentStep', (nVal) ->
        $scope.stateSaver.save()

    #
    # General settings
    #

    $scope.passwords =
        first: ""
        second: ""

    $scope.setOptions = () ->
        process = $scope.progress.add()
        account.set
            firstName: $scope.user.firstName
            lastName: $scope.user.lastName
            name: joinStrings [$scope.user.firstName, $scope.user.lastName]
            settings: $scope.user.settings
            timezone: $scope.user.timezone
        , ->
            $scope.progress.finish process

    $scope.setUserEmail = () ->
        process = $scope.progress.add()
        account.set 
            changeLogin: true
            newLogin: $scope.user.login
        , ->
            $scope.progress.finish process


    $scope.setUserData = () ->
        newUser =
            registered: $scope.user.registered
            password: $scope.passwords.password
            login: $scope.user.currentLogin

        # change password
        if $scope.passwords.first.length>=6 and $scope.passwords.first==$scope.passwords.second #and $scope.passwords.password
            newUser.changePassword = true
            newUser.newPassword = $scope.passwords.first
            $scope.passwords.first = $scope.passwords.second = ''

        if !$scope.user.registered
            if $scope.user.login != $scope.user.currentLogin
                newUser.changeLogin = true
                newUser.newLogin = $scope.user.login
                $scope.passwords.first = $scope.passwords.second = ''

        process = $scope.progress.add()
        account.set newUser, ->
            $scope.progress.finish process

        $scope.passwords.password = ''

    $scope.needCurrentPassword = ->
        if !$scope.user.registered then return false
        #if $scope.user.login != $scope.user.currentLogin then return true
        if $scope.passwords.first then return true
        false

    $scope.showNotConfirmed = ->
        if !$scope.user.registered
            if $scope.user.login != $scope.user.currentLogin then return false
            return true
        false

    $scope.resendConfirm = ->
        process = $scope.progress.add()
        rpc.call 'user.resendEmail',
            firstName: $scope.user.firstName
            login: $scope.user.login
        , (err) ->
            $scope.progress.finish process

            if err then return notificationCenter.addMessage err

            notificationCenter.addMessage
                text: 'userOptions_notify_resend'
            $scope.showNotConfirmed = false

    # Language

    $scope.langList = localization.getLangList()
    $scope.lang = localization.getLang()

    # Подставляем в select выбранный язык при открывании настроек пользователя
    $scope.langParams =
        selectedLang: ''
    if localStorageService.get 'user.lang'
        $scope.langParams.selectedLang = localStorageService.get 'user.lang'
    else
        localStorageService.add 'user.lang', 'ru'
        $scope.langParams.selectedLang = 'ru'

    $scope.getSelectedLang = ->
        for i in $scope.langList
            if $scope.langParams.selectedLang == i.value then return i.title

    # Обновляем язык интерфейса и сохраняем его в local storage
    $scope.updateLang = (val) ->
        $scope.langParams.selectedLang = val || $scope.langParams.selectedLang
        localStorageService.add 'user.lang', $scope.langParams.selectedLang
        localization.setLang $scope.langParams.selectedLang
        localization.getFreshList(true)

    $scope.setTimezone = ->
        $scope.setOptions()
        timezone.setTimezone $scope.user.timezone

    # Timezones stuff

    $scope.timezonesList = []
    list = timezone.getTimezoneList().timezonelist
    for item in list
        $scope.timezonesList.push
            title: item.utc + ' ' + item.title
            value: item.value

    #
    # Account settings
    #

    $scope.detachAccount = (account, e) ->
        e.stopPropagation()

        confirmBox.init localization.translate(140), () ->
            process = $scope.progress.add()
            rpc.call 'social.detachAccount',
                id: $scope.user.id
                publicId: account.publicId
                socialNetwork: account.socialNetwork
            , (data) ->
                $scope.progress.finish process
                if data > 0
                    removeElementFromArray account, $scope.user.accounts

    $scope.updateAccount = (acc) ->
        url = env.baseurl + 'auth/snupdate/' + acc.socialNetwork +
            '?sid=' + localStorageService.get('sid') +
            '&publicId=' + acc.publicId +
            '&hash=' + Date.now()

        loginPage = location.origin + '/static/login.html'
        popup = browserPopup.open loginPage, localization.translate('userOptions_updateAccount')
        popup.redirectURL = url
        popup.color = $rootScope.networksData[acc.socialNetwork].background

        statuses =
            'UPDATE_OK': ->
                account.update()
                body = $(popup.document.body)
                body.html templateCache["/static/accountUnlocked"]
                body.find('#name').html acc.name
                body.find("button").click -> popup.close()
                setTimeout ->
                    popup.close()
                , 300000
            'WRONG_ACCOUNT': ->
                account.update()
                body = $(popup.document.body)
                body.html templateCache["/static/wrongAccount"]
                body.find("button").click -> popup.close()
                setTimeout ->
                    popup.close()
                , 30000
            'FAIL': ->
                account.update()
                body = $(popup.document.body)
                body.html templateCache["/static/updateFail"]
                body.find("button").click -> popup.close()
                setTimeout ->
                    popup.close()
                , 30000

        if popup
            browserPopup.waitResponse popup, statuses, (status) ->
                if status != 'UPDATE_OK' then acc.enabled = false
                $scope.$apply()
        else
            acc.enabled = false

    $scope.addAccount = (sn) ->
        url = env.baseurl + 'auth/snadd/' + sn + '?sid=' + localStorageService.get('sid') + '&hash=' + Date.now()
        loginPage = location.origin + '/static/login.html'
        popup = browserPopup.open loginPage, localization.translate('userOptions_addAccount')
        popup.redirectURL = url
        popup.color = $rootScope.networksData[sn].background

        statuses =
            'ADD_OK': ->
                account.update ->
                    $scope.$apply()
                popup.close()
            'MERGED': ->
                account.update ->
                    $scope.$apply()
                body = $(popup.document.body)
                body.html templateCache["/static/userMerged"]
                body.find("button").click -> popup.close()
                setTimeout ->
                    popup.close()
                , 30000
            'LINKED': ->
                body = $(popup.document.body)
                body.html templateCache["/static/alreadyLinked"]
                body.find("button").click -> popup.close()
                setTimeout ->
                    popup.close()
                , 30000
            'LINKED_HERE': ->
                body = $(popup.document.body)
                body.html templateCache["/static/alreadyLinkedHere"]
                body.find("button").click -> popup.close()
                setTimeout ->
                    popup.close()
                , 30000

        browserPopup.waitResponse popup, statuses
        #tutorialService.nextLesson('addaccount', [2])

    $scope.changeAccEnabled = (acc) ->
        if !acc.enabled
            process = $scope.progress.add()
            rpc.call 'social.disableAccount',
                publicId: acc.publicId
                socialNetwork: acc.socialNetwork
            , (result) ->
                $scope.progress.finish process
                if !result then acc.enabled = true
                # throw message
                $scope.$apply()
        else
            $scope.updateAccount acc

    #
    # Appearance settings
    #

    $scope.solidColors = [
            title: 'Dark grey'
            value: '#5f5f5f'
        ,
            title: 'Light grey'
            value: '#919191'
        ,
            title: 'Green'
            value: '#59867b'
        ,
            title: 'Light blue'
            value: '#537fb7'
        ,
            title: 'Dark blue'
            value: '#446998'
        ,
            title: 'Grey'
            value: '#8E8E93'
        ,
            title: 'Pink'
            value: '#dfdaf1'
    ]

    $scope.desktopSettings =
        color: desktopService.activeDesktop.background
        wallpaper: null

    $scope.setBackground = (color) ->
        $scope.desktopSettings.color = color
        desktopService.activeDesktop.background = color
        account.user.settings.wallpaperSettings =
            wallpaper: $scope.desktopSettings?.wallpaper
            color: color
        account.set
            settings: account.user.settings

    $scope.setWallpaper = (id) ->
        $scope.desktopSettings?.wallpaper = id
        desktopService.setWallpaper id
        account.user.settings.wallpaperSettings =
            wallpaper: $scope.desktopSettings?.wallpaper
            color: account.user.settings.wallpaperSettings?.color or '#537fb7'
        account.set
            settings: account.user.settings

    #
    # User wallpapers
    #
    $scope.removeWallpaper = (id) ->
        removeElementFromArray id, $scope.user.wallpapers

        process = $scope.progress.add()
        account.set
            wallpapers: $scope.user.wallpapers
        , ->
            $scope.progress.finish process

    #
    # Billing
    #

    # Billing settings
    $scope.prolongSumm = 50
    $scope.chargeList = [
        value: 50
        amount: 50
    ,
        value: 300
        amount: 300
    ,
        value: 900
        amount: 900
    ,
        value: '?'
        amount: 0
    ]

    $scope.prolongList = [
        value: 1  * 30
        amount: 600
    ,
        value: 3  * 30
        amount: 1500
    ,
        value: 6  * 30
        amount: 2500
    ,
        value: 12 * 30
        amount: 4800
    ]

    $scope.charge = (item) ->
        account.Charge.checkAmount item.amount
        true

    $scope.prolong = (item) ->
        account.Prolong.checkAmount item, () ->
            true
        true

    min = $scope.min = account.Charge.min
    max = $scope.max = account.Charge.max

    $scope.current = (amount) ->
        min <= amount <= max

    $scope.check = (amount) ->
        if $scope.current(amount)
            account.Charge.checkAmount amount

    true

buzzlike.directive "enterUpdate", () ->
    restrict: 'A'
    require: 'ngModel'
    link: (scope, elem, attrs, ngModelCtrl) ->
        elem.bind "keyup", (e) ->
            if e.keyCode == 13
                ngModelCtrl.$commitViewValue()