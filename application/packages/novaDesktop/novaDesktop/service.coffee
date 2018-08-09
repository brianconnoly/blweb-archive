*deps: socketAuth, localStorageService

getIntersect = (app, rect) ->
    Math.max(0, Math.min(app.position.x + app.size.width,rect.x2) - Math.max(app.position.x,rect.x1)) * Math.max(0, Math.min(app.position.y + app.size.height,rect.y2) - Math.max(app.position.y,rect.y1))

class novaDesktop

    constructor: (@code, data) ->
        @byItem = {}
        @apps = []
        try
            storedApps = JSON.parse localStorageService.get 'novaDesktop_' + @code + '_' + socketAuth.session.user_id
        catch e
            true

        if storedApps?.length > 0
            for app in storedApps
                @launchApp app

        @appCnt = 0
        true

    close: ->
        localStorageService.remove 'novaDesktop_' + @code + '_' + socketAuth.session.user_id
        @destroy()

    destroy: ->
        @apps.length = 0
        true

    saveState: ->
        toSave = []
        for session in @apps
            if session.noSave != true
                toSave.push
                    id: session.id
                    app: session.app
                    item: session.item
                    index: session.index
        localStorageService.add 'novaDesktop_' + @code + '_' + socketAuth.session.user_id, JSON.stringify(toSave)

    activate: (session, newData) ->
        $(':focus').blur()
        # Index stuff
        toSort = []
        for appSession in @apps
            if session == appSession
                continue
            toSort.push appSession

        toSort.sort (a,b) ->
            if a.index > b.index
                return 1
            if a.index < b.index
                return -1
            0

        for appSession,i in toSort
            appSession.index = i

        session.index = toSort.length + 1

        desktopService.activateSession session
        session.run newData if newData?
        @saveState()

    launchApp: (session, cb) =>
        # Process item-sessions
        if session.item?.id?
            # Search sessions with item
            if desktopService.itemSessions[session.item.type + ':' + session.item.id]?
                existedSession = desktopService.itemSessions[session.item.type + ':' + session.item.id]
                @activate existedSession, session
                cb? existedSession
                return existedSession

        session.id = '' + @code + Date.now() + session.app + @appCnt++ if !session.id?
        @apps.push session
        desktopService.registerSession session
        @activate session if !session.index?
        @saveState()
        cb? session
        session

    closeApp: (session, cb) ->
        desktopService.unregisterSession session
        removeElementFromArray session, @apps
        @saveState()
        cb?()

    getFreePosition: (session) ->
        body = $ '.novaDesktop'
        bodyWid = body.width()
        bodyHei = body.height()

        rectWid = (bodyWid / 2)
        rectHei = (bodyHei / 2)

        defaultMargin = 30

        rects = [
            name: 'topleft'
            size: 0
            rect:
                x1: 0
                y1: 0
                x2: rectWid
                y2: rectHei
            position:
                left: defaultMargin
                top: defaultMargin
        ,
            name: 'topright'
            size: 0
            rect:
                x1: rectWid
                y1: 0
                x2: bodyWid
                y2: rectHei
            position:
                top: defaultMargin
                right: defaultMargin
        ,
            name: 'botleft'
            size: 0
            rect:
                x1: 0
                y1: rectHei
                x2: rectWid
                y2: bodyHei
            position:
                left: defaultMargin
                bottom: defaultMargin
        ,
            name: 'botright'
            size: 0
            rect:
                x1: rectWid
                y1: rectHei
                x2: bodyWid
                y2: bodyHei
            position:
                bottom: defaultMargin
                right: defaultMargin
        ,
            name: 'center'
            size: 0
            rect:
                x1: rectWid / 2
                y1: rectHei / 2
                x2: (rectWid / 2) + rectWid
                y2: (rectHei / 2) + rectHei
            position:
                centerWid: true
                centerHei: true
        ,
            name: 'centerTop'
            size: 0
            rect:
                x1: rectWid / 2
                y1: 0
                x2: rectWid / 2 + rectWid
                y2: rectHei
            position:
                centerWid: true
                top: defaultMargin
        ,
            name: 'centerBottom'
            size: 0
            rect:
                x1: rectWid / 2
                y1: rectHei
                x2: rectWid / 2 + rectWid
                y2: bodyHei
            position:
                centerWid: true
                bottom: defaultMargin
        ,
            name: 'leftCenter'
            size: 0
            rect:
                x1: 0
                y1: rectHei / 2
                x2: rectWid
                y2: rectHei / 2 + rectHei
            position:
                centerHei: true
                left: defaultMargin
        ,
            name: 'rightCenter'
            size: 0
            rect:
                x1: rectWid
                y1: rectHei / 2
                x2: bodyWid
                y2: rectHei / 2 + rectHei
            position:
                centerHei: true
                right: defaultMargin
        ]

        for app in @apps
            if !app.position?.x? or app == session
                continue
            for rect in rects
                rect.size += getIntersect app, rect.rect

        min = null
        for rect in rects
            if !min? or rect.size < min.size
                min = rect

        if min.position.top?
            session.position.y = min.position.top

        if min.position.left?
            session.position.x = min.position.left

        if min.position.right?
            session.position.x = bodyWid - min.position.right - session.size.width

        if min.position.bottom?
            session.position.y = bodyHei - min.position.bottom - session.size.height

        if min.position.centerWid
            session.position.x = rectWid - (session.size.width / 2)

        if min.position.centerHei
            session.position.y = rectHei - (session.size.height / 2)

        session.position.x += getRandomInt -30, 30
        session.position.y += getRandomInt -30, 30

