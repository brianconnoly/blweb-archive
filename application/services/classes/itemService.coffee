buzzlike.service 'itemService', (account, rpc, operationsService) ->

    class classEntity

        call: (method, data, cb) -> rpc.call @itemType + '.' + method, data, cb

        getId: (entity) -> if typeof entity == 'object' then entity.id else entity

        constructor: () ->
            @storage = {}

            @fetchedByProject = {}
            @byProjectId = {}

            @my = {}
            @loadingOptimizer =
                handler: null
                ids: []
                cbs: {}
            @init()

        getByProjectId: (projectId, cb) ->
            if @fetchedByProject[projectId] != true
                @fetchedByProject[projectId] = true

                if !@byProjectId[projectId]?.length?
                    @byProjectId[projectId] = []

                @query
                    projectId: projectId
                , (items) =>
                    cb? @byProjectId[projectId]
                return @byProjectId[projectId]

            cb? @byProjectId[projectId]
            return @byProjectId[projectId]

        purge: () ->
            emptyObject @storage
            emptyObject @fetchedByProject
            emptyObject @byProjectId
            emptyObject @my

            @loadingOptimizer.handler?.clearTimeout?()
            @loadingOptimizer.ids.length = 0
            @loadingOptimizer.cbs.length = 0

        handleItems: (items) ->
            @handleItem item for item in items

        handleItem: (item) ->
            stored = @storage[item.id]

            if stored?
                updateObject @storage[item.id], item
                if stored.blank?
                    delete stored.blank
            else
                @storage[item.id] = item

            if item.projectId?
                if @byProjectId[item.projectId]?.length?
                    # @byProjectId[item.projectId] = []

                    if @storage[item.id] not in @byProjectId[item.projectId]
                        @byProjectId[item.projectId].push @storage[item.id] if @storage[item.id] not in @byProjectId[item.projectId]

            if item.userId == account.user.id
                @my[item.id] = @storage[item.id]

            @storage[item.id]

        fetchById: (id, reqCb) ->

            doFetchOptimized = (ids, cbs) =>
                if ids.length > 1
                    @getByIds ids, (items) =>
                        for item in items
                            saved = @handleItem item
                            if cbs[item.id]?
                                for cb in cbs[item.id]
                                    cb? saved
                                delete cbs[item.id]

                        # Rest cbs
                        for k,v of cbs
                            for cb in v
                                cb? false

                        true

                else
                    @call 'getById', ids[0], (item) =>
                        saved = @handleItem item

                        if cbs[id]?
                            for cb in cbs[id]
                                cb? saved
                            delete cbs[id]

            @loadingOptimizer.ids.push id if id not in @loadingOptimizer.ids
            if reqCb?
                if !@loadingOptimizer.cbs[id]?
                    @loadingOptimizer.cbs[id] = []
                @loadingOptimizer.cbs[id].push reqCb

            if @loadingOptimizer.handler == null
                @loadingOptimizer.handler = setTimeout () =>

                    doFetchOptimized @loadingOptimizer.ids, @loadingOptimizer.cbs

                    @loadingOptimizer =
                        handler: null
                        ids: []
                        cbs: {}

                , 200

            return

        getById: (id, cb) ->
            if !id? # or id == 'undefined'
                console.log 'Undefined!', id, cb
                cb? id
                return id

            stored = @storage[id]

            if stored? and stored.blank != true
                cb? stored
            else
                if !stored? then @storage[id] =
                    id: id
                    blank: true

                @fetchById id, cb

            @storage[id]

        getByIdsOptimized: (ids, cb) ->
            result = []
            fetchIds = []
            optimizedMap = {}
            optimizedResult = []
            # Prepare
            for id in ids
                if !@storage[id]? then @storage[id] =
                    id: id
                    blank: true

                if @storage[id].blank == true
                    fetchIds.push id
                else
                    optimizedMap[id] = @storage[id]

                result.push @storage[id]

            if fetchIds.length > 0
                @query
                    ids: fetchIds
                , (items, total) ->
                    for item in items
                        optimizedMap[item.id] = item
                    for id in ids
                        optimizedResult.push optimizedMap[id]
                    cb? optimizedResult
            else
                for id in ids
                    optimizedResult.push optimizedMap[id]
                cb? optimizedResult

            result

        getByIds: (ids, cb) ->
            result = []
            # Prepare
            for id in ids
                if !@storage[id]? then @storage[id] =
                    id: id
                    blank: true

                result.push @storage[id]

            @query
                ids: ids
            , (items, total) ->
                cb? items

            result

        exists: (id) -> @storage[id]?

        addContentIds: (entity, ids, cb) ->
            id = @getId entity

            @call 'addContent',
                id: id
                ids: ids
            , (result) ->
                cb? true

        removeContentIds: (entity, ids, cb) ->
            id = @getId entity

            @call 'removeContent',
                id: id
                ids: ids
            , (result) ->
                cb? true

        query: (data, cb) =>
            @call 'query', data, (queryResult) =>
                response = @handleItems queryResult.items
                cb? response, queryResult.total

        duplicate: (data, cb) ->
            @call 'duplicate', @getId(data), (newItem) =>
                cb? @getById newItem.id

        create: (data, cb) ->
            @call 'create', angular.copy(data), (newItem) =>
                cb? @getById newItem.id

        delete: (data, cb) ->
            data.type = @itemType if !data.type?
            @call 'delete', data, (response) =>
                cb? response

        deleteByIds: (ids, cb) ->
            @call 'deleteByIds', ids, (response) =>
                cb? response

        save: (data, cb) ->
            @call 'update', angular.copy(data), (result) ->
                cb? result

        removeCache: (id) ->
            @storage[id]?.deleted = true
            delete @my[id] if @my[id]?
            # delete @storage[id] if @storage[id]?

        hasContentIds: (entity, ids) ->
            id = @getId entity

            storedEntity = @storage[id]
            for itemId in ids
                for type,items of storedEntity.contentIds
                    if itemId in items
                        return true

            false

        onCreate: (item) ->
            @handleItem item

        init: () ->
            types = @typeMarker || @itemType

            operationsService.registerAction 'save', types, (item, cb) => @save item, cb
            operationsService.registerAction 'create', types, (id, data) => @onCreate data.entity
            operationsService.registerAction 'update', types, (id, data) => @handleItem data.entity
            operationsService.registerAction 'delete', types, (id, data) => @removeCache id
            operationsService.registerAction 'get',    types, (id, cb)   => @getById id, cb
            operationsService.registerAction 'getByIds', types, (ids, cb) => @getByIds ids, cb
            operationsService.registerAction 'query', types, (ids, cb) => @query ids, cb
            operationsService.registerAction 'call', types, (method, data, cb) => @call method, data, cb
