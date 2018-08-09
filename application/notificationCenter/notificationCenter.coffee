buzzlike.factory 'notificationCenter', ($rootScope, socketService, localization) ->

    tasks = []

    messages = []

    status =
        error: false
        progress: false
        wait: false

    updateProgressValue = () ->
        bar = $ '#topProgressBar'
        value = bar.children '.value'

        if tasks.length > 0
            bar.addClass 'active'
            val = tasks[0].value
            value.css
                'width': val + '%'
        else
            status.wait = false
            bar.removeClass 'active'

    init = () ->
        messages.length = 0

    registerProgress = (wait) ->
        newTasks =
            value: 0

        tasks.push newTasks

        if wait
            status.wait = true

        newTasks

    updateStatus = (bar) ->
        if bar.value == 100
            removeElementFromArray bar, tasks

        updateProgressValue()

    getTasks = () -> tasks

    addMessage = (msg) ->
        if msg.text and msg.data
            msg.realText = localization.decrypt msg.text, msg.data
            delete msg.text
            delete msg.data

        if !msg.notificationType?
            for message in messages
                if (msg.realText? and message.realText == msg.realText) or (msg.text? and message.text == msg.text)
                    return false

        if msg in messages
            return false

        messages.push msg

        time = msg.time or 3 * 1000

        if msg.notificationType?
            time = MIN

        if msg.time then time = msg.time

        if msg.error then time = 20 * 1000
        setTimeout () ->
            removeElementFromArray msg, messages
            $rootScope.$applyAsync()
        , time


    removeMessage = (msg) ->
        removeElementFromArray msg, messages

    error = () ->
        status.error = true

    socketService.on 'notify', (data) ->
        addMessage data
        $rootScope.$apply()

    socketService.on 'blog', (data) ->
        blog '=== BE blog ===\n'
        for i, c in data
            blog " ---- #{c} ----\n", i
        blog '\n==============='


    {
        status
        messages
        init

        registerProgress
        updateStatus
        getTasks

        error

        addMessage
        removeMessage
    }

buzzlike.directive 'notificationCenter', (notificationCenter, stateManager, notificationService) ->
    restrict: 'C'
    scope: true
    link: (scope, element, attrs) ->
        elem = $ element

        scope.spinnerShow = false
        scope.panelShown = false
        scope.tasks = notificationCenter.getTasks()
        scope.notificationStatus = notificationCenter.status
        scope.unread = notificationService.unread

        scope.$watch 'tasks', (nValue) ->
            if nValue.length > 0
                scope.spinnerShow = true
            else
                scope.spinnerShow = false
                scope.panelShow = false
        , true

        spinnerOptions =
            lines: 9
            length: 2
            width: 2
            radius: 8
            corners: 0
            rotate: 0
            direction: 1
            color: '#fff'
            speed: 1
            trail: 75
            shadow: false
            hwaccel: true
            className: 'spinner'
            zIndex: 2e9

        target = elem.find('.spinner')
        spinner = new Spinner(spinnerOptions).spin(target[0])

        scope.refresh = () ->
            location.reload()

        closePanel = () ->
            notificationCenter.status.panelShown = false
            stateManager.goBack()

        panelState =
            name: 'notificationState'
            'escape': closePanel

        scope.triggerPanel = () ->
            if scope.notificationStatus.error == true
                return

            if notificationCenter.status.panelShown == true
                #close
                stateManager.faderClick()
            else
                #show

                notificationCenter.status.panelShown = true
                stateManager.applyState panelState

            true

        true

buzzlike.directive 'notificationPanel', (desktopService, notificationCenter, notificationService, stateManager) ->
    restrict: 'C'
    scope: true
    link: (scope, element, attrs) ->
        scope.notificationStatus = notificationCenter.status
        scope.unread = notificationService.unread

        scope.hideAll = (e) ->
            e.preventDefault()
            e.stopPropagation()

            stateManager.faderClick()

            notificationService.markAllRead ->
                true

        scope.showAll = ->
            notificationService.markAllRead ->
                true
            desktopService.launchApp 'notificationViewer'
            stateManager.faderClick()


buzzlike.directive 'notificationItem', ($compile, notificationService) ->
    restrict: 'C'
    link: (scope, element, attrs) ->

        flag = ''
        if $(element).parents('.systemMessages').length > 0
            flag = 'systemmessage="true"'

        if $(element).parents('.notificationPanel').length > 0
            flag = 'unreadnotifications="true"'

        elem = $ element
        previewContainer = elem.children '.notificationPreview'

        scope.markRead =  ->
            notificationService.markRead scope.notification.id

        if scope.notification.notificationType?
            template = '<notification-' + scope.notification.notificationType + ' ' + flag + '>'

        if template?
            inner = $compile(template)(scope)
            previewContainer.append inner
