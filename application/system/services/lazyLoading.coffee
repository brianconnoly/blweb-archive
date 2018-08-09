buzzlike.factory 'lazyLoading', (scheduleService, $rootScope) ->

    stackToLoad =
        communities: []
        start: getBigTimestamp()
        end: 0
        handler: false
        cbs: []

    callLazyLoad = (cIds, start, end, cb) ->
        for cId in cIds
            if stackToLoad.communities.indexOf(cId) < 0
                stackToLoad.communities.push cId

        stackToLoad.cbs.push
            cIds: cIds
            start: start
            end: end
            cb: cb

        if stackToLoad.start > start then stackToLoad.start = start
        if stackToLoad.end < end then stackToLoad.end = end

        if !stackToLoad.handler then stackToLoad.handler = setTimeout () ->
            cbs = stackToLoad.cbs
            do (cbs) ->
                scheduleService.query
                    communities: stackToLoad.communities
                    filterBy: 'timestamp'
                    filterLower: stackToLoad.end
                    filterGreater: stackToLoad.start
                , (items) ->
                    for cb in cbs
                        cbItems = []
                        for item in items
                            if  item.communityId in cb.cIds and
                                cb.start <= item.timestamp <= cb.end
                                    cbItems.push item
                        cb.cb cbItems if cbItems.length > 0

            stackToLoad =
                communities: []
                start: getBigTimestamp()
                end: 0
                handler: false
                cbs: []

            # $rootScope.$apply()
        , 500

    {
        callLazyLoad
    }