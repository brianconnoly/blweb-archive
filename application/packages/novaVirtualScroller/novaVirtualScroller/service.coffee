class novaVirtualScroller

    constructor: (@params) ->
        # Init ========
        @query = @params.query
        @pockets = {}
        @pocketMap = {}
        @pages = []
        @keypage = null
        @pageIdCnt = 0
        # Run =========
        if @params.elem?
            @params.elem.on 'mousewheel', (e, delta) =>
                e.stopPropagation()
                e.preventDefault()
                @scroll delta

        @scroll 0

    addPage: (data) ->
        page =
            id: @pageIdCnt++
            anchor: 'top'
            top: 0
            query: data.query
            pageCnt: data.pageCnt
            blocks: []
            height: 0

        @buildPage page
        @fetch page.query
        page

    apply: ->
        @params.apply?()

    scroll: (delta, fuck = null) ->
        delta = delta | 0
        lastY = 0
        lastPage = null
        firstPage = @pages[0]

        wasCreated = false

        middlePage = @params.pageHeight / 2
        minDelta = null
        newKeypage = null

        toDelete = []

        if @keypage?
            # console.log @keypage.pageCnt, @pages.length if fuck
            @keypage.top += delta

            firstTop = firstPage.top
            if firstPage.anchor == 'bottom'
                firstTop -= firstPage.height

            keyIndex = @pages.indexOf @keypage
            minDelta = Math.abs(middlePage - @keypage.top)

            # Check if last page is last
            if @pages[@pages.length-1].last == true # and @pages[@pages.length-1].first != true
                # count height from scroller top to last page
                bigHei = @keypage.top + @keypage.height
                if keyIndex+1 < @pages.length then for i in [keyIndex+1...@pages.length]
                    bigHei += @pages[i].height

                if bigHei < @params.pageHeight
                    # Fix key top
                    @keypage.top += @params.pageHeight - bigHei

            # Check if first is first
            if firstPage?.first == true
                # Get key to top
                keyIndex = @pages.indexOf @keypage
                keyToFirstTop = 0
                for i in [0...keyIndex]
                    keyToFirstTop += @pages[i].height

                if @keypage.top - keyToFirstTop > 0
                    i = 0
                    smallTop = 0
                    page = firstPage
                    while page != @keypage and i < @pages.length
                        smallTop += page.height
                        i++
                        page = @pages[i]

                    if page == @keypage
                        @keypage.top = smallTop

            if @keypage.element?
                pHei = @keypage.element.height()
                if pHei > 0
                    @keypage.height = pHei
                @keypage.element?.css 'transform', "translate3d(0,#{@keypage.top}px,0)"

            if @keypage.top + @keypage.height < -@params.pageHeight * 2 or @keypage.top > @params.pageHeight * 3
                toDelete.push @keypage

            # After
            lastY = @keypage.top + @keypage.height
            if keyIndex+1 < @pages.length then for i in [keyIndex+1...@pages.length]
                page = @pages[i]
                page.top = lastY

                if page.element?
                    pHei = page.element.height()
                    if pHei > 0
                        page.height = pHei
                    page.element?.css 'transform', "translate3d(0,#{page.top}px,0)"

                if page.anchor == 'bottom'
                    page.element?.css 'bottom', 'auto'
                    page.anchor = 'top'

                lastY += page.height

                topDelta = Math.abs(middlePage - page.top)
                if !minDelta? or topDelta < minDelta
                    minDelta = topDelta
                    newKeypage = page

                if page.top < -@params.pageHeight or page.top > @params.pageHeight * 2
                    toDelete.push page #if page not in toDelete

            # Before
            lastY = @keypage.top
            if keyIndex > 0 then for i in [keyIndex-1..0] by -1
                page = @pages[i]
                page.top = lastY

                if page.element?
                    pHei = page.element.height()
                    if pHei > 0
                        page.height = pHei
                    page.element?.css 'transform', "translate3d(0,#{page.top}px,0)"

                if page.anchor == 'top'
                    page.element?.css 'bottom', '100%'
                    page.anchor = 'bottom'

                lastY -= page.height

                topDelta = Math.abs(middlePage - lastY)
                if !minDelta? or topDelta < minDelta
                    minDelta = topDelta
                    newKeypage = page

                # if page.top - page.height < -@params.pageHeight * 2 or page.top > @params.pageHeight * 3
                if page.top < -@params.pageHeight or page.top > @params.pageHeight * 2
                    toDelete.push page

        lastPage = @pages[@pages.length-1]

        if !lastPage?
            lastPage =
                # pageCnt: -1
                top: 0
                height: 0
                query:
                    from: @params.startFrom or 0
                    to: @params.startFrom or 0
            firstPage = lastPage

        lastY = lastPage.top + lastPage.height

        while lastPage.last != true and lastY? and lastY < @params.pageHeight * 1.5
            page = @addPage
                pageCnt: (lastPage.pageCnt or 0) + 1
                query:
                    cursor: lastPage.query.cursorEnd
                    from: lastPage.query.to
            page.top = lastY

            if page.last == true and page.first != true and page.top + page.height < @params.pageHeight
                page.top = @params.pageHeight - page.height
                # Fix next page
                removeElementFromArray lastPage, toDelete if lastPage in toDelete
                if lastPage.anchor == 'top'
                    lastPage.top = page.top - lastPage.height
                else
                    lastPage.top = page.top

            lastY += page.height
            lastPage = page
            @pages.push page
            wasCreated = true

            topDelta = Math.abs(middlePage - page.top)
            if !minDelta? or topDelta < minDelta
                minDelta = topDelta
                newKeypage = page

        firstPage = @pages[0] if @pages[0]?
        firstTop = firstPage.top
        if firstPage.anchor == 'bottom'
            firstTop = firstPage.top - firstPage.height
        while firstPage.first != true and firstTop > - @params.pageHeight / 2
            page = @addPage
                pageCnt: (firstPage.pageCnt or 0) - 1
                query:
                    cursorEnd: firstPage.query.cursor
                    to: firstPage.query.from

            if firstPage.anchor == 'top'
                page.top = firstPage.top
            else
                page.top = firstPage.top - firstPage.height

            if page.first == true and page.top - page.height > 0
                page.top = 0 + page.height
                # Fix prev page
                removeElementFromArray firstPage, toDelete if firstPage in toDelete
                if firstPage.anchor == 'top'
                    firstPage.top = page.top
                else
                    firstPage.top = page.top + page.height

            page.anchor = 'bottom'
            @pages.unshift page
            firstPage = page
            firstTop = page.top - page.height
            wasCreated = true

            topDelta = Math.abs(middlePage - page.top + page.height)
            if !minDelta? or topDelta < minDelta
                minDelta = topDelta
                newKeypage = page

        if newKeypage?
            @keypage = newKeypage
            if @keypage.anchor == 'bottom'
                @keypage.element?.css 'bottom', 'auto'
                @keypage.anchor = 'top'
                @keypage.top -= @keypage.height
                @keypage.element?.css 'transform', "translate3d(0,#{@keypage.top}px,0)"

        for page in toDelete
            if page != @keypage
                wasCreated = true
                removeElementFromArray page, @pages

        if wasCreated
            @apply()
        true

    processAffected: (affectedPockets) ->
        if @keypage? and affectedPockets.length > 0

            updateFlags =
                update: false
                updPrev: false
                updNext: false
                updCur: false

            for pocketId in affectedPockets
                if pocketId*1 > @keypage.query.from or (pocketId*1 == @keypage.query.from and @keypage.query.cursor > 0)
                    updateFlags.update = true
                    updateFlags.updPrev = true
                    continue

                if pocketId*1 < @keypage.query.to
                    updateFlags.update = true
                    updateFlags.updNext = true
                    continue

                if @keypage.query.to <= pocketId*1 <= @keypage.query.from
                    updateFlags.update = true
                    updateFlags.updCur = true
                    continue

            if updateFlags.update == false
                return

            @pages.length = 0
            @pages.push @keypage
            @buildPage @keypage

            # if updateFlags.updPrev
            #     keyIndex = @pages.indexOf @keypage
            #     if keyIndex > 0
            #         # @pages.splice 0, keyIndex - 1
            #         @pages.length = keyIndex
            #     @buildPage @pages[0]
            #
            # if updateFlags.updCur
            #     # @pages.length = 0
            #     # @pages.push @keypage
            #     # @buildPage @keypage
            #     keyIndex = @pages.indexOf @keypage
            #     if @pages.length > keyIndex + 1
            #         @pages.length = keyIndex + 1
            #     @buildPage @keypage
            #
            # else if updateFlags.updNext
            #     keyIndex = @pages.indexOf @keypage
            #     if @pages.length > keyIndex + 2
            #         @pages.length = keyIndex + 2
            #     @buildPage @pages[keyIndex+1] if @pages[keyIndex+1]?

        @scroll 0, 'fuck'
        @apply()

    getItemsAffectedPockets: (items, finalQuery, action) ->
        console.log 'NEW ITEMS', items
        affectedPockets = []
        for item in items
            if item.deleted == true or ((item.parent or 'null') != @query.parent)
                if @pocketMap[item.id]?
                    removeElementFromArray item, @pockets[@pocketMap[item.id]]
                    affectedPockets.push @pocketMap[item.id]
                    delete @pocketMap[item.id]
            else
                pocketId = @pickPocket item, finalQuery
                if @pocketMap[item.id]? and @pocketMap[item.id] != pocketId
                    removeElementFromArray item, @pockets[@pocketMap[item.id]]
                    affectedPockets.push @pocketMap[item.id] if @pocketMap[item.id] not in affectedPockets
                @pocketMap[item.id] = pocketId

                if !@pockets[pocketId]?
                    @pockets[pocketId] = []
                    affectedPockets.push pocketId if pocketId not in affectedPockets
                else if @params.updateOnAffected
                    affectedPockets.push pocketId if pocketId not in affectedPockets

                @pockets[pocketId].push item if item not in @pockets[pocketId]
        console.log 'RESULT', @pockets
        affectedPockets

    fetch: (query) ->
        @doFetch query, (items, total, finalQuery) =>
            @processAffected @getItemsAffectedPockets items, finalQuery

    updated: (items, action) ->
        @processAffected @getItemsAffectedPockets items, {}, action

    reloadAll: () ->
        emptyObject @pockets
        emptyObject @pocketMap
        @pages.length = 0
        # @keypage = null
        @pages.push @keypage
        # @buildPage @keypage
        @lastPageFetched = 0
        @fetch()

    filterFunc: (item) ->
        console.log item
        true

    sortFunc: (item) ->
        if @params.sortFunc?
            return @params.sortFunc item
        else
            console.log 'ELSE'
            item.lastUpdated or item.created

    rebuild: (full = false)->
        @pages.length = 0

        if !full
            @pages.push @keypage
            @buildPage @keypage
        else
            @keypage = null

        @scroll 0

novaVirtualScroller
