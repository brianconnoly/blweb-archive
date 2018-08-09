*deps: socketService, $rootScope, notificationCenter

# Call counter
callId = 0

# Possible callbacks
callbacks = {}

# Progress for notification center
progressStack = {}

# Legacy showErr
showErr = {}
debug = 1

# RPC Answer event
socketService.on 'rpcAnswer', (pack) ->
    blog '↓ ' + pack.callId, pack.data if debug == 1

    # Handle error
    if pack.data?.err == true
        if !(typeof callbacks[pack.callId].error == 'function') or callbacks[pack.callId].error(pack.data)
            # Show notification center error if handler returned true
            notificationCenter.addMessage
                text: 'rpc_error_' + pack.data.code
                error: if pack.data.code == 4 then false else true

        for k,handler of flushHandlers
            handler()

    # Handler success
    else
        callbacks[pack.callId].success? pack.data

    # Anyway handler
    callbacks[pack.callId].anyway? pack.data

    # Clear handlers (!!!May be try to delete children!!!)
    delete callbacks[pack.callId]

    # Notification service progress
    progressStack[pack.callId].value = 100
    notificationCenter.updateStatus progressStack[pack.callId]

    # AngularJS Apply
    $rootScope.$applyAsync()
    true

# RPC Status event
socketService.on 'rpcStatus', (pack) ->
    blog '⇢' + pack.callId, pack.status, pack.progress + '%' if debug == 1
    callbacks[pack.callId]?.progress? pack.status, pack.progress
    # AngularJS Apply
    $rootScope.$applyAsync()
    true

socketService.onDisconnect ->
    for id,handlers of callbacks
        console.log id, handlers
        handlers.anyway? error 99999, 'Disconnected'
        handlers.error? error 99999, 'Disconnected'
        delete callbacks[id]

call = (method, data, cb, forceErrResult) ->
    # Notification service progress
    progress = notificationCenter.registerProgress true
    progressStack[callId] = progress

    # Simple call without data
    if typeof data == 'function'
        cb = data
        data = {}

    # Get stored callbacks
    storedCb = null
    if typeof method == 'object'
        callData = method

        method = callData.method
        data = callData.data or {}

        storedCb = {}
        if typeof callData.success == 'function'
            storedCb.success = callData.success
        if typeof callData.complete == 'function' # DEPRECATED, leaved for compatibility
            storedCb.success = callData.complete
        if typeof callData.error == 'function'
            storedCb.error = callData.error
        if typeof callData.anyway == 'function'
            storedCb.anyway = callData.anyway
        if typeof callData.progress == 'function'
            storedCb.progress = callData.progress
    else
        storedCb =
            success: cb

        # Legacy force error
        if forceErrResult or data?.showErrors == true
            storedCb.error = cb

    # Store callbacks
    callbacks[callId] = storedCb

    # Create transfer object
    pack =
        callId: callId
        method: method
        data: data || {}

    callId++
    callId = 0 if callId > 1000

    # Do API call
    socketService.emit 'rpcCall', pack
    blog '↑ ' + pack.callId, method, data if debug == 1

cnt = 0
flushHandlers = {}
registerErrorFlush = (handler) ->
    flushHandlers[cnt] = handler
    cnt++
clearErrorFlush = (code) ->
    delete flushHandlers[code] if flushHandlers[code]?

{
    call
    registerErrorFlush
    clearErrorFlush
}