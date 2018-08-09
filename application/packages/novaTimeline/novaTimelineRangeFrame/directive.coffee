*deps: account, communityService, groupService, updateService, $compile, lazyLoading
*replace: true

elem = $ element
rangeHead = $ elem.find('.rangeHead')[0]
rangeItems = $ elem.find('.rangeItems')[0]

# Frame params
scope.flowFrame.maxWidth = 320

# Range zoom
scope.maxZoom = 0
scope.currentZoom = 0
scope.setZoom = (zoom) ->
    scope.currentZoom = zoom
    rebuildRange()
    setTimeout ->
        scrollToCursor()
    , 0

# Generate header
scope.communityIds = scope.flowFrame.data.communityIds
from = Date.now()
to = from
switch scope.flowFrame.data.type
    when 'month'
        scope.maxZoom = 2
        scope.currentZoom = 2
        monthStart = new Date scope.flowFrame.data.timestamp
        from = scope.flowFrame.data.timestamp
        to = new Date(monthStart.getFullYear(), monthStart.getMonth()+1, 0).getTime()

    when 'week'
        scope.maxZoom = 1
        scope.currentZoom = 1
        from = scope.flowFrame.data.timestamp
        to = from + WEEK - DAY

    when 'day'
        scope.maxZoom = 1
        scope.currentZoom = 0

        from = scope.flowFrame.data.timestamp
        to = from + DAY

# Cursor stuff
# now = new Date()
scope.cursorTime = scope.flowFrame.data.timestamp #new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime()
scope.scrollerParams =
    cursor: scope.cursorTime

headerElem = null
sepScope = null
exCursor = 0
scope.cursorChanged = ->
    update = false

    exDate = new Date exCursor
    nuDate = new Date scope.scrollerParams.cursor

    switch scope.flowFrame.data.type
        when 'month'
            if exDate.getMonth() != nuDate.getMonth() or exDate.getFullYear() != nuDate.getFullYear()
                update = true

                monthStart = new Date nuDate.getFullYear(), nuDate.getMonth(), 1
                from = monthStart.getTime()
                to = new Date(monthStart.getFullYear(), monthStart.getMonth()+1, 0).getTime()

                block =
                    type: 'dayBreak'
                    timestamp: from
                    dayBreakType: 'month'

        when 'week'
            if exDate.getWeekNumber() != nuDate.getWeekNumber() or exDate.getFullYear() != nuDate.getFullYear()
                update = true

                weekDay = nuDate.getDay()
                weekDay--
                weekDay = 6 if weekDay < 0

                block =
                    type: 'dayBreak'
                    timestamp: nuDate.getTime() - (DAY * weekDay)
                    dayBreakType: 'week'

        when 'day'
            if exDate.getTime() != nuDate.getTime()
                update = true

                block =
                    type: 'dayBreak'
                    timestamp: nuDate.getTime()
                    dayBreakType: 'day'

    if update
        headerElem?.remove()
        sepScope?.$destroy()

        headerElem = $ '<div>',
            class: 'novaTimelineDayView'
        sepScope = scope.$new()
        sepScope.block = block

        headerElem = $ $compile(headerElem)(sepScope)
        setTimeout ->
            rangeHead.append headerElem
        , 0

        rebuildRange()

    # Align scroll
    setTimeout ->
        scrollToCursor()
    , 0

# Get schedules
pockets = {}
pocketMap = {}
processSchedule = (item) ->
    if item.deleted == true or item.timestamp < from or item.timestamp > to
        if pocketMap[item.id]?
            removeElementFromArray item, pockets[pocketMap[item.id]]
            delete pocketMap[item.id]
        return

    if !pockets[item.timestamp]?
        pockets[item.timestamp] = []
    pockets[item.timestamp].push item if item not in pockets[item.timestamp]
    pocketMap[item.id] = item.timestamp

lazyLoading.callLazyLoad scope.communityIds, from, to, (items) ->
    for item in items
        processSchedule item
    rebuildRange()

# Range items
scope.items = []
rebuildRange = ->
    scope.items.length = 0

    switch scope.currentZoom
        when 2
            fromObj = new Date from
            dayDiff = fromObj.getDay() - 1
            dayDiff = 6 if dayDiff < 0
            weekStart = new Date(fromObj.getFullYear(),fromObj.getMonth(),fromObj.getDate()-dayDiff).getTime()
            while weekStart < to
                scope.items.push
                    type: 'dayBreak'
                    static: true
                    id: weekStart + 'static' + '_' + scope.currentZoom
                    timestamp: weekStart
                    dayBreakType: 'week'
                weekStart += WEEK
        # when 1
        #     cursor = from
        #     while cursor < to
        #         scope.items.push
        #             type: 'dayBreak'
        #             static: true
        #             id: cursor + 'static' + '_' + scope.currentZoom
        #             timestamp: cursor
        #             dayBreakType: 'day'
        #         cursor += DAY
        else
            pocketKeys = Object.keys pockets
            pocketKeys.sort()

            fromObj = new Date from
            nextDay = new Date(fromObj.getFullYear(),fromObj.getMonth(),fromObj.getDate()).getTime()

            for key in pocketKeys

                if scope.flowFrame.data.type != 'day' then while key > nextDay
                    scope.items.push
                        type: 'dayBreak'
                        static: true
                        id: nextDay + 'static' + '_' + scope.currentZoom
                        timestamp: nextDay
                        dayBreakType: 'day'
                    nextDay += DAY

                scope.items.push
                    type: 'schedule'
                    schedules: pockets[key]
                    id: key * 1
                    timestamp: key * 1

            if scope.flowFrame.data.type != 'day' then while nextDay <= to
                scope.items.push
                    type: 'dayBreak'
                    static: true
                    id: nextDay + 'static' + '_' + scope.currentZoom
                    timestamp: nextDay
                    dayBreakType: 'day'
                nextDay += DAY

searchCursor = ->
    blocks = rangeItems.find '.novaTimelineDayBreak'

    minDiff = 99999999999
    nearest = null
    blocks.each ->
        diff = Math.abs $(@).parent().position().top
        if diff < minDiff
            minDiff = diff
            nearest = @

    if nearest?
        blockScope = angular.element(nearest).scope()
        nuTs = blockScope.block.timestamp
        nuTs = from if nuTs < from
        nuTs = to if nuTs > to
        if scope.scrollerParams.cursor != nuTs
            scope.scrollerParams.cursor = nuTs
            scope.$apply()

scrollToCursor = ->
    blocks = rangeItems.find '.novaTimelineDayBreak'

    minDiff = 99999999999
    nearest = null
    blocks.each ->
        blockScope = angular.element(@).scope()
        diff = Math.abs(scope.scrollerParams.cursor - blockScope.block.timestamp)
        if diff < minDiff
            minDiff = diff
            nearest = @

    if nearest?
        rangeItems[0].scrollTop = rangeItems[0].scrollTop + $(nearest).parent().position().top + 2

# rebuildRange()
scope.cursorChanged()
setTimeout ->
    searchCursor()
, 0

lastCursor = null
rangeItems.on 'mousewheel', (e, delta) ->
    searchCursor()
