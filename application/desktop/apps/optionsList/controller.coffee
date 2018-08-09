buzzlike.controller 'optionsListCtrl', ($scope, localization) ->

    defaultSettings =
        cancelButton: true

    settings = {}

    rawOptions = null

    $scope.state = 
        showed: false
        options: []
        selected: 0
        text: ''

    confirmState =
        'noMenu': 'inherit'
        'hideRight': 'inherit'
        'enter': () ->
            callActive()
        'left': () ->
            $scope.state.selected--
            if $scope.state.selected < 0 then $scope.state.selected = $scope.state.options.length - 1
        'right': () ->
            $scope.state.selected++
            if $scope.state.selected > $scope.state.options.length - 1 then $scope.state.selected = 0
        'escape': () ->
            for action,i in $scope.state.options
                if action.class?.indexOf('cancel') > -1
                    $scope.callAction i
                    return
            close()

    $scope.stateTree.applyState confirmState


    close = () ->
        $scope.closeApp()

    init = (message, options, newSettings) ->
        updateObject settings, defaultSettings, newSettings

        $scope.state.text = $scope.state.realText = $scope.state.description = ''

        if typeof message == 'object'
            $scope.state.text = message.phrase if message.phrase
            $scope.state.realText = message.realText if message.realText
            $scope.state.description = message.description

        else if typeof message == 'string' or typeof message == 'number'
            $scope.state.text = ''+message

        else return false

        $scope.state.selected = 0
        $scope.state.options.length = 0
        rawOptions = options
        for option in options
            if option.check?
                if !option.check()
                    continue
            $scope.state.options.push option

        if settings.cancelButton
            $scope.state.options.push
                text: 79
                action: () -> true
                class: 'cancel'

        $scope.state.showed = true
        # stateManager.applyState confirmState

    $scope.checkOptions = checkOptions = () ->
        $scope.state.selected = 0
        $scope.state.options.length = 0
        for option in rawOptions
            if option.check?
                if !option.check()
                    continue
            $scope.state.options.push option

        if settings.cancelButton
            $scope.state.options.push
                text: 79
                action: () -> true
                class: 'cancel'

    callActive = () ->
        close()
        if $scope.state.options[$scope.state.selected]?
            $scope.state.options[$scope.state.selected].action?()

    $scope.select = (index) ->
        $scope.state.selected = index

    $scope.callAction = (index) ->
        $scope.state.selected = index
        callActive()
        true

    init $scope.session.message, $scope.session.options, $scope.session.newSettings

    true