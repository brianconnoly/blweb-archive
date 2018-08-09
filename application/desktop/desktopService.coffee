buzzlike.service 'desktopService', (socketAuth, appsService, localStorageService, actionsService) ->

    class desktopService

        constructor: () ->
            @stateLoaded = false

            @showMenu = false
            @desktops = []
            @activeDesktop = null

            # actionsService.registerAction
            #     sourceType: 'desktop'
            #     phrase: 'close'
            #     action: (data) =>
            #         for item in data.items
            #             @closeDesktop item

            actionsService.registerParser 'desktop', (item) =>
                result = []
                if item == @activeDesktop
                    result.push 'activeDesktop'
                result

            socketAuth.onLogout =>
                @purge()

        purge: ->
            @stateLoaded = false
            for desktop in @desktops
                @closeDesktop desktop, true

        newDesktop: (params) ->
            if @desktops.length > 1
                return @desktops[0]

            newDesktop =
                type: 'desktop'
                sessions: []
                background: 'lightBlue' # 'green'
                wallpaper: coreSettings?.wallpapers?[0] # "548dca5e9af5d58423695855"

            updateObject newDesktop, params

            @desktops.push newDesktop

            @selectDesktop newDesktop
            @saveState()
            newDesktop

        closeDesktop: (desktop, noSave = false) ->
            for session in desktop.sessions
                appsService.close session, noSave

            removeElementFromArray desktop, @desktops
            if !noSave then @saveState()

        selectDesktop: (desktop) ->
            if @activeDesktop != desktop
                appsService.launchSessions desktop.sessions
                @activeDesktop = desktop

        saveState: () ->
            if !@stateLoaded
                return

            toSave = []
            for desktop in @desktops
                toSaveDesktop = 
                    sessions: []
                    background: desktop.background
                    wallpaper: desktop?.wallpaper

                for session in desktop.sessions
                    if session.noSave == true
                        continue
                    # saveSession = {}
                    # for k,v of session
                    #     if k not in ['scope', 'element']
                    #         saveSession[k] = v
                    toSaveDesktop.sessions.push 
                        id: session.id # saveSession
                        app: session.app
                        zIndex: session.zIndex
                        active: session == appsService.activeSession

                toSaveDesktop.sessions.sort (a,b) ->
                    if a.zIndex > b.zIndex then return 1
                    if a.zIndex > b.zIndex then return -1
                    return 0

                toSave.push toSaveDesktop

            str = JSON.stringify toSave

            localStorageService.add 'desktops' + socketAuth.session.user_id, str

        loadState: () ->
            str = localStorageService.get 'desktops' + socketAuth.session.user_id
            data = JSON.parse str

            if data?.length?
                for desktop in data
                    @newDesktop
                        background: desktop.background
                        wallpaper: desktop?.wallpaper

                    for session in desktop.sessions
                        appsService.launchApp session.app, session
            else
                @newDesktop()

            @stateLoaded = true

        launchApp: (app, params, e, no_flush = false) ->
            session = appsService.launchApp app, params, e, no_flush
            @saveState()
            session

        init: () ->
            appsService.flush()
            # Load from storage
            @loadState()

        setWallpaper: (id) ->
            # @wallpaperLoaded = false
            @activeDesktop?.wallpaper = id
            @saveState()

    new desktopService()