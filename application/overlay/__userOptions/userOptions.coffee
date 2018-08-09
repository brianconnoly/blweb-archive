userOptionsCtrl = (overlayManager, tableImport, account, $scope, $rootScope, $state, user, env, res, confirmBox, httpWrapped, notificationCenter, $compile, localization, localStorageService, hintService, communityService, browserPopup, smartDate, timezone, infinityScroll, stateManager, tutorialService, surveyService) ->
    prefs = user.getAnimPrefs()
    $scope.liveWp = prefs.liveWp
    $scope.blurBg = prefs.blurBg
    $scope.turbo = prefs.turbo

    $scope.prefs = user.animPrefs

    $scope.hints = hintService.current.active

    $scope.timezoneList = timezone.getTimezoneList().timezonelist
    $scope.selectedtimezoneTitle = null
    $scope.lang = localization.getLang()
    $scope.langList = localization.getLangList()

    $scope.passwords =
        first: ""
        second: ""

    $scope.user = account.user

    menuAnimationDuration = 250

    stateManager.applyState
        'noMenu': true
        'hideRight': true
        'escape': () ->
            $rootScope.settingsShowed = false
            overlayManager.unloadOverlay 'userOptions'
            stateManager.goBack()

    account.update ->
        $scope.$apply()

    $rootScope.settingsShowed = true

    $scope.$watch () ->
        hintService.current
    , (nVal) ->
        $scope.hints = nVal.active
    , true

    # Добавляем языки по умолчанию, чтобы userOptions не ругался
    # не получилось там сделать $watch, т.к. ехала верстка скролла by Phil Situmorang
    $scope.languages = [
        {title: "Русский"
        value: "ru"
        active: 1}
        {title: "English"
        value: "en"
        active: 1}
        {title: "Українська"
        value: "ua"
        active: 1}
    ]
    # Добавляем языки с [active] - в котором указано доступен ли этот язык для локализации
    $rootScope.$watch 'languageslist', (newValue) ->
        if newValue?
            $scope.languages = $rootScope.languageslist
    , true

    # Подставляем в select выбранный язык при открывании настроек пользователя
    $scope.selectedLang = ''
    if localStorageService.get 'user.lang'
        $scope.selectedLang = localStorageService.get 'user.lang'
    else
        localStorageService.add 'user.lang', 'ru'
        $scope.selectedLang = 'ru'

    $scope.getSelectedLang = ->
        for i in $scope.langList
            if $scope.selectedLang == i.value then return i.title

    # Обновляем язык интерфейса и сохраняем его в local storage
    $scope.updateLang = (val) ->
        $scope.selectedLang = val || $scope.selectedLang
        localStorageService.add 'user.lang', $scope.selectedLang
        localization.setLang $scope.selectedLang
        localization.getFreshList(true)

        selectedTimezone()
        $scope.page "main"

    $scope.updateAnimPrefs = () ->
        if $scope.prefs.turbo == true
            $scope.prefs.blurBg = false
            $scope.prefs.snow = false

        #user.setLiveBg $scope.liveWp
        #user.setLiveBg false  #snow
        user.setBlur $scope.prefs.blurBg
        user.setTurbo $scope.prefs.turbo
        user.setSnow $scope.prefs.snow

    $scope.updateHintPref = () ->
        if $scope.hints
            hintService.turnOn()
        else
            hintService.turnOff()

    $scope.$watch 'user.accounts', (newValue) ->
        blockedAccounts = $scope.user.accounts.filter (acc) -> acc.blocked
        $scope.hasBlockedAccount = blockedAccounts.length > 0
    , true

    $scope.detachAccount = (account, e) ->
        e.stopPropagation()

        confirmBox.init localization.translate(140), () ->
            rpc.call 'social.detachAccount',
                id: $scope.user.id
                publicId: account.publicId
                socialNetwork: account.socialNetwork
            , (data) ->
                if data > 0
                    removeElementFromArray account, $scope.user.accounts

    $scope.setOptions = () ->
        account.set
            settings: $scope.user.settings
            timezone: $scope.user.timezone

    $scope.$on '$destroy', () ->
        stateManager.goBack()
        $rootScope.settingsShowed = false

        $scope.setOptions()

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

        account.set newUser

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
        rpc.call 'user.resendEmail',
            firstName: $scope.user.firstName
            login: $scope.user.login
        , (err) ->
            if err then return notificationCenter.addMessage err

            notificationCenter.addMessage
                text: 'userOptions_notify_resend'
            $scope.showNotConfirmed = false

    $scope.updateAccount = (acc) ->
        url = env.baseurl + 'auth/snupdate/' + acc.socialNetwork +
            '?sid=' + localStorageService.get('sid') +
            '&publicId=' + acc.publicId +
            '&hash=' + Date.now()

        loginPage = location.origin + '/static/login.html'
        popup = browserPopup.open loginPage, localization.translate('userOptions_updateAccount')
        popup.redirectURL = url

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
             rpc.call 'social.disableAccount',
                 publicId: acc.publicId
                 socialNetwork: acc.socialNetwork
             , (result) ->
                 if !result then acc.enabled = true
                 # throw message
                 $scope.$apply()
        else
            $scope.updateAccount acc


    $scope.selectTimezone = (val) ->
        $scope.user.timezone = val
        account.set {timezone: val}
        $scope.page "main"
        setTimeout ->
            timezone.setTimezone val
            selectedTimezone()
            $scope.$apply()
        , menuAnimationDuration

    selectedTimezone = ->
        for item in $scope.timezoneList
            if item.value == account.user.timezone
                $scope.selectedtimezoneTitle = item.utc + ' ' + item.title

    selectedTimezone()

    # switch pages
    $scope.page = (page) ->
        if page != 'main'
            state =
                'noMenu': true
                'hideRight': true
                'escape': () ->
                    $scope.page "main"
                    #stateManager.goBack()
            stateManager.applyState state
        else
            stateManager.goBack()

        $(".userOptions .page.visible").removeClass "visible"
        $(".userOptions").find("."+page).addClass "visible"
        true

    #account direction
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
        stateManager.faderClick()
        account.Prolong.checkAmount item, () ->
            true
        true


    #$scope.prolongMethod = ->
    #    stateManager.goRoot()
    #    overlayManager.unloadOverlay() #all
    #    overlayManager.loadOverlay 'paymentInfo'
    #    true

    $scope.showSurvey = ->
        surveyService.loadStats()
        true

    #other overlays
    $scope.tableImport = ->
        tableImport.open()
        true



