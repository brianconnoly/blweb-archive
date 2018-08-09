buzzlike.service 'statsCutService', (itemService, rpc) ->

    class classEntity extends itemService

        itemType: 'statsCut'

        constructor: () ->
            super()
            @byCommunity = {}

        _handler = null
        _cumulativeQuery = 
            communityIds: []
            timestamp: 
                $gte: null
                $lte: null
            cbs: []

        delayedFetch: (query, cb) ->
            _cumulativeQuery.communityIds.push query.communityId if query.communityId not in _cumulativeQuery.communityIds
            _cumulativeQuery.cbs.push cb

            if query.timestamp < _cumulativeQuery.timestamp.$gte or _cumulativeQuery.timestamp.$gte == null
                _cumulativeQuery.timestamp.$gte = query.timestamp

            if query.timestamp > _cumulativeQuery.timestamp.$lte or _cumulativeQuery.timestamp.$lte == null
                _cumulativeQuery.timestamp.$lte = query.timestamp

            if _handler == null
                _handler = setTimeout =>
                    cbs = _cumulativeQuery.cbs
                    _handler = null

                    @query 
                        communityId:
                            $in: _cumulativeQuery.communityIds
                        timestamp: _cumulativeQuery.timestamp
                    , () ->
                        for callback in cbs
                            callback?()

                    _cumulativeQuery = 
                        communityIds: []
                        timestamp: 
                            $gte: null
                            $lte: null
                        cbs: []
                , 1000

        get: (query, cb) ->
            if @byCommunity[query.communityId]?[query.timestamp]?
                cb? @byCommunity[query.communityId][query.timestamp]
                return @byCommunity[query.communityId][query.timestamp]

            if !@byCommunity[query.communityId]?
                @byCommunity[query.communityId] = {}

            if !@byCommunity[query.communityId][query.timestamp]?
                @byCommunity[query.communityId][query.timestamp] = {}
                    # day: 
                    #     timestamp: query.timestamp
                    #     communityId: query.communityId

            # @query query, () =>
            @delayedFetch query,
                cb? @byCommunity[query.communityId][query.timestamp]

            return @byCommunity[query.communityId][query.timestamp]

        handleItem: (item) ->
            handled = super item
            
            if !@byCommunity[handled.communityId]?
                @byCommunity[handled.communityId] = {}

            ts = handled.timestamp
            # switch handled.statsCutType
            #     when 'day'
            #         ts += DAY
            #     when 'week'
            #         ts += WEEK
            #     when 'month'
            #         dtObj = new Date ts
            #         ts = new Date(dtObj.getFullYear(),dtObj.getMonth()+1).getTime()

            if !@byCommunity[handled.communityId][ts]?
                @byCommunity[handled.communityId][ts] = {}

            @byCommunity[handled.communityId][handled.timestamp][handled.statsCutType] = handled
            handled

    new classEntity()