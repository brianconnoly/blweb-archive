buzzlike.service 'queryService', (httpWrapped, env, notificationCenter, $injector, lotService, rpc) ->

    callBacks = {}
    queryId = 0

    status = 
        handler: null
        queries: []

    contentService = null
    combService = null
    postService = null

    init = () ->
        contentService = $injector.get 'contentService'
        combService = $injector.get 'combService'
        postService = $injector.get 'postService'


    query = (queryData, cb) ->
        progress = notificationCenter.registerProgress true
        rpc.call queryData.entityType + '.query', queryData, (result) ->
            progress.value = 100
            notificationCenter.updateStatus progress

            items = []

            for item in result.items
                if contentService.isContent(item)
                    items.push contentService.handleItem item
                    continue

                if item.type == 'comb'
                    items.push combService.handleItem item
                    continue

                if item.type == 'lot'
                    items.push lotService.handleItem item
                    continue

                if item.type == 'post'
                    items.push postService.handleItem item
                    continue

            cb items, result.total

        # queryData = angular.copy queryData
        
        # queryData.queryId = queryId
        # callBacks[queryId] = cb

        # status.queries.push queryData
        # queryId++

        # if !status.handler?
        #     status.handler = setTimeout () ->
                

        #         fireQuery status.queries, callBacks

        #         status = 
        #             handler: null
        #             queries: []
        #     , 200

    fireQuery = (list, cbs) ->
        progress = notificationCenter.registerProgress true
        httpWrapped.post env.baseurl + '/query', list, (results) ->
            progress.value = 100
            notificationCenter.updateStatus progress

            for result in results
                items = []

                for item in result.items
                    if contentService.isContent(item)
                        items.push contentService.registerContent item
                        continue

                    if item.type == 'comb'
                        items.push combService.registerComb item

                    if item.type == 'lot'
                        items.push lotService.registerLot item

                if callBacks[result.queryId]?
                    callBacks[result.queryId] items, result.total
                    delete callBacks[result.queryId]
    {
        init
        query
    }