class novaDesktopService

    constructor: ->
        @activeSession = null
        @launchers = {}
        @itemSessions = {}
        @sessions = []
        @desktops = {}

        # socketAuth.onAuth =>
        #     @registerLauncher
        #         static: true
        #         dock: true
        #         order: 0
        #         item:
        #             type: 'user'
        #             id: socketAuth.session.user_id
        #         app: 'novaProfileApp'

        socketAuth.onLogout =>
            @flush()

    registerLauncher: (data) ->
        itemCode = data.item.type + ':' + data.item.id
        data.id = itemCode
        @launchers[itemCode] = data

        # Check launched session
        if @itemSessions[itemCode]?
            @launchers[itemCode].session = @itemSessions[itemCode]
            removeElementFromArray @itemSessions[itemCode], @sessions

        @launchers[itemCode]

    unregisterLauncher: (data) ->
        itemCode = data.item.type + ':' + data.item.id
        data.id = itemCode


        if @itemSessions[itemCode]?
            @getDesktop().closeApp @itemSessions[itemCode]

        if @launchers[itemCode]?.session?
            @getDesktop().closeApp @launchers[itemCode].session

        delete @launchers[itemCode]
        true

    registerSession: (session) ->
        itemCode = session.item?.type + ':' + session.item?.id
        @itemSessions[itemCode] = session
        if @launchers[itemCode]?
            @launchers[itemCode].session = session
        else
            @sessions.push session

    unregisterSession: (session) ->
        itemCode = session.item?.type + ':' + session.item?.id
        delete @itemSessions[itemCode] if @itemSessions[itemCode]?
        if @launchers[itemCode]?
            delete @launchers[itemCode].session if @launchers[itemCode].session?
        else
            removeElementFromArray session, @sessions

    isActive: (session) ->
        if @activeSession == null
            return false
        @activeSession == session

    activateSession: (session) ->
        @activeSession = session
        session.activated?()

    activate: (session) ->
        # TODO: Find session desktop
        @getDesktop().activate session

    flush: ->
        for k,desktop of @desktops
            desktop.destroy()
            delete @desktops[k]

        @activeSession = null
        emptyObject @launchers
        emptyObject @itemSessions
        emptyObject @desktops
        @sessions.length = 0

    createDesktop: (code = 0, data) ->
        @desktops[code] = new novaDesktop code, data

    getDesktop: (code = 0) ->
        if !@desktops[code]?
            @createDesktop code
        @desktops[code]

    init: ->
        # Clear current desktops
        @flush()

        # Load info from locaStorage
        try
            desktopsData = JSON.parse localStorageService.get 'novaDesktops_' + socketAuth.session.user_id
        catch e
            desktopsData = []

        for id in desktopsData
            @createDesktop id

    launchApp: (data, cb) ->
        # TODO: Pick active desktop
        for k,v of @desktops
            v.launchApp data, cb
            return

desktopService = new novaDesktopService()
desktopService
