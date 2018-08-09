NwflwCtrl = (inviteTeamMember, teamService, teamManager, notificationCenter, requestService, lotService, combEdit, socketAuth, resize, tableImport, dragMaster, surveyService, account, overlayManager, touchHelper, optionsList, stateManager, multiselect, contentService, postService, env, httpWrapped, confirmBox, calendar, $state, $rootScope, $scope, $compile, user, uploadService, buffer, combService, notificationService, localization, tutorialService) ->
    # Const
    

    # ---
    $scope.dragMaster = dragMaster
    $scope.user = account.user

    $scope.unreadNotifications = notificationService.unread

    overlayManager.init()
    rpTimer = null
    rpLoaded = false


    # Team stuff
    $scope.showTeamManager = () ->
        teamManager.open()
    
    $scope.teamNews = 0
    $rootScope.$watch ->
        teamService.storage
    , (nVal) ->
        $scope.teamNews = 0
        for k,team of nVal
            if team?.members?.length > 0
                for user in team.members
                    if user.userId == account.user.id and user.roles?.invited == true
                        $scope.teamNews++
        true
    , true

    $rootScope.newRequests = 0
    $rootScope.$watch ->
        lotService.my
    , (nVal) ->
        $rootScope.newRequests = 0
        for k,lot of nVal
            $rootScope.newRequests += lot.requestsNew
    , true

    $rootScope.returned = 0
    $rootScope.$watch ->
        requestService.requestsFrom
    , (nVal) ->
        $rootScope.returned = 0
        for k,req of nVal
            if req.unread == true and req.requestStatus == 'returned'
                $rootScope.returned++
    , true

    $scope.showOptions = () ->
        overlayManager.loadOverlay 'userOptions'
        true

    $scope.navigation = [
            state: 'timeline'
        ,
            state: 'combs'
        ,
            state: 'content'
        ,
            state: 'market'
    ]

    $scope.multiselectState = multiselect.state

    $scope.notificationState = notificationCenter.status
    $scope.touchState = touchHelper.state
    $scope.animPrefs = user.animPrefs

    $scope.localization = localization

    #$scope.isRightShown = selectionService.isAnythingSelected
    $scope.showedPanels = resize.showedPanels

    $scope.isRightShownAlways = () ->
        if account.user.settings?
            account.user.settings.rightPanel
        else
            true

    $scope.isCurrentState = (state) ->
        if $state.current.name == state then return true
        false

    $scope.showAddPanel = () ->

        if !tutorialService.lockAction 'addcommunity_plus'
            return false

        tutorialService.nextLesson('all', [1])
        overlayManager.loadOverlay 'addWindow'

        true

    $scope.isSettingsShowed = () ->
        $rootScope.settingsShowed

    $scope.isOverlayShowed = -> overlayManager.state.showed

    $scope.isBlurUsed = ->
        $scope.isOverlayShowed()

    $scope.go = (where, e) ->

        if !tutorialService.lockAction 'switchpage_'+where
            return false

        if combEdit.state.currentComb? and (e.ctrlKey or e.metaKey)
            buffer.addItems [combEdit.state.currentComb]

        multiselect.state.context = null

        if $state.current.name == where
            stateManager.faderClick()
            return false

        calendar.hide()
        window.goUp = null

        $state.transitionTo where

        if tutorialService.status.currentCourse?
            tutorialService.switchTransitLesson(where)

        tutorialService.nextLesson('quickcreatepost', [2])
        tutorialService.nextLesson('quickcreatepostfolder', [2])

    $scope.logout = () ->
        confirmBox.init
            phrase: 'popup_exit_title'
            description: 'popup_exit_subtitle'
            yes: localization.translate('popup_exit_confirm')
            no: localization.translate('morework')
        , () ->
            socketAuth.logout()


    $scope.goUp = () ->
        stateManager.faderClick()

    tutorial = null
    tutorialState =
        'escape': () ->
            #console.log angular.element(tutorial).scope()
            true

    $scope.showTutorial = () ->
        tutorial = $compile('<div class="selectcourse shader"></div>')($scope)
        $('.main-wrapper').append tutorial
        angular.element($('.tutorialcourse')).scope().cancelLesson()
        true

    $scope.showMarket = () ->
        if $('.requestsManager').length == 0
            overlayManager.loadOverlay 'requestsManager'

    # Multi file uploader by dialog
    $('.uploadHelper input').on 'change', (e) ->
        uploadService.upload @, true
        $(@).val ''

    # CSV / XLS import
    $('#importFullHelper').on 'change', (e) ->
        tableImport.uploadFull @
        $(@).val ''

    $('#importCommunityHelper').on 'change', (e) ->
        tableImport.uploadCommunity @
        $(@).val ''

    # Show loading spinner
    spinnerOptions =
        lines: 13
        length: 20
        width: 2
        radius: 30
        corners: 1
        rotate: 0
        direction: 1
        color: '#000'
        speed: 1
        trail: 66
        shadow: true
        hwaccel: true
        className: 'spinner'
        zIndex: 2e9

    target = $('#big_loading').children('.spinner')
    spinner = new Spinner(spinnerOptions).spin(target[0])

    $scope.paymentRequired = false

    $scope.showPaymentRequired = (e) ->
        if $scope.user.id == -1
            return

        if !$scope.user.daysRemain or $scope.user.daysRemain > 3
            return

        ###
        if $scope.user.daysRemain <= 3
            nav = $ "#nav"
            nav.addClass('paymentRequired').css('background-color', '')
            color = 'rgba(222,47,47,0.9)'
            if color
                color = getColor color
                color.g += daysRemain*33  #чем меньше, тем краснее
                nav.css 'background-color', makeRGBA color
        ###

        if e?.target.id == 'nav'
            daysRemain = $scope.user.daysRemain
            days = daysRemain+' '+localization.declension daysRemain, 'paymentRequire_days'

            if daysRemain > 0
                text = localization.translate('paymentRequire').replace('%s', days)
            else
                text = localization.translate('paymentRequire_blocked')

            message =
                realText: text

            optionsList.init message, [
                {
                    text: 'paymentRequire_charge'
                    action: ->
                        overlayManager.loadOverlay 'paymentInfo'
                }
            ]
            true

    $scope.showPaymentRequired()

    account.onAuthed () ->
        if $scope.user.statsShowed
            $scope.user.statsShowed = false
            surveyService.loadStats()
        true


