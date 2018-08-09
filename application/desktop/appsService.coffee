buzzlike.service 'appsService', (rpc, socketAuth, multiselect, $compile, $rootScope, actionsService, dragMaster, stateManager, localStorageService) ->

    class StateTree

        constructor: ->
            @showed = false
            @stack = []
            @activeState = null

            @handler = null

        applyState: (state) ->
            if @activeState?
                @stack.push @activeState

            @activeState = state

        goBack: ->
            @activeState = @stack.pop()

    class Progress

        constructor: (@scope) ->
            @stack = []
            @done = 0

        flush: ->
            clearTimeout @handler
            for task in @stack
                @finish task

        add: ->
            if @handler != null
                clearTimeout @handler
                @handler = null

            newProcess = {}
            @stack.push newProcess
            @done = (80 ) * 100 / (@stack.length * 100) #+ (@stack.length * 20)
            @showed = true
            newProcess

        finish: (process) ->
            removeElementFromArray process, @stack
            @done = 80 * 100 / (@stack.length * 100)
            if @stack.length == 0
                @done = 100

                if @handler == null
                    @handler = setTimeout =>
                        @showed = false
                        @scope.$apply()
                    , 1000

    class StateSaver

        constructor: (@sessionId) ->
            if !@sessionId?
                @sessionId = Date.now() + '' + getRandomInt(0,1000)
            @handlers = {}

            blob = localStorageService.get 'appState_' + @sessionId
            if blob?
                @initData = JSON.parse blob

        destroy: ->
            localStorageService.remove 'appState_' + @sessionId

        add: (code, saver, loader) ->
            @handlers[code] =
                saver: saver
                loader: loader
                code: code

            if @initData?[code]?
                @handlers[code].loader @initData?[code]

        remove: (code) ->
            delete @handlers[code] if @handlers[code]?

        save: () ->
            blob = {}
            for k,obj of @handlers
                blob[k] = obj.saver()

            localStorageService.add 'appState_' + @sessionId, JSON.stringify(blob)

        load: () ->
            blob = localStorageService.get 'appState_' + @sessionId
            blobData = JSON.parse blob

            for k,data of blobData
                @handlers?[k]?.load? data

    class itemClass

        launchedApps = 0
        lastAppCoord = 20
        lastZindex = 0

        constructor: ->
            @apps = {}
            @sessions = []
            @activeSession = null

            @desktop = null
            @appsFrame = null
            @desktopService = null

            @body = $ 'body'

            actionsService.registerAction
                sourceType: 'session'
                phrase: 'close'
                action: (data) ->
                    for session in data.items
                        session.scope.closeApp()

        #     socketAuth.onLogout =>
        #         @purge()

        # purge: ->
        #     for session in @sessions
        #         @close session, true

        desktopResized: ->
            desktop = $ 'div#desktop'
            desktopHei = desktop.height()
            desktopWid = desktop.width()

            for session in @sessions
                if session.maximized == true
                    session.scope.setWidth desktopWid
                    session.scope.setHeight desktopHei

                    session.element.css
                        width: 'auto'
                        height: 'auto'

                    session.scope.resized desktopWid, desktopHei

        setDesktopService: (service) ->
            @desktop = null
            @appsFrame = null
            @desktopService = service

        launchApp: (appId, params, e, no_flush = false) ->
            if !@apps[appId]?
                console.log 'Unknown application', appId
                return

            launchedApps++
            appData = angular.copy @apps[appId]
            
            lastAppCoord += 20
            if @desktop? and lastAppCoord > @desktop.width() / 3
                lastAppCoord = 20

            newSession = 
                no_flush: no_flush
                id: params?.id or Date.now() + '' + launchedApps
                type: 'session'
                app: appId
                stateVars: {}
                coords: 
                    x: lastAppCoord
                    y: lastAppCoord
                size: 
                    width: 600
                    height: 500

            updateObject newSession, appData
            updateObject newSession, params

            desktop = $ 'div#desktop'
            desktopHei = desktop.height()
            desktopWid = desktop.width()

            if newSession.startPosition == 'center'
                newSession.coords.x = (desktopWid - newSession.size.width) / 2 | 0
                newSession.coords.y = (desktopHei - (newSession.size.height | 0) ) / 3 | 0
                delete newSession.startPosition

            if newSession.startPosition == 'cursor' and e?
                newSession.coords.x = e.clientX + 20
                newSession.coords.y = e.clientY + 20

            if newSession.size.width > desktopWid
                newSession.coords.x = 0
                newSession.size.height = desktopWid

            if newSession.coords.y + newSession.size.height > desktopHei
                newSession.coords.y = desktopHei - newSession.size.height

            if newSession.coords.y < 0
                newSession.coords.y = 0

            if newSession.size.height > desktopHei
                newSession.coords.y = 0
                newSession.size.height = desktopHei

            if newSession.coords.x + newSession.size.width > desktopWid
                newSession.coords.x = desktopWid - newSession.size.width

            if !@appsFrame?
                @appsFrame = $('#applications')

            newScope = $rootScope.$new()
            newScope.session = newSession

            # Progress indicator
            newScope.progress = new Progress newScope
            errorFlush = rpc.registerErrorFlush ->
                newScope.progress.flush()

            newScope.stateSaver = new StateSaver newSession.id
            newScope.stateSaver.add 'session', ->
                # save
                toSave = {}
                for k,v of newScope.session
                    if k not in ['scope', 'element']
                        toSave[k] = angular.copy v

                toSave
            , (data) ->
                # load
                for k,v of data
                    newScope.session[k] = v

            newScope.stateTree = new StateTree()
            newScope.closeApp = (result) =>
                rpc.clearErrorFlush errorFlush
                
                for handler in closeHandlers
                    handler result
                @close newSession

            closeHandlers = []
            newScope.onClose = (handler) ->
                closeHandlers.push handler

            newScope.hideApp = =>
                @hide newSession

            resizeHandlers = []
            newScope.onResize = (handler, fire = true) ->
                if fire == true
                    handler newSession.size.width, newSession.size.height
                resizeHandlers.push handler

            newScope.resized = (wid, hei) ->
                for handler in resizeHandlers
                    handler wid, hei

            resizeProgressHandlers = []
            newScope.onResizeProgress = (handler, fire = true) ->
                if fire == true
                    handler newSession.size.width, newSession.size.height
                resizeProgressHandlers.push handler
                
            newScope.resizeInProgress = (wid, hei) ->
                for handler in resizeProgressHandlers
                    handler wid, hei

            jElem = $('<div class="appLauncher"></div>')
            newScope.window = jElem[0]

            newScope.maximize = () =>
                if newSession.maximized != true
                    desktopHei = desktop.height()
                    desktopWid = desktop.width()

                    newSession.ex =
                        coords: angular.copy newSession.coords
                        size: angular.copy newSession.size

                    newScope.setPosition 0, 0
                    newScope.setWidth desktopWid
                    newScope.setHeight desktopHei

                    newScope.element.css
                        top: 0
                        left: 0
                        right: 0
                        bottom: 0
                        width: 'auto'
                        height: 'auto'
                        transform: 'none'

                    newSession.maximized = true
                else
                    newScope.setPosition newSession.ex.coords.x, newSession.ex.coords.y
                    newScope.setWidth newSession.ex.size.width
                    newScope.setHeight newSession.ex.size.height

                    newSession.maximized = false

                newScope.resized newScope.session.size.width, newScope.session.size.height
                # @desktopService.saveState()
                newScope.stateSaver.save()
                true

            newScope.setWidth = (wid) ->
                newScope.session.size.width = wid
                if newScope.session.size.minWidth? and newScope.session.size.width < newScope.session.size.minWidth
                    newScope.session.size.width = newScope.session.size.minWidth
                if newScope.session.size.maxWidth? and newScope.session.size.width > newScope.session.size.maxWidth
                    newScope.session.size.width = newScope.session.size.maxWidth
                jElem.width newScope.session.size.width

            newScope.setHeight = (hei, force = false) ->
                newScope.session.size.height = hei
                if force 
                    if newScope.session.size.minHeight? then newScope.session.size.minHeight = hei
                    if newScope.session.size.maxHeight? then newScope.session.size.maxHeight = hei

                if newScope.session.size.minHeight? and newScope.session.size.height < newScope.session.size.minHeight
                    newScope.session.size.height = newScope.session.size.minHeight
                if newScope.session.size.maxHeight? and newScope.session.size.height > newScope.session.size.maxHeight
                    newScope.session.size.height = newScope.session.size.maxHeight
                jElem.height newScope.session.size.height

            newScope.setPosition = (x,y) ->
                y = -10 if y < -10
                jElem.css 'transform', 'translate3d(' + x + 'px,' + y + 'px, 0)'
                newScope.session.coords = 
                    x: x
                    y: y

            template = $compile(jElem)(newScope)
            $(template).on 'mousedown.blApp', (e) =>
                # if newSession != @activeSession
                e.stopPropagation()
                @activate newSession
                newScope.$apply()

            handler = null
            jElem.on 'mouseenter.blApp', (e) =>
                if dragMaster.dragInProgress() and e.which == 1
                    handler = setTimeout =>
                        @activate newSession
                        newScope.$apply()
                    , 200

            jElem.on 'mouseleave.blApp', (e) =>
                if handler?
                    clearTimeout handler
                    handler = null

            newSession.scope = newScope
            newSession.element = template

            @appsFrame.append newSession.element

            @sessions.push newSession
            @activate newSession, no_flush

            newScope.stateSaver.save()
            
            newSession

        activate: (session, no_flush = false) ->
            if session.minimized
                session.minimized = false
                @appsFrame.append session.element

            if session.maximized
                session.scope.element.css
                    top: 0
                    left: 0
                    right: 0
                    bottom: 0
                    width: 'auto'
                    height: 'auto'
                    transform: 'none'
                
            if session != @activeSession
                multiselect.flush() if !no_flush and !session.no_flush
                lastZindex++
                $('.appLauncher.active').removeClass 'active'
                session.element.addClass 'active'
                session.element.css 'z-index', lastZindex
                session.zIndex = lastZindex
                @activeSession = session

                index = @sessions.indexOf session
                @sessions.move index, @sessions.length - 1

                stateManager.setTree session.scope.stateTree

                @desktopService?.saveState()

        flushActive: ->
            @activeSession = null
            $('.appLauncher.active').removeClass 'active'
            stateManager.clearTree()
            true

        launchSessions: (sessions) ->
            for session in @sessions
                session.element.detach()
            @sessions = sessions

            for session in @sessions
                @appsFrame.append session.element

        flush: () ->
            for session in @sessions
                session.scope.$destroy()
                session.element.remove()
            @sessions.length = 0
            @activeSession = null

        close: (session, noSave = false) ->
            if !session? or session.destroyed == true
                return 
            
            # Show anim
            jElemDestopy = $(session.element)
            jElemDestopy.addClass('hideAnimationStart')
            setTimeout =>
                jElemDestopy[0].style.transform += ' scale(0.9)'
                jElemDestopy.addClass('hideAnimation')
                setTimeout =>
                    
                    session.element.remove()

                    if @sessions[@sessions.length-1]?
                        @activate @sessions[@sessions.length-1], session.no_flush
                    if !noSave then @desktopService?.saveState()

                , 500
            , 0

            # Do destroy
            session.destroyed = true
            session.scope.stateSaver.destroy()
            session.scope.$destroy()
            removeElementFromArray session, @sessions

            

        hide: (session) ->
            session.minimized = true
            session.element.detach()
            true

        registerApp: (app) ->
            @apps[app.app] = app
            true

    new itemClass()
