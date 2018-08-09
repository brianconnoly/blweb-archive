buzzlike.service 'operationsService', (socketService, rpc, $http, env, $rootScope, updateService, account) ->

    stackToRequest =
        operations: []
        cbs: []
        handler: null

    awaitingCallback = {}

    registeredActions = {}

    cnt = 0

    handler = null

    socketService.on 'operationsResponse', (result) ->
        blog 'operationsResult', result
        if typeof result == 'object'
            parseOperations [result]
        else
            parseOperations result

        if handler == null
            handler = setTimeout () ->
                $rootScope.$apply()
                handler = null
            , 500

    requestOperation = (data, cb) ->
        newKey = 'oK' + Date.now() + cnt
        cnt++

        operation =
            actionType: data.action
            entities: data.entities
            entityKey: newKey
            confirmed: data.confirmed || false

        if data.action == 'update'
            if data.entities[0].type == 'comb' or data.entities[0].type == 'post'
                data.entities[0].clientUpdated = Date.now()

        stackToRequest.operations.push operation
        stackToRequest.cbs.push cb if cb?

        if data.cb?
            awaitingCallback[newKey] = data.cb

        blog 'operation fire', data.action, if data.entities.length > 1 then data.entities else data.entities[0]
        rpc.call 'operations.request',
            actionType: data.action
            entities: data.entities
            entityKey: newKey
            confirmed: data.confirmed || false
        , (result) ->
            cb? result

        true

    parseOperations = (operations) ->
        for operation in operations
            operationParams =
                id: operation.entityId
                entity: operation.entity
                action: operation.action
                type: operation.entityType
                confirmCode: operation.confirmCode
                failCode: operation.failCode

            # if operation.action == 'update' and operationParams.entity.type == 'text' and operationParams.entity.patch?
            #     # if !lastPatch[operationParams.id]? or lastPatch[operationParams.id] < operationParams.entity.lastUpdate
            #     if !patches[operationParams.entity.id]?
            #         patches[operationParams.entity.id] = []
            #     patches[operationParams.entity.id].push operationParams.entity.patch

            entity = get operationParams.type, operationParams.id
            registeredActions[operation.entityType]?[operation.action]? operation.entityId, operationParams

            if operation.entityKey?
                awaitingCallback[operation.entityKey]? operation.entityId, registeredActions[operation.entityType].get(operation.entityId), operationParams

            # if operation.action in ['create','update']
            #     entity = get operationParams.type, operationParams.id
            # else
            #     entity =
            #         type: operationParams.type
            #         id: operationParams.id

            updateService.triggerUpdate [entity], operation.action

            #update schedule statuses
            refreshScheduleItem = (id) ->
                $('.sched_'+id).each (i, sched) ->
                    schedScope = angular.element(sched).scope().$$childHead
                    schedScope.refreshItem?()


            if operationParams.type == 'schedule' and operation.action == 'update'
                refreshScheduleItem operationParams.entity.id

            if operationParams.type == 'request' and operation.action == 'update'
                refreshScheduleItem operationParams.entity.scheduleId



    get = (type, id, cb) ->
        registeredActions[type]?.get id, cb

    getByIds = (type, ids, cb) ->
        registeredActions[type]?.getByIds ids, cb

    query = (type, query, cb) ->
        registeredActions[type]?.query query, cb

    call = (type, method, data, cb) ->
        registeredActions[type]?.call method, data, cb

    save = (type, item, cb) ->
        registeredActions[type]?.save item, cb

    registerAction = (action, typeStr, cb) ->
        arr = typeStr.split '/'
        if arr.length < 2
            arr = [typeStr]

        for type in arr
            registeredActions[type] = {} if !registeredActions[type]?
            registeredActions[type][action] = cb

    lastPatch = {}
    patches = {}
    getPatches = (textId) ->
        if !patches[textId]?
            patches[textId] = []
        patches[textId]

    setLastPatch = (textId) ->
        lastPatch[textId] = Date.now()
        patches[textId]?.length = 0

    contentTypes = null
    {
        setContentTypes: (types) -> contentTypes = types

        requestOperation
        parseOperations
        get
        getByIds
        save
        query
        call
        registerAction

        getPatches
        setLastPatch
    }
