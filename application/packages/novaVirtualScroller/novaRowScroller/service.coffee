*deps: novaVirtualScroller

class novaContentScroller extends novaVirtualScroller

    constructor: (params) ->
        @updateDayStart()
        @perLine = params.perLine
        @sepCache = {}
        @lastPageFetched = 0

        params.updateOnAffected = true
        super params

    updateDayStart: ->
        now = new Date()
        @dayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate())

    getNextSeparator: (timestamp) ->
        startTs = @dayStart.getTime()
        if timestamp > startTs
            return {
                code: startTs
                type: 'separator'
                separatorType: 'today'
                timestamp: startTs
            }

        if timestamp > startTs - WEEK
            return {
                code: startTs - WEEK
                type: 'separator'
                separatorType: 'week'
                timestamp: startTs - WEEK
            }

        tsDate = new Date timestamp
        monthTs = new Date(tsDate.getFullYear(), tsDate.getMonth()).getTime()
        return {
            code: monthTs
            type: 'separator'
            separatorType: 'month'
            timestamp: monthTs
        }

    setPerLine: (val) ->
        @perLine = val

    rebuild: ->
        @params.pageHeight = @params.elem.height()


    buildPage: (page) ->
        @updateDayStart()

        page.blocks.length = 0
        page.height = 0
        page.log = []

        pocketKeys = Object.keys @pockets
        if pocketKeys.length == 0
            page.last = true
            page.first = true
            return page

        pocketKeys.sort().reverse()

        if page?.query?.from?

            page.query.to = page.query.from
            pocketId = page.query.from
            if pocketId+'' not in pocketKeys
                pocketId = pocketKeys[0]*1
            pocketIndex = pocketKeys.indexOf pocketId+''
            cursor = page.query.cursor or 0

            while @pockets[pocketId]? and page.height < @params.pageHeight

                if !(cursor > 0) # == 0 page.query.to != pocketId
                    page.blocks.push @sepCache[pocketId] if @sepCache[pocketId]?
                    page.height += 30

                page.query.to = pocketId

                newBlock =
                    id: pocketId
                    code: pocketId + ':' + cursor
                    type: 'content'
                    items: []

                while cursor < @pockets[pocketId].length and page.height < @params.pageHeight
                    for i in [cursor...cursor + @perLine]
                        if @pockets[pocketId][i]?
                            newBlock.items.push @pockets[pocketId][i]
                    cursor += @perLine
                    page.height += @params.lineHei

                if cursor >= @pockets[pocketId].length
                    pocketIndex++
                    cursor = 0
                    pocketId = pocketKeys[pocketIndex]*1

                page.query.cursorEnd = cursor
                page.blocks.push newBlock
                page.height += @params.blockMargin

                if page.height + 30 >= @params.pageHeight
                    break

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
                            newBlock.items.unshift @pockets[pocketId][i-1]
                    lineId--
                    cursor = lineStart
                    page.height += @params.lineHei

                page.blocks.unshift newBlock
                page.height += @params.blockMargin

                if cursor <= 0
                    page.blocks.unshift @sepCache[pocketId] if @sepCache[pocketId]?
                    page.height += 30

                    # if page.height < @params.pageHeight
                    pocketIndex--
                    pocketId = pocketKeys[pocketIndex]*1
                    page.log.push 'prev pocket ' + pocketId
                    cursor = @pockets[pocketId]?.length

                if page.height + 30 >= @params.pageHeight
                    break

            if !@pockets[pocketId]?
                page.query.from = 0
                page.first = true
            else
                page.query.cursor = cursor
                page.query.from = pocketId
                page.first = false

        page

    pickPocket: (item, query) ->
        separator = @getNextSeparator(item[@params.sortBy])
        @sepCache[separator.timestamp] = separator
        separator.timestamp

    doFetch: (query, cb) ->
        if @lastPageFetched >= @maxPages
            return

        finalQuery =
            limit: 60
            page: @lastPageFetched++
            sortBy: @params.sortBy
            sortType: 'desc'
        updateObject finalQuery, @query
        @params.queryFunc finalQuery, (items, total) =>
        # contentService.query finalQuery, (items, total) =>
            @maxPages = Math.ceil total / 60
            cb items, total

novaContentScroller
