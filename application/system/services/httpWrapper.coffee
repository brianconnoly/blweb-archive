buzzlike.factory 'httpWrapped', ($http, $injector, $rootScope, notificationCenter, localization) ->
    # request contains
    # required method, url
    # optional data, responseHandler, noResponseHandler, ignoreResponseHandler, httpErrorHandler,
    # serverErrorHandler, errorHandler name
    ts = 0
    sync = false

    isResult = (data) ->
        if !data?
            return false
        if data.length == 0
            return false
        return true

    send = (request) ->
        console.log 'log invalid request!!!', request.url
        return
        $http({
            method: request.method
            url: request.url
            async: !sync
            data:request.data
            withCredentials: true
        })
            .success (data) ->
                if data.err
                    notificationCenter.addMessage
                        error: true
                        realText: localization.translate('httpwrapped_servererror') + ': ' + data.err.text

                    console.log('server error', request, data.err)
                    request.serverErrorHandler? data.err
                    request.errorHandler? data.err
                    return
                else
                    request.anyDataResponseHandler? data.data, data.total
                if isResult(data.data)
                    request.responseHandler? data.data, data.total
                else
                    request.noResponseHandler?()
                request.ignoreResponseHandler?()
            .error  (error, status, headers) ->
                if status == 403
                    route = request.url.split 'back/'
                    route = route[1]

                    notificationCenter.addMessage
                        error: true
                        realText: localization.translate('access_error') + ': ' + route

                    return

                if status == 401
                    cur = new Date().getTime()
                    if Math.abs(cur-ts) > 5 * 60 * 1000
                        notificationCenter.addMessage
                            error: true
                            realText: localization.translate('httpwrapped_sessionend')

                        user = $injector.get 'user'
                        $rootScope.clearData()
                        user.logout()

                    ts = new Date().getTime()
                    return

                # [TODO:] Parse errors
                route = request.url.split 'back/'
                route = route[1]

                notificationCenter.addMessage
                    error: true
                    realText: localization.translate('httpwrapped_httperror') + ': ' + route + '<br>' + status + '<br>' + error.errCode + ': ' + error.errText

                console.log('http error', request, error, status)

                request.httpErrorHandler? error
                request.errorHandler? error

    getByRequest = (request) ->
        request['method'] = 'GET'
        send(request)

    getByUrlHandler = (url, handler) ->
        send({
            method : 'GET'
            url : url
            anyDataResponseHandler : handler
        })

    postByRequest = (request) ->
        request['method'] = 'POST'
        send(request)

    postByUrlDataHandler = (url,data,handler) ->
        send({
            method : 'POST'
            url : url
            data : data
            anyDataResponseHandler : handler
        })

    putByRequest = (request) ->
        request['method'] = 'PUT'
        send(request)

    putByUrlDataHandler = (url,data,handler) ->
        send({
            method : 'PUT'
            url : url
            data : data
            anyDataResponseHandler : handler
        })

    deleteByRequest = (request) ->
        request['method'] = 'DELETE'
        send(request)

    deleteByUrlHandler = (url, handler) ->
        send({
            method : 'DELETE'
            url : url
            ignoreResponseHandler : handler
        })

    deleteByData = (url, data, handler) ->
        send({
            method : 'DELETE'
            url : url
            data : data
            ignoreResponseHandler : handler
        })

    send : send
    get : (arg1, arg2, Sync) ->
        sync = !!Sync || false
        if arg1.url
            getByRequest(arg1)
        else
            getByUrlHandler(arg1, arg2)

    post : (arg1, arg2, arg3, Sync) ->
        sync = !!Sync || false
        if arg1.url
            postByRequest(arg1)
        else
            postByUrlDataHandler(arg1, arg2, arg3)

    put : (arg1, arg2, arg3, Sync) ->
        sync = !!Sync || false
        if arg1.url
            putByRequest(arg1)
        else
            putByUrlDataHandler(arg1, arg2, arg3)

    delete : (arg1, arg2, Sync) ->
        sync = !!Sync || false
        if arg1.url
            deleteByRequest arg1
        else
            deleteByUrlHandler arg1, arg2
    deleteByData : deleteByData

