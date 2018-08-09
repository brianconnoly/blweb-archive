buzzlike.service 'rpc', (socketService, $rootScope, notificationCenter) ->

    callId = 0
    cbsStack = {}
    anywayStack = {}
    errorStack = {}
    
    progressStack = {}

    showErr = {}

    debug = 1

    handler = null

    socketService.on 'rpcAnswer', (pack) ->
        blog pack.callId, 'RPC answ', pack.data if debug == 1

        if pack.data?.err == true
            if showErr[pack.callId] == true
                delete showErr[pack.callId]
                cbsStack[pack.callId]? pack.data
            else
                notificationCenter.addMessage
                    text: 'rpc_error_' + pack.data.code
                    error: if pack.data.code == 4 then false else true

                # cbsStack[pack.callId]?()
                for k,handler of flushHandlers
                    handler()
        else
            cbsStack[pack.callId]? pack.data

        delete cbsStack[pack.callId]

        progressStack[pack.callId].value = 100
        notificationCenter.updateStatus progressStack[pack.callId]

        $rootScope.$applyAsync()
        true

    call = (method, data, cb, forceErrResult) ->
        progress = notificationCenter.registerProgress true

        if typeof data == 'function'
            cb = data
            data = {}

        if forceErrResult or data?.showErrors == true
            showErr[callId] = true

        pack =
            callId: callId
            method: method
            data: data || {}

        #if callId>20 then return
        progressStack[callId] = progress
        cbsStack[callId] = cb if cb
        callId = 0 if callId > 1000
        socketService.emit 'rpcCall', pack

        blog pack.callId, 'RPC call', method, data if debug == 1

        callId++

    cnt = 0
    flushHandlers = {}
    registerErrorFlush = (handler) ->
        flushHandlers[cnt] = handler

    clearErrorFlush = (code) ->
        delete flushHandlers[code] if flushHandlers[code]?

    {
        call

        registerErrorFlush
        clearErrorFlush
    }




