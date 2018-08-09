*deps: novaVirtualScroller

class novaListScroller extends novaVirtualScroller

    constructor: (params) ->
        @perLine = 1
        @sepCache = {}
        @lastPageFetched = 0

        params.updateOnAffected = true
        super params

    setPerLine: (val) ->
        @perLine = val

    rebuild: ->
        @params.pageHeight = @params.elem.height()
        @scroll 0

    buildPage: (page) ->
        page.blocks.length = 0
        page.height = 0
        page.log = []

        pocketKeys = Object.keys @pockets
        console.log 'KEYS', pocketKeys
        if pocketKeys.length == 0
            page.last = true
            page.first = true
            if page.query.from? and !page.query.to?
                page.query.to = page.query.from
            return page

        pocketKeys.sort().reverse()

        if page?.query?.from?

            page.query.to = page.query.from
            pocketId = page.query.from
            if pocketId+'' not in pocketKeys
                pocketId = pocketKeys[0]*1
            pocketIndex = pocketKeys.indexOf pocketId+''
            cursor = page.query.cursor or 0

            console.log @pockets[pocketId], pocketId, @params.pageHeight

            while @pockets[pocketId]? and page.height < @params.pageHeight

                page.query.to = pocketId

                newBlock =
                    id: pocketId
                    code: pocketId + ':' + cursor
                    type: 'content'
                    items: []

                while cursor < @pockets[pocketId].length and page.height < @params.pageHeight
                    for i in [cursor...cursor + @perLine]
                        if @pockets[pocketId][i]?
                            # newBlock.items.push @pockets[pocketId][i]
                            page.blocks.push @pockets[pocketId][i]
                    cursor += @perLine
                    page.height += @params.lineHei

                if cursor >= @pockets[pocketId].length
                    pocketIndex++
                    cursor = 0
                    pocketId = pocketKeys[pocketIndex]*1

                page.query.cursorEnd = cursor
                # page.blocks.push newBlock

            if !@pockets[pocketId]?
                page.last = true
                @fetch page
            else
                page.query.to = pocketId
                page.last = false

            if page.query.from == 0
                page.first = true

        else

            page.query.from = page.query.to
            pocketId = page.query.to
            if pocketId+'' not in pocketKeys
                pocketId = pocketKeys[0]*1
            pocketIndex = pocketKeys.indexOf pocketId+''
            cursor = page.query.cursorEnd or 0

            page.log.push 'start ' + cursor

            if cursor == 0
                pocketIndex--
                pocketId = pocketKeys[pocketIndex]*1
                cursor = @pockets[pocketId]?.length

            page.log.push 'pocket picked ' + pocketId

            while @pockets[pocketId]? and page.height < @params.pageHeight

                newBlock =
                    id: pocketId
                    code: pocketId + ':' + cursor
                    type: 'content'
                    items: []

                lineId = Math.ceil cursor / @perLine
                while lineId > 0 and page.height < @params.pageHeight
                    lineStart = (lineId-1) * @perLine
                    for i in [lineStart + @perLine...lineStart]
                        if @pockets[pocketId][i-1]?
                            # newBlock.items.unshift @pockets[pocketId][i-1]
                            page.blocks.unshift @pockets[pocketId][i-1]
                    lineId--
                    cursor = lineStart
                    page.height += @params.lineHei

                # page.blocks.unshift newBlock

                if cursor <= 0
                    # if page.height < @params.pageHeight
                    pocketIndex--
                    pocketId = pocketKeys[pocketIndex]*1

                    cursor = @pockets[pocketId]?.length

            if !@pockets[pocketId]?
                page.query.from = 0
                page.first = true
            else
                page.query.cursor = cursor
                page.query.from = pocketId
                page.first = false

        page

    pickPocket: (item, query) ->
        if @params.sortFunc?
            return @params.sortFunc item, query
        query.page

    doFetch: (query, cb) ->
        if @lastPageFetched >= @maxPages
            return

        finalQuery =
            limit: 20
            page: @lastPageFetched++
            parent: @params.parent or 'null'
            sortBy: @params.sortBy
            sortType: 'desc'
        updateObject finalQuery, @query
        @params.queryFunc finalQuery, (items, total) =>
        # contentService.query finalQuery, (items, total) =>
            @maxPages = Math.ceil total / 20
            cb items, total, finalQuery

novaListScroller
