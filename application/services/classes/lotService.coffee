buzzlike.service 'lotService', (itemService, rpc, account, socketService, requestService, actionsService) ->

    class classEntity extends itemService

        itemType: 'lot'

        constructor: () ->
            super()

            @categoriesList = {}
            @categoriesKeys = {}
            @state =
                currentLot: null

            @catsLoaded = false

            socketService.on 'lot.update', @fetchMy

        handleItem: (item) ->
            stored = @storage[item.id]

            if stored?

                for key, value of item
                    if key == 'userUpdated' 
                        if item.userUpdated?[0]?.userId != account.user.id
                            continue
                    @storage[item.id][key] = item[key]

                if stored.blank?
                    delete stored.blank
            else
                @storage[item.id] = item

            if item.userId == account.user.id
                @my[item.id] = @storage[item.id]

            @storage[item.id]

        getCategories: (cb) ->
            if @catsLoaded
                cb? @categoriesList
                return
            #httpWrapped.get marketBaseUrl + '/categories', (categories) ->
            rpc.call 'market.getCategories', (categories) =>
                @catsLoaded = true
                for c in categories
                    @categoriesList[c.id] = c
                    @categoriesKeys[c.key] = @categoriesList[c.id]
                cb? @categoriesList

        previewLot: (lotItem) -> @state.currentLot = lotItem
        previewLotById: (lotId) -> @previewLot @storage[lotId]

        publish: (lotId, cb) -> 
            @call 'publish', lotId, (result) =>
                if result? and !result.err?
                    result = @handleItem result
                cb? result
        unpublish: (lotId, cb) -> 
            @call 'unpublish', lotId, (result) =>
                if result? and !result.err?
                    result = @handleItem result
                cb? result

        buy: (lotId) ->
            @call 'buy', lotId, (result) ->
                if result? and !result.err?
                    result = @handleItem result
                cb? result

        sortMy: =>
            # sorting my items by lastUpdated
            myArr = makeArray @my
            myArr.sort (a, b) ->
                a = a.lastUpdated
                b = b.lastUpdated
                if a < b then return 1
                if a > b then return -1
                0

            myArr

        fetchMy: (cb) =>
            latestItem = @sortMy()[0]

            @query
                userId: account.user.id
                filterBy: 'lastUpdated'
                filterGreater: latestItem?.lastUpdated or 0
            , (data) =>
                if !@state?.currentLot? then return cb? data
                requestService.query
                    lotId: @state.currentLot.id
                , cb

        getModeration: (cb) ->
            @call 'moderation', (queryResult) ->
                cb? queryResult.items

        moderate: (data, cb) ->
            @call 'moderate', data, (result) ->
                cb? result

        # Flags ======
        flushNew: (lotId, cb) ->
            @call 'flushNew', lotId, (result) =>
                @storage[lotId]?.requestsNew = 0
                cb? result

        init: () ->
            super()

            actionsService.registerParser 'lot', (item) ->
                result = [item.lotType + 'Lot']
                if item.userId == account.user.id
                    result.push 'myLot'
                result

            actionsService.registerAction
                sourceType: 'image'
                sourceNumber: 1
                targetType: 'myLot'
                phrase: 'set_cover'
                action: (data) =>
                    @save
                        id: data.target.id
                        cover: data.item.id
                    , ->
                        true                            

            ###
            selectionService.registerAction 'post', 'all', 'unsellContent', (contentIds) ->
                removeLots 'post', contentIds
                true
            , checkUnSold
            selectionService.registerAction 'content', 'all', 'unsellContent', (contentIds) ->
                removeLots 'content', contentIds
                true
            , checkUnSold
            selectionService.registerAction 'comb', 'all', 'unsellContent', (contentIds) ->
                removeLots 'comb', contentIds
                true
            , checkUnSold
            selectionService.registerAction 'post', 'all', 'sellContent', (contentIds) ->
                sale 'post', contentIds
                true
            , checkSold
            selectionService.registerAction 'content', 'all', 'sellContent', (contentIds) ->
                toAdd = []
                for id in contentIds
                    obj = operationsService.get 'content', id
                    if obj.type!='url'
                        toAdd.push obj
                sale 'content', toAdd
                true
            , checkSold
            selectionService.registerAction 'comb', 'all', 'sellContent', (contentIds) ->
                sale 'comb', contentIds
                true
            , checkSold
            ###
            true

    new classEntity()