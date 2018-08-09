*deps: novaVirtualScroller, scheduleService, lazyLoading, $compile

separatorType =
    0: 'day'
    1: 'day'
    2: 'week'
    3: 'month'

sortInt = (a,b) ->
    if a*1 > b*1
        return 1
    if a*1 < b*1
        return -1
    return 0

class novaTimelineScroller extends novaVirtualScroller

    constructor: (params, @scope, @elem) ->
        @fetched =
            from: 0
            to: 0
        @separators = {}
        @currepntSeparator = null
        @placeholders = {}
        @rules = params.rules
        super params

    requestSeparator: (data, cb) ->
        sep = @separators[data.block.timestamp]
        sep.scrollerElem = data.elem
        sep.page = data.page
        sep.pos = data.pos

        if data.page.anchor == 'top'
            if data.page.top + data.pos.top < 0 and (!@currepntSeparator?.page? or !@currepntSeparator?.pos? or (@currepntSeparator.page.top + @currepntSeparator.pos.top > data.page.top + data.pos.top))
                if @currepntSeparator?
                    @currepntSeparator.scrollerElem?.append @currepntSeparator.elem
                    @currepntSeparator.elem.css 'top', 0
                # Make current

                @currepntSeparator = sep
                @currepntSeparator.hei = data.page.top + data.pos.top

                @elem.append @currepntSeparator.elem
            else
                cb sep.elem
        else
            if data.page.top - data.page.height + data.pos.top < 0 and (!@currepntSeparator?.page? or !@currepntSeparator?.pos? or (@currepntSeparator.page.top + @currepntSeparator.pos.top > data.page.top - data.page.height + data.pos.top))
                if @currepntSeparator?
                    @currepntSeparator.scrollerElem?.append @currepntSeparator.elem
                    @currepntSeparator.elem.css 'top', 0
                # Make current
                @currepntSeparator = sep
                @currepntSeparator.hei = data.page.top + data.pos.top

                @elem.append @currepntSeparator.elem
            else
                cb sep.elem

        @updateSeparator()

    scroll: (data, fuck) ->
        super data, fuck
        @updateSeparator()

        # Search currentDay
        searchPage = null
        keyTop =
        if @keypage.anchor == 'top'
            keyTop = @keypage.top
        else
            keyTop = @keypage.top - bottom

        if keyTop <= 140
            searchPage = @keypage
        else
            keyIndex = @pages.indexOf @keypage
            keyIndex = 1 if keyIndex < 1
            searchPage = @pages[keyIndex - 1]

        @scope.minDiff = 9999999
        # @scope.cursorTime = null

        _scroller = @
        if searchPage?.element?
            blocks = searchPage.element.children '.novaTimelineFrameBlock'
            found = null
            blocks.each ->
                jBlock = $ @
                if searchPage.anchor == 'top'
                    diff = searchPage.top + jBlock.position().top
                else
                    diff = searchPage.top - searchPage.height + jBlock.position().top

                if 0 <= diff < _scroller.scope.minDiff
                    _scroller.scope.minDiff = diff
                    found = @

            if found?
                if _scroller.scope.scrollerParams.cursor != angular.element(found).scope().block?.timestamp
                    _scroller.scope.scrollerParams.cursor = angular.element(found).scope().block.timestamp
                    _scroller.scope.$applyAsync()

    getSepTop: (sep) ->
        if !sep.pos?.top?
            return null

        if sep.page.anchor == 'top'
            return sep.page.top + sep.pos.top
        else
            return sep.page.top - sep.page.height + sep.pos.top

    updateSeparator: ->
        if !@currepntSeparator?
            keys = Object.keys @separators
            if keys.length > 0
                @currepntSeparator = @separators[keys[0]]
            else

                lastTimeObj = new Date @params.startFrom

                switch @scope.currentZoom
                    when 3
                        nextDay = new Date(lastTimeObj.getFullYear(),lastTimeObj.getMonth(), 1).getTime()
                    when 2
                        weekDay = lastTimeObj.getDay()
                        weekDay--
                        weekDay = 6 if weekDay < 0
                        nextDay = new Date(lastTimeObj.getFullYear(),lastTimeObj.getMonth(), lastTimeObj.getDate() - weekDay).getTime()
                    else
                        nextDay = new Date(lastTimeObj.getFullYear(),lastTimeObj.getMonth(), lastTimeObj.getDate()).getTime()
                block =
                    type: 'dayBreak'
                    id: nextDay
                    timestamp: nextDay
                    dayBreakType: separatorType[@scope.currentZoom]
                newSep = @generateSeparator block

                @currepntSeparator = newSep
                currentId = cursor

                @elem.append @currepntSeparator.elem

                setTimeout ->
                    newSep.scope.$applyAsync()
                , 0

                return

        sepKeys = Object.keys @separators
        sepKeys.sort()

        currentId = sepKeys.indexOf @currepntSeparator.block.timestamp + ''

        if @getSepTop(@currepntSeparator) > 0
            cursor = currentId - 1
            found = false
            while cursor >= 0
                sep = @separators[sepKeys[cursor]]
                sep.pos = sep.scrollerElem?.parent().position()
                if !sep.pos?.top? and cursor > 0
                    cursor--
                    continue
                sepTop = @getSepTop(sep)
                if sepTop < 0 or (sepTop == null and cursor == 0)
                    found = true

                    if @currepntSeparator.scrollerElem?
                        @currepntSeparator?.elem.appendTo @currepntSeparator.scrollerElem
                    else
                        @currepntSeparator.elem.detach()
                    @currepntSeparator.elem.css 'top', 0

                    @currepntSeparator = sep
                    currentId = cursor

                    @elem.append @currepntSeparator.elem
                    cursor = -1
                cursor--

            if !found # Add new separator
                switch @scope.currentZoom
                    when 3
                        lastTimeObj = new Date @separators[sepKeys[0]].block.timestamp
                        nextDay = new Date(lastTimeObj.getFullYear(),lastTimeObj.getMonth()-1).getTime()
                    when 2
                        nextDay = @separators[sepKeys[0]].block.timestamp - WEEK
                    else
                        nextDay = @separators[sepKeys[0]].block.timestamp - DAY
                block =
                    type: 'dayBreak'
                    id: nextDay
                    timestamp: nextDay
                    dayBreakType: separatorType[@scope.currentZoom]
                newSep = @generateSeparator block

                @currepntSeparator?.elem.appendTo @currepntSeparator.scrollerElem
                @currepntSeparator.elem.css 'top', 0

                @currepntSeparator = newSep
                currentId = cursor

                @elem.append @currepntSeparator.elem

                setTimeout ->
                    newSep.scope.$applyAsync()
                , 0

        else
            cursor = currentId + 1
            while cursor < sepKeys.length
                sep = @separators[sepKeys[cursor]]
                sep.pos = sep.scrollerElem?.parent().position()
                if !sep.pos?.top?
                    cursor++
                    continue
                if @getSepTop(sep) < 0
                    if @currepntSeparator.scrollerElem?
                        @currepntSeparator?.elem.appendTo @currepntSeparator.scrollerElem
                    else
                        @currepntSeparator.elem.detach()
                    @currepntSeparator.elem.css 'top', 0

                    @currepntSeparator = sep
                    currentId = cursor

                    @elem.append @currepntSeparator.elem
                    # cursor = 0
                cursor++

        # Process next
        if @separators[sepKeys[currentId+1]]?
            sep = @separators[sepKeys[currentId+1]]
            top = @getSepTop(sep)
            if top? and top < 140
                @currepntSeparator.elem.css 'top', top - 140
            else
                @currepntSeparator.elem.css 'top', 0

    switchWithCurrent: (separator) ->
        true

    generateSeparator: (block, page) ->
        # Store separator in scroller
        if !@separators[block.timestamp]?

            # Create dom element
            elem = $ '<div>',
                class: 'novaTimelineDayView'
            sepScope = @scope.$new()
            sepScope.block = block
            # DEBUG
            sepScope.debug = []
            elem = $ $compile(elem)(sepScope)

            @separators[block.timestamp] = {}

            @separators[block.timestamp].elem  = elem
            @separators[block.timestamp].scope = sepScope

        @separators[block.timestamp].block = block
        @separators[block.timestamp].page  = page

        # @currepntSeparator = @separators[block.timestamp] if !@currepntSeparator?

        @separators[block.timestamp]

    buildPage: (page) ->
        page.blocks.length = 0
        page.height = 0

        pocketKeys = Object.keys @pockets
        pocketKeys.sort()

        ruleKeys = (k*1 for k,v of @placeholders) # Object.keys @placeholders
        ruleKeys.sort sortInt

        if page?.query?.from? and page.anchor != 'bottom'
            fromObj = new Date page.query.from
            switch @scope.currentZoom
                when 3
                    # Month
                    curYear = fromObj.getFullYear()
                    curMon = fromObj.getMonth()+1
                    nextDay = new Date(curYear,curMon).getTime()
                    incDay = MONTH

                    nextSub = new Date(fromObj.getFullYear(),fromObj.getMonth(),fromObj.getDate()+1).getTime()
                when 2
                    weekDay = fromObj.getDay()
                    weekDay--
                    weekDay = 6 if weekDay < 0
                    nextSub = new Date(fromObj.getFullYear(),fromObj.getMonth(),fromObj.getDate()+1).getTime()
                    nextDay = nextSub + (6 - weekDay) * DAY
                    incDay = WEEK
                else
                    nextDay = new Date(fromObj.getFullYear(),fromObj.getMonth(),fromObj.getDate()+1).getTime()
                    incDay = DAY
                    nextSub = nextDay

            lastTs = page.query.from

            if @scope.currentZoom < 2 then for key in pocketKeys

                if key*1 > page.query.from

                    while key*1 > nextDay and page.height < @params.pageHeight

                        # [Insert placeholders before first separator]
                        lastTime = new Date lastTs
                        lastDayTs = lastTime.getHours() * HOUR + lastTime.getMinutes() * MIN
                        lastDayStart = new Date(lastTime.getFullYear(), lastTime.getMonth(), lastTime.getDate()).getTime()
                        currentWeekDay = lastTime.getDay()

                        for ruleKey in ruleKeys
                            pHolderTimestamp = lastDayStart + ruleKey

                            # TODO: Check including condition
                            if pHolderTimestamp < lastTs
                                continue
                            if pHolderTimestamp >= nextDay
                                break
                            if page.height > @params.pageHeight
                                break

                            pholderRules = []
                            for rule in @placeholders[ruleKey]
                                if rule.dayMask[currentWeekDay]
                                    pholderRules.push rule.rule

                            if pholderRules.length > 0
                                page.blocks.push
                                    type: 'placeholder'
                                    rules: pholderRules
                                    id: pHolderTimestamp * 1 + 'placeholder' + '_' + @scope.currentZoom
                                    timestamp: pHolderTimestamp
                                page.height += 40
                                lastTs = pHolderTimestamp

                            lastTs = pHolderTimestamp
                        # END [Insert plcaholders berofe first separator]

                        if page.height > @params.pageHeight
                            break

                        # Reached day break
                        block =
                            type: 'dayBreak'
                            id: nextDay + '_' + @scope.currentZoom
                            timestamp: nextDay
                            dayBreakType: separatorType[@scope.currentZoom]
                        @generateSeparator block, page
                        page.blocks.push block

                        page.height += 140
                        lastTs = nextDay

                        # Fix for month incrementing
                        if @scope.currentZoom == 3
                            curMon++
                            nextDay = new Date(curYear,curMon).getTime()
                        else
                            nextDay += incDay

                    if page.height > @params.pageHeight
                        break

                    # [Insert placeholders before first post]
                    lastTime = new Date lastTs
                    lastDayTs = lastTime.getHours() * HOUR + lastTime.getMinutes() * MIN
                    lastDayStart = new Date(lastTime.getFullYear(), lastTime.getMonth(), lastTime.getDate()).getTime()
                    currentWeekDay = lastTime.getDay()

                    for ruleKey in ruleKeys
                        pHolderTimestamp = lastDayStart + ruleKey

                        # TODO: Check including condition
                        if pHolderTimestamp < lastTs
                            continue
                        if pHolderTimestamp >= key*1 or pHolderTimestamp >= nextDay
                            break
                        if page.height > @params.pageHeight
                            break

                        pholderRules = []
                        for rule in @placeholders[ruleKey]
                            if rule.dayMask[currentWeekDay]
                                pholderRules.push rule.rule

                        if pholderRules.length > 0
                            page.blocks.push
                                type: 'placeholder'
                                rules: pholderRules
                                id: pHolderTimestamp * 1 + 'placeholder' + '_' + @scope.currentZoom
                                timestamp: pHolderTimestamp
                            page.height += 40
                            lastTs = pHolderTimestamp

                        lastTs = pHolderTimestamp
                    # END [Insert plcaholders before first post]

                    # Add block to page
                    page.blocks.push
                        type: 'schedule'
                        schedules: @pockets[key]
                        id: key * 1 + 'schedule' + '_' + @scope.currentZoom
                        timestamp: key*1
                    page.height += 40 # if @scope.currentZoom != 0 then 40 else 150
                    lastTs = key*1

                nextSub = nextDay

            # [Insert placeholders after all posts]
            if @scope.currentZoom < 2 and page.height < @params.pageHeight
                lastTime = new Date lastTs
                lastDayTs = lastTime.getHours() * HOUR + lastTime.getMinutes() * MIN
                lastDayStart = new Date(lastTime.getFullYear(), lastTime.getMonth(), lastTime.getDate()).getTime()
                currentWeekDay = lastTime.getDay()

                for ruleKey in ruleKeys
                    pHolderTimestamp = lastDayStart + ruleKey

                    # TODO: Check including condition
                    if pHolderTimestamp <= lastTs
                        continue
                    if pHolderTimestamp >= nextDay or pHolderTimestamp >= nextDay
                        break
                    if page.height > @params.pageHeight
                        break

                    pholderRules = []
                    for rule in @placeholders[ruleKey]
                        if rule.dayMask[currentWeekDay]
                            pholderRules.push rule.rule

                    if pholderRules.length > 0
                        page.blocks.push
                            type: 'placeholder'
                            rules: pholderRules
                            id: pHolderTimestamp * 1 + 'placeholder' + '_' + @scope.currentZoom
                            timestamp: pHolderTimestamp
                        page.height += 40
                        lastTs = pHolderTimestamp

                    lastTs = pHolderTimestamp
            # END [Insert placeholders after all posts]

            while page.height < @params.pageHeight
                if nextSub == nextDay or @scope.currentZoom < 2
                    block =
                        type: 'dayBreak'
                        static: false
                        id: nextSub + '_' + @scope.currentZoom
                        timestamp: nextSub #nextDay
                        dayBreakType: separatorType[@scope.currentZoom]
                    @generateSeparator block, page
                    page.blocks.push block

                if @scope.currentZoom > 1
                    block =
                        type: 'dayBreak'
                        static: true
                        id: nextSub + 'static' + '_' + @scope.currentZoom
                        timestamp: nextSub #nextDay
                        dayBreakType: 'day'
                    page.blocks.push block

                page.height += 140
                lastTs = nextSub #nextDay

                # Fix for month incrementing
                if nextSub == nextDay
                    if @scope.currentZoom == 3
                        curMon++
                        nextDay = new Date(curYear,curMon).getTime()
                    else
                        nextDay += incDay
                nextSub += DAY

                # [Insert placeholders after dayBreak]
                if @scope.currentZoom < 2 and page.height < @params.pageHeight
                    lastTime = new Date lastTs
                    lastDayTs = lastTime.getHours() * HOUR + lastTime.getMinutes() * MIN
                    lastDayStart = new Date(lastTime.getFullYear(), lastTime.getMonth(), lastTime.getDate()).getTime()
                    currentWeekDay = lastTime.getDay()

                    for ruleKey in ruleKeys
                        pHolderTimestamp = lastDayStart + ruleKey

                        # TODO: Check including condition
                        if pHolderTimestamp < lastTs
                            continue
                        if pHolderTimestamp >= nextDay or pHolderTimestamp >= nextDay
                            break
                        if page.height > @params.pageHeight
                            break

                        pholderRules = []
                        for rule in @placeholders[ruleKey]
                            if rule.dayMask[currentWeekDay]
                                pholderRules.push rule.rule

                        if pholderRules.length > 0
                            page.blocks.push
                                type: 'placeholder'
                                rules: pholderRules
                                id: pHolderTimestamp * 1 + 'placeholder' + '_' + @scope.currentZoom
                                timestamp: pHolderTimestamp
                            page.height += 40
                            lastTs = pHolderTimestamp

                        lastTs = pHolderTimestamp
                # END [Insert placeholders after dayBreak]

            page.query.to = lastTs + MIN

        else
            toObj = new Date page.query.to #- MIN
            # nextDay = new Date(toObj.getFullYear(),toObj.getMonth(),toObj.getDate()).getTime()
            switch @scope.currentZoom
                when 3
                    # Month
                    curYear = toObj.getFullYear()
                    curMon = toObj.getMonth()
                    nextDay = new Date(curYear,curMon).getTime()
                    incDay = MONTH
                    nextSub = new Date(toObj.getFullYear(),toObj.getMonth(),toObj.getDate()).getTime()
                when 2
                    weekDay = toObj.getDay()
                    weekDay--
                    weekDay = 6 if weekDay < 0
                    nextSub = new Date(toObj.getFullYear(),toObj.getMonth(),toObj.getDate()).getTime()
                    nextDay = nextSub - (weekDay) * DAY
                    incDay = WEEK
                else
                    nextDay = new Date(toObj.getFullYear(),toObj.getMonth(),toObj.getDate()).getTime()
                    incDay = DAY
                    nextSub = nextDay

            lastTs = page.query.to

            if @scope.currentZoom < 2 then for key in pocketKeys by -1

                if key*1 < page.query.to

                    while key*1 < nextDay and page.height < @params.pageHeight

                        # [Insert placeholders before first separator]
                        lastTime = new Date lastTs
                        lastDayTs = lastTime.getHours() * HOUR + lastTime.getMinutes() * MIN
                        lastDayStart = new Date(lastTime.getFullYear(), lastTime.getMonth(), lastTime.getDate()).getTime()
                        currentWeekDay = lastTime.getDay()

                        for ruleKey in ruleKeys by -1
                            pHolderTimestamp = lastDayStart + ruleKey

                            # TODO: Check including condition
                            if pHolderTimestamp >= lastTs
                                continue
                            if pHolderTimestamp < nextDay
                                break
                            if page.height > @params.pageHeight
                                break

                            pholderRules = []
                            for rule in @placeholders[ruleKey]
                                if rule.dayMask[currentWeekDay]
                                    pholderRules.push rule.rule

                            if pholderRules.length > 0
                                page.blocks.unshift
                                    type: 'placeholder'
                                    rules: pholderRules
                                    id: pHolderTimestamp * 1 + 'placeholder' + '_' + @scope.currentZoom
                                    timestamp: pHolderTimestamp
                                page.height += 40
                                lastTs = pHolderTimestamp

                            lastTs = pHolderTimestamp
                        # END [Insert plcaholders berofe first separator]

                        if page.height > @params.pageHeight
                            break

                        # Reached day break
                        block =
                            type: 'dayBreak'
                            id: nextDay + '_' + @scope.currentZoom
                            timestamp: nextDay
                            dayBreakType: separatorType[@scope.currentZoom]
                        @generateSeparator block, page
                        page.blocks.unshift block

                        page.height += 140
                        lastTs = nextDay

                        # Fix for month incrementing
                        if @scope.currentZoom == 3
                            curMon--
                            nextDay = new Date(curYear,curMon).getTime()
                        else
                            nextDay -= incDay

                    if page.height > @params.pageHeight
                        break

                    # [Insert placeholders before first post]
                    lastTime = new Date lastTs
                    lastDayTs = lastTime.getHours() * HOUR + lastTime.getMinutes() * MIN
                    lastDayStart = new Date(lastTime.getFullYear(), lastTime.getMonth(), lastTime.getDate()-1).getTime()
                    currentWeekDay = lastTime.getDay()

                    for ruleKey in ruleKeys by -1
                        pHolderTimestamp = lastDayStart + ruleKey

                        # TODO: Check including condition
                        if pHolderTimestamp > lastTs
                            continue
                        if pHolderTimestamp < key*1 or pHolderTimestamp < nextDay
                            break
                        if page.height > @params.pageHeight
                            break

                        pholderRules = []
                        for rule in @placeholders[ruleKey]
                            if rule.dayMask[currentWeekDay]
                                pholderRules.push rule.rule

                        if pholderRules.length > 0
                            page.blocks.unshift
                                type: 'placeholder'
                                rules: pholderRules
                                id: pHolderTimestamp * 1 + 'placeholder' + '_' + @scope.currentZoom
                                timestamp: pHolderTimestamp
                            page.height += 40
                            lastTs = pHolderTimestamp

                        lastTs = pHolderTimestamp
                    # END [Insert plcaholders before first post]

                    # Add block to page
                    page.blocks.unshift
                        type: 'schedule'
                        schedules: @pockets[key]
                        timestamp: key*1
                        id: key*1 + 'schedule' + '_' + @scope.currentZoom
                    page.height += 40 # if @scope.currentZoom != 0 then 40 else 150
                    lastTs = key*1

                    nextSub = nextDay

            # [Insert placeholders after all posts]
            if @scope.currentZoom < 2 and page.height < @params.pageHeight
                lastTime = new Date lastTs
                lastDayTs = lastTime.getHours() * HOUR + lastTime.getMinutes() * MIN
                lastDayStart = new Date(lastTime.getFullYear(), lastTime.getMonth(), lastTime.getDate()).getTime()
                currentWeekDay = lastTime.getDay()

                for ruleKey in ruleKeys by -1
                    pHolderTimestamp = lastDayStart + ruleKey

                    # TODO: Check including condition
                    if pHolderTimestamp >= lastTs
                        continue
                    if pHolderTimestamp < nextDay or pHolderTimestamp < nextDay
                        break
                    if page.height > @params.pageHeight
                        break

                    pholderRules = []
                    for rule in @placeholders[ruleKey]
                        if rule.dayMask[currentWeekDay]
                            pholderRules.push rule.rule

                    if pholderRules.length > 0
                        page.blocks.unshift
                            type: 'placeholder'
                            rules: pholderRules
                            id: pHolderTimestamp * 1 + 'placeholder' + '_' + @scope.currentZoom
                            timestamp: pHolderTimestamp
                        page.height += 40
                        lastTs = pHolderTimestamp

                    lastTs = pHolderTimestamp
            # END [Insert placeholders after all posts]

            while page.height < @params.pageHeight
                if @scope.currentZoom > 1
                    block =
                        type: 'dayBreak'
                        static: true
                        id: nextSub + 'static' + '_' + @scope.currentZoom
                        timestamp: nextSub #nextDay
                        dayBreakType: 'day'
                    page.blocks.unshift block

                if nextSub == nextDay or @scope.currentZoom < 2
                    block =
                        type: 'dayBreak'
                        static: false
                        id: nextSub + '_' + @scope.currentZoom
                        timestamp: nextSub #nextDay
                        dayBreakType: separatorType[@scope.currentZoom]
                    @generateSeparator block, page
                    page.blocks.unshift block

                page.height += 140
                lastTs = nextSub

                # Fix for month incrementing
                if nextSub == nextDay
                    if @scope.currentZoom == 3
                        curMon--
                        nextDay = new Date(curYear,curMon).getTime()
                    else
                        nextDay -= incDay
                nextSub -= DAY

                # [Insert placeholders after dayBreak]
                if @scope.currentZoom < 2 and page.height < @params.pageHeight
                    lastTime = new Date lastTs
                    lastDayTs = lastTime.getHours() * HOUR + lastTime.getMinutes() * MIN
                    lastDayStart = new Date(lastTime.getFullYear(), lastTime.getMonth(), lastTime.getDate()-1).getTime()
                    currentWeekDay = lastTime.getDay()

                    for ruleKey in ruleKeys by -1
                        pHolderTimestamp = lastDayStart + ruleKey

                        # TODO: Check including condition
                        if pHolderTimestamp >= lastTs
                            continue
                        if pHolderTimestamp < nextDay
                            break
                        if page.height > @params.pageHeight
                            break

                        pholderRules = []
                        for rule in @placeholders[ruleKey]
                            if rule.dayMask[currentWeekDay]
                                pholderRules.push rule.rule

                        if pholderRules.length > 0
                            page.blocks.unshift
                                type: 'placeholder'
                                rules: pholderRules
                                id: pHolderTimestamp * 1 + 'placeholder' + '_' + @scope.currentZoom
                                timestamp: pHolderTimestamp
                            page.height += 40
                            lastTs = pHolderTimestamp

                        lastTs = pHolderTimestamp
                # END [Insert placeholders after dayBreak]

            page.query.from = lastTs - MIN

        page

    isPageAffected: (page, pocketId) ->
        page.query.from < pocketId*1 < page.query.to

    pickPocket: (item) ->
        item.timestamp

    doFetch: (query, cb) ->
        finalQuery = {}
        updateObject finalQuery, @query

        doQuery = false
        if query.to > @fetched.to
            @fetched.to = query.to
            doQuery = true

        if query.from < @fetched.from or @fetched.from == 0
            @fetched.from = query.from
            doQuery = true

        if doQuery
            lazyLoading.callLazyLoad finalQuery.communityIds, query.from, query.to, cb

    processAffected: (affectedPockets) ->
        if @keypage? and affectedPockets.length > 0

            updateFlags =
                update: false
                updPrev: false
                updNext: false
                updCur: false

            for pocketId in affectedPockets
                if pocketId*1 < @keypage.query.from
                    updateFlags.update = true
                    updateFlags.updPrev = true
                    continue

                if pocketId*1 > @keypage.query.to
                    updateFlags.update = true
                    updateFlags.updNext = true
                    continue

                if @keypage.query.to >= pocketId*1 >= @keypage.query.from
                    updateFlags.update = true
                    updateFlags.updCur = true
                    continue

            if updateFlags.update == false
                return

            if updateFlags.updPrev
                keyIndex = @pages.indexOf @keypage
                if keyIndex > 1
                    @pages.splice 0, keyIndex - 1
                @buildPage @pages[0]

            if updateFlags.updCur
                # @pages.length = 0
                # @pages.push @keypage
                # @buildPage @keypage
                keyIndex = @pages.indexOf @keypage
                if @pages.length > keyIndex + 1
                    @pages.length = keyIndex + 1
                @buildPage @keypage

            else if updateFlags.updNext
                keyIndex = @pages.indexOf @keypage
                if @pages.length > keyIndex + 2
                    @pages.length = keyIndex + 2
                @buildPage @pages[keyIndex+1] if @pages[keyIndex+1]?

        @scroll 0, 'fuck'
        @apply()

    rebuild: (full = false) ->
        for k,sep of @separators
            sep.scope.$destroy()
            sep.elem.remove()
        emptyObject @separators
        @currepntSeparator?.elem?.detach()
        @currepntSeparator = null
        super full

    updatePlaceholders: (@rules) ->
        emptyObject @placeholder
        for rule in @rules
            dO = new Date(rule.timestampStart)
            code = dO.getHours() * HOUR + dO.getMinutes() * MIN
            if !@placeholders[code]? #or !@placeholders[code].combId?
                @placeholders[code] = []

            @placeholders[code].push
                dayMask: rule.dayMask
                start: rule.timestampStart
                end: if rule.end then rule.timestampEnd else false
                combId: rule.combId
                rule: rule
        @rebuild true

novaTimelineScroller
