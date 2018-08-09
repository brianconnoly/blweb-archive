buzzlike.service 'socketService', (env, localStorageService, $rootScope) ->
    socket = {}
    waitEmits = []
    waitOns = []

    onHandlers = {}

    connectCbs = []

    stored_sid = localStorageService.get 'sid'
    sid_validated = false

    state = 
        connected: false

    connected = false
    no_worker = true #navigator.userAgent.toLowerCase().indexOf('webkit') == -1 or navigator.userAgent.toLowerCase().indexOf('mobile') > -1

    if no_worker
        $.getScript env.baseurl + 'socket.io/socket.io.js', () ->
            socket = io env.baseurl,
                secure: true
                # transports: ['websocket']

            socket.on 'connect', () ->
                connected = true
                state.connected = true
                socket.emit 'uid', 'abc'

                for args in waitOns
                    socket.on args.event, args.cb
                waitOns.length = 0

                socket.emit 'sid', stored_sid
                $rootScope.$applyAsync()

            socket.on 'disconnect', ->
                connected = false
                state.connected = false
                disconnectHandler?()
                $rootScope.$applyAsync()

    firstConn = true

    if !no_worker
        socketWorker = new Worker '/workers/socket.js'
        socketWorker.onmessage = (e) ->
            if !e.data?
                return

            switch e.data.type
                when 'connection'
                    if firstConn == true
                        for e, handlers of onHandlers
                            socketWorker.postMessage
                                type: 'on'
                                event: e
                        firstConn = false

                    socketWorker.postMessage
                        type: 'emit'
                        event: 'sid'
                        data: stored_sid

                    connected = true

                when 'on'
                    if onHandlers[e.data.event]?
                        for handler in onHandlers[e.data.event]
                            handler e.data.data
                            true

    resetSid = ->
        localStorageService.remove 'sid'

        if !no_worker
            socketWorker.postMessage
                type: 'emit'
                event: 'sid'
                data: stored_sid
        else
            socket.emit 'sid', stored_sid

    if !no_worker
        socketWorker.postMessage
            type: 'baseurl'
            baseurl: env.baseurl

    onConnect = (cb) =>
        connectCbs.push cb if cb?
        if socket.connected
            cb()

    _on = (e, cb) ->
        if no_worker
            if !socket.connected
                waitOns.push 
                    event: e
                    cb: cb
            else
                socket.on e, cb

        else

            onHandlers[e] = [] if !onHandlers[e]?
            onHandlers[e].push cb if cb not in onHandlers[e]

            if connected
                socketWorker.postMessage
                    type: 'on'
                    event: e

    _emit = (e, data) ->
        if !connected or !sid_validated #!socket.connected
            blog "_emit", e, "puted in wait stack"
            waitEmits.push 
                event: e
                data: data
        else
            if no_worker
                socket.emit e, data
            else
                socketWorker.postMessage
                    type: 'emit'
                    event: e
                    data: data

    _on 'sid', (sid) ->
        console.log 'SID Recieved'
        localStorageService.add 'sid', sid
        stored_sid = sid
        sid_validated = true

        for args in waitEmits
            _emit args.event, args.data

        waitEmits.length = 0

        for method in connectCbs
            method()

    disconnectHandler = null
    onDisconnect = (handler) ->
        disconnectHandler = handler


    # _on 'expired', () ->
    #     resetSid()


    {
        state

        on: _on
        emit: _emit

        onConnect
        resetSid

        onDisconnect

    }

