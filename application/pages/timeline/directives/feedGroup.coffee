buzzlike
    .directive "feedGroup", (account, desktopService, localization, groupService, communityService, localStorageService, multiselect, lazyLoading, dragMaster, $rootScope, confirmBox, scheduleService, smartDate, $compile, ruleService, inspectorService, updateService) ->
        restrict: 'E'
        replace: true
        template: tC['/pages/timeline/directives/feedGroup']
        link: (scope, element, attrs) ->

            scope.cursor = $(element).find('.timeCursor')

            if !window.groupCnt? then window.groupCnt = 0
            currentCnt = window.groupCnt++

            scope.canRemove = ->
                scope.group.userId == account.user.id

            setGroupStart = (ts) ->
                dateObj = new Date ts

                hours = dateObj.getHours()
                hours /= 3 | 0
                dateObj.setHours hours * 3
                ts = dateObj.getTime()

                scope.group.startDay = ts
                scope.group.date =
                    day: dateObj.getDate()
                    month: localization.translate(154+dateObj.getMonth())[2]
                    date: localization.translate(147+dateObj.getDay())[1]

            # Resources
            # $rootScope.schedular = schedular = scheduleService.storage
            scope.groupSchedules = []
            ruleService.fetchByGroupId scope.group.id

            # Constants
            MIN = 60 * 1000
            postLen = $rootScope.postLen

            postWID = 139
            freeSpaceWID = 360

            # ZoomWork
            zoom = [
                {
                    step: 180 # 420
                    sub: 5
                    zoom: 60 * 3
                }
            ]
            currentZoom = 0
            zoomObj = zoom[currentZoom]

            width = scope.session.size.width + 50
            scope.onResize (wid, hei) ->
                width = wid + 50
                recalculateIntervals()
            , false

            elem = $(element)
            eternityContainer = elem.find '.eternity'
            timelinesContainer = elem.find '.timelines'

            sideWidth = 300

            date_obj = null

            storedStart  = parseInt( localStorageService.get('user.groupStart.'+scope.group.id) )
            storedScroll = parseInt( localStorageService.get('user.groupScroll.'+scope.group.id) )

            if storedStart < (Date.now() - YEAR)
                storedStart = 0

            if storedStart > 0
                setGroupStart storedStart

            if storedScroll > 0
                scope.group.scroll = storedScroll

            glued = scope.group.glued = localStorageService.get('user.groupGlued.'+scope.group.id) | 0

            if account.user.settings.simpleMode
                glued = scope.group.glued = 2

            scope.$watch 'group.glued', (val, oval) ->
                localStorageService.add 'user.groupGlued.'+scope.group.id, val
                if val == 2 or oval == 2
                    keyInterval = null
                    scope.group.scroll = null

                    for int in scope.intervals
                        removeInterval int

                    scope.intervals.length = 0

                    scroll 0
                    recalculateIntervals()
                else
                    recalculateIntervals()
                    scroll(0)

            scope.$watch 'session.zoom', (nVal) ->
                if nVal?
                    switch nVal
                        when 'min'
                            postWID = 70
                            zoomObj.step = 180
                        when 'mid'
                            postWID = 139
                            zoomObj.step = 360
                        when 'max'
                            postWID = 167
                            zoomObj.step = 360

                    recalculateIntervals()
                    scroll 0

            week = [
                147
                148
                149
                150
                151
                152
                153
            ]

            year = [
                154
                155
                156
                157
                158
                159
                160
                161
                162
                163
                164
                165
            ]

            # Globals
            intervalCnt = 0
            keyInterval = null
            group_cIds = []

            scope.group.scroll = null if !scope.group.scroll?
            scope.intervals = []

            # TimeWork
            if !scope.group.startDay?
                today = new Date()
                setGroupStart new Date(today.getFullYear(), today.getMonth(), today.getDate(), 0, 0).getTime() + (24 * 60 * MIN)

            # CalendarWork
            date_block = elem.find 'div.date'
            date_block.bind 'click', () ->
                scope.opened = true
                true

            # Event handling Work
            upd_cnt = 0
            # scope.$watch 'schedular', (nVal, oVal) ->

            #     # Check if changed
            #     changed = false
            #     for k,nS of nVal
            #         if nS.communityId in group_cIds
            #             oS = oVal[k]
            #             if  !oS? or
            #                 nS.communityId != oS.communityId or
            #                 nS.timestamp != oS.timestamp or
            #                 nS.repost != oS.repost or
            #                 nS.deleted != oS.deleted
            #                     changed = true

            #     for k,oS of oVal
            #         if oS.communityId in group_cIds
            #             nS = nVal[k]
            #             if  !nS? or
            #                 nS.communityId not in group_cIds or
            #                 nS.collapsed != oS.collapsed or
            #                 nS.repost != oS.repost or
            #                 nS.deleted != oS.deleted
            #                     changed = true

            #     if changed
            #         recalculateIntervals()
            #         scroll(0)
            # , true

            scope.$watch () ->
                ruleService.byGroupId[scope.group.id]
            , (nVal, oVal) ->

                recalculateIntervals()
                scroll(0)

            , true

            scope.$watch 'group.feeds', (nVal) ->
                buildTimelines(nVal)

                group_cIds = scope.group.feeds.map (elem) ->
                    elem.communityId

                keyInterval = null

                for int in scope.intervals
                    removeInterval int

                scope.intervals.length = 0

                recalculateIntervals()
                scroll(0)
            , true

            scope.$watch () ->
                smartDate.state
            , (nVal, oVal) ->
                recalculateIntervals()
                scroll(0)
            , true

            timelinesCache = {}
            buildTimelines = (feeds) ->
                for own key, tl of timelinesCache
                    tl.scope.$destroy()
                    tl.element.remove()

                emptyObject timelinesCache

                total = feeds.length
                for feed,i in feeds
                    newscope = scope.$new()
                    newscope.lineId = feed.communityId
                    newscope.status = feed.statusAsInt
                    #blog feed
                    feedTimeline = $compile('<feed-timeline></feed-timeline>')(newscope)
                    intervalsContainer = $(feedTimeline).children('ul.intervals')

                    feedTimeline.css
                        zIndex: total-i

                    timeBar = $(feedTimeline).children 'div.timebar'
                    touchBar = $(feedTimeline).children 'div.touchBar'

                    timelinesCache[feed.communityId] =
                        scope: newscope
                        element: feedTimeline
                        intervals: intervalsContainer
                        timebar: timeBar
                        touchBar: touchBar

                    timelinesContainer.append feedTimeline

            scroll = (val) ->
                if $.isEmptyObject(timelinesCache) then return

                maxRight = -width * 80
                minLeft = width * 80
                maxTime = 0
                minTime = getBigTimestamp()

                minDeltaCenter = 999999

                toRemove = []
                for interval in scope.intervals
                    interval.left -= Math.floor val

                    # Check if remove
                    if interval.left + interval.width < - sideWidth or interval.left > width + sideWidth
                        toRemove.push interval
                        continue

                    for timeline in interval.timelines
                        $(timeline.element).css
                            "transform": 'translate3d('+interval.left + 'px, 0, 0)'
                            "width": interval.width + 'px'

                    $(interval.eternity).css
                        "transform": 'translate3d('+interval.left + 'px, 0, 0)'
                        "width": interval.width + 'px'

                    right = interval.left + interval.width
                    if right > maxRight
                        maxRight = right
                        maxTime = interval.to

                    if interval.left < minLeft || minLeft == null
                        minLeft = interval.left
                        minTime = interval.from

                    if Math.abs( width / 2 - interval.left) < minDeltaCenter
                        minDeltaCenter = Math.abs( width / 2 - interval.left )
                        keyInterval = interval
                        setGroupStart keyInterval.from
                        scope.group.scroll = keyInterval.left


                localStorageService.add 'user.groupStart.'+scope.group.id, scope.group.startDay
                localStorageService.add 'user.groupScroll.'+scope.group.id, scope.group.scroll

                changed = false
                # Removing
                for int in toRemove
                    removeInterval int

                    index = scope.intervals.indexOf int
                    scope.intervals.splice(index,1)
                    changed = true

                if maxTime == 0
                    maxTime = scope.group.startDay
                    if scope.group.glued*1 == 2
                        dObj = new Date maxTime
                        maxTime = new Date(dObj.getFullYear(), dObj.getMonth(),dObj.getDate()).getTime()
                    maxRight = Math.floor width/2
                    if scope.group.scroll != null #and scope.intervals.length == 0
                        maxRight = scope.group.scroll
                if minTime == getBigTimestamp()
                    minTime = scope.group.startDay
                    minLeft = Math.floor width/2 # - scope.group.scroll
                    if scope.group.scroll != null #and scope.intervals.length == 0
                        minLeft = scope.group.scroll

                # Adding right
                while maxRight < width + sideWidth
                    newInt = addInterval maxTime, maxRight
                    maxRight += newInt.width
                    maxTime = newInt.to

                    changed = true

                    if !keyInterval? then keyInterval = newInt

                # Adding left
                if minLeft then while minLeft > - sideWidth
                    if scope.group.glued == 2
                        minTime -= DAY
                    else
                        minTime -= DAY / 8
                    newInt = addInterval minTime, minLeft, true
                    minLeft -= newInt?.width

                    changed = true

                if changed
                    inspectorService.appendHandlers scope.intervals

            updateSchedulesPosition = () ->
                $('.feedItem').each () ->
                    elem_scope = angular.element(@).scope()
                    elem_scope.recalc?()

            recalculateIntervals = () ->
                if $.isEmptyObject(timelinesCache) then return

                intervals = scope.intervals
                intSize = intervals.length
                if intSize == 0
                    keyInterval = null
                    return false

                if !keyInterval?
                    scroll 0
                    intSize = intervals.length

                rightSide = keyInterval.left
                leftSide = keyInterval.left

                # Push right
                index = intervals.indexOf keyInterval
                for i in [index...intSize]
                    interval = intervals[i]
                    if !interval? then continue
                    fillDay interval
                    for timeline in interval.timelines
                        timeline.scope.schedular = interval.communityCache[timeline.id]
                    interval.left = rightSide
                    rightSide += interval.width

                # Push left
                if index > 0 then for i in [index-1..0]
                    interval = intervals[i]
                    if !interval? then continue
                    fillDay interval
                    for timeline in interval.timelines
                        timeline.scope.schedular = interval.communityCache[timeline.id]
                    interval.left = leftSide - interval.width
                    leftSide -= interval.width

                updateSchedulesPosition()

            addIntervalLong = (startTime, left, back) ->
                # Fill interval parts
                intervalTime = new Date startTime
                dateInfo =
                    day: intervalTime.getDate()
                    month: year[intervalTime.getMonth()]
                    weekDay: week[intervalTime.getDay()]
                    year: intervalTime.getFullYear()

                eternity = $ '<li>',
                    class: 'interval liveInterval'

                parts = []
                el = $ '<div>',
                    class: 'part'

                startDay = false
                if intervalTime.getHours() == 0 and intervalTime.getMinutes() == 0

                    startDay = true
                    # ng_part = $ tC['/pages/timeline/eternity/dayBreak']
                    # ng_part_children = ng_part.children()

                    # localization.onLangLoaded () ->
                    #     $(ng_part_children[0]).html localization.translate(dateInfo.weekDay)[0]
                    #     $(ng_part_children[1]).html dateInfo.day
                    #     $(ng_part_children[2]).html localization.translate(dateInfo.month)[0]
                    #     $(ng_part_children[3]).html dateInfo.year

                    parts.push
                        type: 'dayBreak'
                        left: 0
                        width: 0
                        free: false
                        time: startTime
                        timeEnd: startTime
                        humanTime: humanTime(startTime)
                        timeInfo: dateInfo
                        element: el

                    el.css
                        width: postWID #150
                        left: 0
                
                    el.append ng_part if ng_part
                    eternity.append el
                else
                    console.log 'Incorrect time', intervalTime
                    return

                intervalLength = DAY
                partsCnt = 1 #intervalLength / ( zoomObj.zoom * MIN )
                #for i in [0...partsCnt]

                el = $ '<div>',
                    class: 'part'

                ng_part = $ tC['/pages/timeline/eternity/freePlace']

                newpart =
                    type: 'regular'
                    left: 0
                    width: 0
                    free: true
                    time: startTime #+ ( (zoomObj.zoom * 60 * 1000) * i )
                    timeEnd: startTime + intervalLength #( (zoomObj.zoom * 60 * 1000) * ( i + 1 ) )
                    marks: []
                    element: el
                    bars: ng_part

                parts.push newpart

                el.append ng_part
                eternity.append el

                newInt =
                    from: startTime
                    to: startTime + intervalLength
                    id: intervalCnt
                    parts: parts
                    eternity: eternity

                fillDay newInt

                if back == true
                    newInt.left = left - newInt.width
                else
                    newInt.left = left

                if back == true
                    eternityContainer.prepend eternity
                else
                    eternityContainer.append eternity

                newInt.timelines = []

                # Add DOM Eternity
                for own key, tl of timelinesCache
                    newscope = tl.scope.$new()
                    newscope.interval = newInt
                    newscope.cId = key
                    newscope.schedular = newInt.communityCache[key]
                    newscope.timebar = tl.timebar
                    newscope.touchBar = tl.touchBar
                    newscope.startDay = startDay
                    newscope.dateInfo = dateInfo

                    # Add DOM Interval
                    el2 = $compile('<div class="feedInterval"/>')(newscope)

                    newInt.timelines.push
                        id: key
                        element: el2
                        scope: newscope

                    if back == true
                        tl.intervals.prepend el2
                    else
                        tl.intervals.append el2

                    $(el2).css
                        "transform": 'translateX('+newInt.left + 'px)'
                        "width": newInt.width + 'px'

                if back == true
                    scope.intervals.unshift newInt
                else
                    scope.intervals.push newInt

                $(eternity).css
                    "transform": 'translateX('+newInt.left + 'px)'
                    "width": newInt.width + 'px'

                intervalCnt++

                # Lazy Load (YEAH!!!)
                cIds = scope.group.feeds.map (elem) ->
                    elem.communityId

                lazyLoading.callLazyLoad cIds, startTime, startTime + intervalLength, processItems

                newInt

            addInterval = (startTime, left, back) ->
                if scope.group.glued == 2
                    return addIntervalLong startTime, left, back

                # Fill interval parts
                intervalTime = new Date startTime
                dateInfo =
                    day: intervalTime.getDate()
                    month: year[intervalTime.getMonth()]
                    weekDay: week[intervalTime.getDay()]
                    year: intervalTime.getFullYear()

                eternity = $ '<li>',
                    class: 'interval liveInterval'

                parts = []
                el = $ '<div>',
                    class: 'part'

                startDay = false
                if intervalTime.getHours() == 0 and intervalTime.getMinutes() == 0

                    startDay = true
                    # ng_part = $ tC['/pages/timeline/eternity/dayBreak']
                    # ng_part_children = ng_part.children()

                    # localization.onLangLoaded () ->
                    #     $(ng_part_children[0]).html localization.translate(dateInfo.weekDay)[0]
                    #     $(ng_part_children[1]).html dateInfo.day
                    #     $(ng_part_children[2]).html localization.translate(dateInfo.month)[0]
                    #     $(ng_part_children[3]).html dateInfo.year

                    parts.push
                        type: 'dayBreak'
                        left: 0
                        width: 0
                        free: false
                        time: startTime
                        timeEnd: startTime
                        humanTime: humanTime(startTime)
                        timeInfo: dateInfo
                        element: el

                    el.css
                        width: postWID #150
                        left: 0
                else
                    ng_part = $ tC['/pages/timeline/eternity/hourMark']
                    $(ng_part).html humanTime(startTime)

                    el.append ng_part
                    eternity.append el

                    parts.push
                        type: 'hourMark'
                        left: 0
                        width: 0
                        free: false
                        time: startTime 
                        timeEnd: startTime 
                        humanTime: humanTime(startTime) # part_scope.humanTime
                        element: el
                
                el.append ng_part if ng_part
                eternity.append el

                intervalLength = DAY / 8
                partsCnt = intervalLength / ( zoomObj.zoom * MIN )
                #for i in [0...partsCnt]

                el = $ '<div>',
                    class: 'part'

                ng_part = $ tC['/pages/timeline/eternity/freePlace']

                newpart =
                    type: 'regular'
                    left: 0
                    width: 0
                    free: true
                    time: startTime #+ ( (zoomObj.zoom * 60 * 1000) * i )
                    timeEnd: startTime + intervalLength #( (zoomObj.zoom * 60 * 1000) * ( i + 1 ) )
                    marks: []
                    element: el
                    bars: ng_part

                parts.push newpart

                el.append ng_part
                eternity.append el

                newInt =
                    from: startTime
                    to: startTime + intervalLength
                    id: intervalCnt
                    parts: parts
                    eternity: eternity

                fillDay newInt

                if back == true
                    newInt.left = left - newInt.width
                else
                    newInt.left = left

                if back == true
                    eternityContainer.prepend eternity
                else
                    eternityContainer.append eternity

                newInt.timelines = []

                # Add DOM Eternity
                for own key, tl of timelinesCache
                    newscope = tl.scope.$new()
                    newscope.interval = newInt
                    newscope.cId = key
                    newscope.schedular = newInt.communityCache[key]
                    newscope.timebar = tl.timebar
                    newscope.touchBar = tl.touchBar
                    newscope.startDay = startDay
                    newscope.dateInfo = dateInfo

                    # Add DOM Interval
                    el2 = $compile('<div class="feedInterval"/>')(newscope)

                    newInt.timelines.push
                        id: key
                        element: el2
                        scope: newscope

                    if back == true
                        tl.intervals.prepend el2
                    else
                        tl.intervals.append el2

                    $(el2).css
                        "transform": 'translateX('+newInt.left + 'px)'
                        "width": newInt.width + 'px'

                if back == true
                    scope.intervals.unshift newInt
                else
                    scope.intervals.push newInt

                $(eternity).css
                    "transform": 'translateX('+newInt.left + 'px)'
                    "width": newInt.width + 'px'

                intervalCnt++

                # Lazy Load (YEAH!!!)
                cIds = scope.group.feeds.map (elem) ->
                    elem.communityId

                lazyLoading.callLazyLoad cIds, startTime, startTime + intervalLength, processItems

                newInt

            processItems = (items) ->
                # console.log 'arrived', currentCnt, items

                cIds = scope.group.feeds.map (elem) ->
                    elem.communityId

                for item in items
                    if item.type != 'schedule'
                        continue

                    if item.communityId in cIds
                        scope.groupSchedules.push item if item not in scope.groupSchedules
                    else
                        removeElementFromArray item, scope.groupSchedules

                recalculateIntervals()
                scroll(0)

            updateId = updateService.registerUpdateHandler (data, action, items) ->
                if action in ['update','create']
                    if data['schedule']?
                        processItems items
                        scope.$apply()

            scope.$on '$destroy', ->
                updateService.unRegisterUpdateHandler updateId

            stackToLoad =
                communities: []
                start: getBigTimestamp()
                end: 0
                handler: false

            cacheBlocks = (from, to) ->
                blkCache = {}
                communityCache = {}

                from_obj = new Date from
                fromDate = new Date(from_obj.getFullYear(), from_obj.getMonth(), from_obj.getDate()).getTime()

                offset = {}
                for commId in group_cIds
                    offset[commId] =
                        start: 0
                        end: postLen

                nOff = 0

                scheduled = []

                for k,v of scope.groupSchedules
                    if v.deleted == true
                        continue
                    if v.communityId in group_cIds
                        shiftTime = smartDate.getShiftTimeBar(v.timestamp)
                        if v.collapsed != true
                            if (shiftTime >= from and shiftTime < to)
                                if !communityCache[v.communityId]? then communityCache[v.communityId] = []
                                communityCache[v.communityId].push v
                                scheduled.push v

                            # Prepare minutes time for transparent logic
                            mFrom = justMinutes(from)
                            mTo = justMinutes(to)
                            mTime = justMinutes(shiftTime)

                            if mFrom - mTime <= postLen and mFrom > mTime
                                nOff = postLen - mFrom + mTime
                                if nOff > offset[v.communityId].start then offset[v.communityId].start = nOff
                            if mTime - mTo <= postLen and mTo <= mTime
                                nOff = mTime - mTo
                                if nOff < offset[v.communityId].end then offset[v.communityId].end = nOff

                for s_data in scheduled
                    if s_data.rule
                        delete s_data.rule
                    shiftTime = smartDate.getShiftTimeBar(s_data.timestamp)
                    if !blkCache[shiftTime]? then blkCache[shiftTime] = []
                    blkCache[shiftTime].push
                        type: 'schedule'
                        scheduled: s_data
                        communityId: s_data.communityId

                ts = new Date().getTime() # + ( 6 * MIN )
                nowShift = smartDate.getShiftTimeBar(ts)
                # Get mediaplan placeholders
                # Get rules for WHOLE GROUP
                rules = ruleService.byGroupId[scope.group.id] or []
                for id in group_cIds

                    for rule in rules
                        # Borders
                        shiftStart = smartDate.getShiftTimeBar rule.timestampStart

                        if shiftStart >= to
                            continue

                        if rule.end == true and rule.timestampEnd?
                            shiftEnd = smartDate.getShiftTimeBar rule.timestampEnd
                            if shiftEnd < from
                                continue

                        # Display different types
                        switch rule.ruleType
                            when 'single'
                                shiftTime = smartDate.getShiftTimeBar(rule.timestampStart)

                                if shiftTime < nowShift
                                    continue

                                canPlace = true
                                if !blkCache[shiftTime]? then blkCache[shiftTime] = [] else
                                    for cachedBlock in blkCache[shiftTime]
                                        if cachedBlock.communityId == id #rule.communityId
                                            cachedBlock.pholder = 
                                                rule: rule
                                                type: 'placeholder'
                                                ruleType: rule.ruleType
                                                communityId: id
                                                groupId: scope.group.id
                                                id: 0
                                            canPlace = false
                                            break

                                if !canPlace then continue

                                if shiftTime >= from and shiftTime < to
                                    newPlaceholder =
                                        rule: rule
                                        type: 'placeholder'
                                        ruleType: rule.ruleType
                                        timestamp: rule.timestampStart
                                        communityId: id
                                        groupId: scope.group.id
                                        id: 0

                                    if !communityCache[id]? then communityCache[id] = []
                                    communityCache[id].push newPlaceholder

                                    blkCache[shiftTime].push
                                        type: 'placeholder'
                                        placeholder: newPlaceholder
                                        groupId: scope.group.id
                                        communityId: id #rule.communityId
                            when 'chain'
                                if !rule.interval? then continue
                                placeholderDuration = ( (rule.interval) * MIN )

                                shiftStart = smartDate.getShiftTimeBar(rule.timestampStart)
                                shiftEnd = to

                                startFrom = 0

                                if rule.end == true and rule.timestampEnd?
                                    shiftEnd = smartDate.getShiftTimeBar(rule.timestampEnd)
                                    if shiftEnd < from then continue

                                if shiftStart < from
                                    diff = from - shiftStart

                                    number = diff / placeholderDuration
                                    numberInt = number | 0

                                    if number > numberInt then numberInt++

                                    shiftStart = shiftStart + (numberInt * placeholderDuration)

                                    startFrom = numberInt

                                if shiftEnd > to then shiftEnd = to

                                for phTime in [shiftStart...shiftEnd] by placeholderDuration

                                    if phTime < nowShift
                                        startFrom++
                                        continue

                                    canPlace = true
                                    if !blkCache[phTime]? then blkCache[phTime] = [] else
                                        for cachedBlock in blkCache[phTime]
                                            if cachedBlock.communityId == id #rule.communityId
                                                cachedBlock.pholder = 
                                                    rule: rule
                                                    type: 'placeholder'
                                                    ruleType: rule.ruleType
                                                    communityId: id
                                                    groupId: scope.group.id
                                                    id: startFrom
                                                canPlace = false
                                                startFrom++
                                                break

                                            # if cachedBlock.placeholder?.rule?.id == rule.id
                                            #     canPlace = false
                                            #     break

                                    if !canPlace then continue

                                    normalTime = smartDate.resetShiftTimeBar(phTime)

                                    newPlaceholder =
                                        id: startFrom
                                        rule: rule
                                        type: 'placeholder'
                                        ruleType: rule.ruleType
                                        timestamp: normalTime
                                        communityId: id
                                        groupId: scope.group.id

                                    startFrom++

                                    if !communityCache[id]? then communityCache[id] = []
                                    communityCache[id].push newPlaceholder

                                    blkCache[phTime].push
                                        type: 'placeholder'
                                        placeholder: newPlaceholder
                                        communityId: id #rule.communityId
                                        groupId: scope.group.id

                            when 'daily'
                                # Parse time and date
                                shiftRuleStart = smartDate.getShiftTimeBar(rule.timestampStart)
                                date_obj = new Date shiftRuleStart
                                date_time = ( date_obj.getHours() * 60 + date_obj.getMinutes() ) * MIN
                                date_date = new Date( date_obj.getFullYear(), date_obj.getMonth(), date_obj.getDate() ).getTime()

                                from_obj = new Date from
                                from_startDay = new Date(from_obj.getFullYear(), from_obj.getMonth(), from_obj.getDate()).getTime()

                                if fromDate + date_time < from or fromDate + date_time >= to
                                    continue

                                shiftStart = date_date
                                shiftTime = fromDate + date_time

                                if rule.end == true and rule.timestampEnd?
                                    if from + date_time >= shiftEnd
                                        continue

                                if shiftTime < nowShift
                                    continue

                                day = new Date(shiftTime).getDay()
                                if !rule.dayMask[day]
                                    continue
                                else
                                    canPlace = true
                                    if !blkCache[shiftTime]? then blkCache[shiftTime] = [] else
                                        for cachedBlock in blkCache[shiftTime]
                                            if cachedBlock.communityId == id #rule.communityId
                                                cachedBlock.pholder = 
                                                    rule: rule
                                                    type: 'placeholder'
                                                    ruleType: rule.ruleType
                                                    communityId: id
                                                    groupId: scope.group.id
                                                    id: 0
                                                canPlace = false
                                                break
                                            # if cachedBlock.placeholder?.rule?.id == rule.id
                                            #     canPlace = false
                                            #     break

                                    if !canPlace then continue

                                    # Get order number
                                    diff = from - shiftStart
                                    number = diff / ( 24 * 60 * MIN )
                                    numberInt = number | 0

                                    # if number > numberInt then numberInt++

                                    #console.log new Date(from), new Date(from + date_time), new Date(smartDate.resetShiftTimeBar(from))

                                    normalTime = smartDate.resetShiftTimeBar(fromDate + date_time)
                                    
                                    newPlaceholder =
                                        id: numberInt
                                        rule: rule
                                        type: 'placeholder'
                                        ruleType: rule.ruleType
                                        timestamp: normalTime
                                        communityId: id
                                        groupId: scope.group.id

                                    if !communityCache[id]? then communityCache[id] = []
                                    communityCache[id].push newPlaceholder

                                    blkCache[shiftTime].push
                                        type: 'placeholder'
                                        placeholder: newPlaceholder
                                        communityId: id # rule.communityId
                                        groupId: scope.group.id

                {
                    blkCache
                    communityCache
                    offset
                }

            humanTime = (ts) ->
                date = new Date ts

                hours = date.getHours()
                min = date.getMinutes()

                if hours < 10 then hours = '0' + hours
                if min < 10 then min = '0' + min

                hours + ':' + min

            fillDay = (interval) ->
                startTime = interval.from
                endTime = interval.to

                blkCacheExt = cacheBlocks(startTime, endTime)
                blkCache = blkCacheExt.blkCache

                interval.blkCache = blkCacheExt.blkCache
                interval.communityCache = blkCacheExt.communityCache

                nextTime = startTime
                nextCoord = 0

                if scope.group.glued == 2
                    intLen = DAY / MIN
                else
                    intLen = zoomObj.zoom

                minWid = postWID #150
                postWidth = postWID #150

                waitingBlocks = []
                simple = false

                intervalTime = new Date startTime
                dateInfo =
                    day: intervalTime.getDate()
                    month: year[intervalTime.getMonth()]
                    weekDay: week[intervalTime.getDay()]
                    year: intervalTime.getFullYear()

                # Day break
                currentPart = interval.parts[0]
                if currentPart.type == 'dayBreak' #.humanTime == '00:00'

                    break_width = 100
                    # if scope.group.glued
                    #     break_width = 120

                    currentPart.left = nextCoord
                    currentPart.width = break_width
                    currentPart.element.css
                        width: break_width

                    nextCoord += break_width
                else

                    switch scope.group.glued*1
                        when 1
                            currentPart.width = 120
                        when 2
                            currentPart.width = 0
                        else
                            currentPart.width = 100

                    currentPart.element.css
                        width: currentPart.width
                        left: currentPart.left

                    nextCoord += currentPart.width

                partCnt = 1
                zIndex = 100
                while nextTime < endTime
                    currentPart = interval.parts[partCnt]
                    if !currentPart? then continue
                    currentPart.left = nextCoord
                    currentPart.marks = []
                    currentPart.posts = []
                    currentPart.startOffset = 0
                    currentPart.offset = 0

                    currentPart.bars.empty()

                    for wBlk in waitingBlocks
                        wBlk.elem.noRight = true

                        # currentPart.posts.push
                        #     left: wBlk.elem.startCoord
                        #     width: wBlk.elem.startCoord + 150
                        #     time: wBlk.elem.startTime
                        #     timeEnd: wBlk.elem.startTime + ( postLen * 60 * 1000 )

                    simple = true

                    # get offset
                    offset = 0
                    if partCnt == 1
                        offset = 0 # blkCacheExt.offset.start
                    else
                        offset = currentPart.offset

                    # if offset > 0
                    #     simple = false
                    #     nextTime += offset * 60 * 1000
                    #     intLen = zoomObj.zoom - offset

                    barTime = nextTime
                    endScheds = 0
                    firstPost = true
                    for i in [0...intLen]
                        timeCursor = nextTime + (i * 1000 * 60)
                        exPost = null

                        toPlace = blkCache[ timeCursor ]

                        toRemove = []
                        wasWaiting = false
                        newArray = []
                        justEnded = false
                        # for wBlk in waitingBlocks
                        #     # console.log wBlk.elem
                        #     wBlk.elem.noRight = true

                        #     currentPart.posts.push
                        #         left: wBlk.elem.startCoord
                        #         width: wBlk.elem.startCoord + 150
                        #         time: wBlk.elem.startTime
                        #         timeEnd: wBlk.elem.startTime + ( postLen * 60 * 1000 )
                            # if wBlk.startTime + (postLen * 1000 * 60) == timeCursor
                            #     justEnded = true
                            #     if !wasWaiting and nextCoord - wBlk.startCoord < postWidth
                            #         nextCoord += postWidth/2
                            #         markSet = false
                            #     wasWaiting = true
                            #     wBlk.elem.width = nextCoord - wBlk.startCoord
                            # else
                            #     newArray.push wBlk

                        waitingBlocks = newArray

                        if toPlace? and waitingBlocks.length == 0
                            simple = false

                            delta = timeCursor - barTime
                            if delta >= ( postLen * 60 * 1000 )
                                delta = timeCursor - barTime
                                size = ( intLen * 1000 * 60) / 12
                                barWidth = Math.floor(zoomObj.step / 12)

                                count = Math.floor(delta / size)
                                if endScheds != 0
                                    if count < 2 then count = 2
                                else
                                    if count < 1 then count = 1

                                if i == 0
                                    count = 1

                                size = Math.floor(delta / count)

                                locked = false
                                if scope.group.glued
                                    count = 0
                                    # if firstPost and barTime < interval.from + (3 * 60 * 60 * 1000)
                                    #     count = 1
                                    #     barWidth = 20
                                    #     locked = true

                                # if firstPost and blkCacheExt.offset.start > 0 and partCnt == 1
                                #     count = 0

                                if !firstPost
                                    new_bar = $ tC['/pages/timeline/eternity/marks/regular']
                                    new_bar.css
                                        left: endScheds - ( barWidth )
                                        width: barWidth

                                currentPart.bars.append new_bar

                                for j in [0...count]
                                    if j == count-1
                                        endtime = timeCursor
                                    else
                                        endtime = barTime + size

                                    currentPart.marks.push
                                        left: endScheds + ( barWidth * j )
                                        width: barWidth
                                        time: barTime
                                        timeEnd: endtime
                                        locked: locked

                                    new_bar = $ tC['/pages/timeline/eternity/marks/regular']
                                    new_bar.css
                                        left: endScheds + ( barWidth * j )
                                        width: barWidth

                                    currentPart.bars.append new_bar

                                    barTime = endtime
                                    nextCoord += barWidth

                                endScheds += barWidth * count
                            else
                                barTime = timeCursor # - ( postLen * 60 * 1000 )
                                currentPart.startOffset = delta / MIN

                            barTime += ( postLen * 60 * 1000 )

                            if exPost != null
                                exPost.noRight = true

                            for elem in toPlace

                                currentPart.posts.push
                                    left: endScheds
                                    width: postWidth
                                    time: timeCursor
                                    timeEnd: timeCursor + ( postLen * MIN )
                                    communityId: elem.communityId

                                if elem.type == 'schedule'
                                    waitingBlocks.push
                                        elem: elem.scheduled
                                        startTime: timeCursor
                                        startCoord: nextCoord
                                        type: elem.type

                                    if !elem.scheduled.left?
                                        elem.scheduled.left = {}

                                    if !elem.scheduled.pholders?
                                        elem.scheduled.pholders = {}

                                    elem.scheduled.left[scope.group.id] = nextCoord
                                    elem.scheduled.pholders[scope.group.id] = elem.pholder
                                    elem.scheduled.width = postWidth
                                    elem.scheduled.zindex = zIndex
                                    
                                    elem.scheduled.timeStart = timeCursor
                                    elem.scheduled.timeEnd = timeCursor + (postLen*MIN)

                                    elem.scheduled.noRight = timeCursor + ( postLen * 60 * 1000 ) > interval.to
                                    elem.scheduled.noLeft = if scope.group.glued*1 == 2 then false else i == 0

                                    elem.scheduled.humanStartTime = getHumanDate(timeCursor).time
                                    elem.scheduled.humanEndTime = getHumanDate(timeCursor + (postLen*MIN)).time

                                if elem.type == 'placeholder'
                                    waitingBlocks.push
                                        elem: elem.placeholder
                                        startTime: timeCursor
                                        startCoord: nextCoord
                                        type: elem.type

                                    if !elem.placeholder.left?
                                        elem.placeholder.left = {}

                                    elem.placeholder.left[scope.group.id] = nextCoord
                                    elem.placeholder.width = postWidth
                                    elem.placeholder.zindex = zIndex

                                    elem.placeholder.timeStart = timeCursor
                                    elem.placeholder.timeEnd = timeCursor + (postLen*MIN)
                                    
                                    elem.placeholder.noRight = timeCursor + ( postLen * 60 * 1000 ) > interval.to
                                    elem.placeholder.noLeft = (i == 0 and timeCursor == currentPart.from)

                                    elem.placeholder.humanStartTime = getHumanDate(timeCursor).time
                                    elem.placeholder.humanEndTime = getHumanDate(timeCursor + (postLen*MIN)).time


                                zIndex++

                            endScheds += postWidth
                            firstPost = false
                            nextCoord += postWidth

                    if simple
                        currentPart.type = 'freePlace'

                        currentPart.bars.empty().addClass('freeMarks') #.html tC['/pages/timeline/eternity/marks/free']

                        if scope.group.glued
                            currentPart.width = 0
                            #nextCoord += 1
                        else
                            currentPart.width = zoomObj.step
                            nextCoord += zoomObj.step

                    else
                        currentPart.type = 'regular'

                        currentPart.bars.removeClass('freeMarks')

                        delta = nextTime + ( intLen * 1000 * 60) - barTime
                        size = ( intLen * 1000 * 60) / 12
                        barWidth = Math.floor(zoomObj.step / 12)

                        count = Math.floor(delta / size)
                        if count < 1 then count = 1

                        locked = false
                        if scope.group.glued
                            if scope.group.glued
                                count = 0
                            # if scope.group.glued*1 == 1
                            #     count = 1
                            #     locked = true
                            #     barWidth = 20

                            # if scope.group.glued*1 == 2
                            #     count = 0
                            #     if barTime > (interval.from + (21*60*60*1000))
                            #         count = 1
                            #         locked = true
                            #         barWidth = 20

                        if barTime > currentPart.timeEnd
                            count = 0
                            interval.parts[partCnt+1]?.realTime = (barTime - currentPart.timeEnd) / (60 * 1000) | 0
                            interval.parts[partCnt+2]?.offset = (barTime - currentPart.timeEnd) / (60 * 1000) | 0
                        else
                            if interval.parts[partCnt+1]?.realTime?
                                delete interval.parts[partCnt+1].realTime

                            if interval.parts[partCnt+2]?.offset?
                                delete interval.parts[partCnt+2].offset

                        if count > 0 then size = Math.floor(delta / count)

                        new_bar = $ tC['/pages/timeline/eternity/marks/regular']
                        new_bar.css
                            left: endScheds - ( barWidth )
                            width: barWidth

                        currentPart.bars.append new_bar

                        for j in [0...count]

                            barTimeEnd = barTime + size

                            if j == count-1 # and barTimeEnd > (interval.from + (21*60*60*1000))
                                barTimeEnd = currentPart.timeEnd - (60*1000)

                            currentPart.marks.push
                                left: endScheds + ( barWidth * j )
                                width: barWidth
                                time: barTime
                                timeEnd: barTimeEnd
                                hide: j == count-1
                                free: delta > 0
                                locked: locked

                            if j != count-1
                                new_bar = $ tC['/pages/timeline/eternity/marks/regular']
                                new_bar.css
                                    left: endScheds + ( barWidth * j )
                                    width: barWidth

                                currentPart.bars.append new_bar

                            nextCoord += barWidth
                            barTime += size

                        currentPart.width = nextCoord - currentPart.left

                    currentPart.element.css
                        left: currentPart.left
                        width: currentPart.width

                    partCnt++
                    currentPart = interval.parts[partCnt]

                    nextTime += ( intLen * 1000 * 60)

                    if humanTime(nextTime) != '00:00' and currentPart?
                        currentPart.left = nextCoord

                        switch scope.group.glued*1
                            when 1
                                currentPart.width = 120
                            when 2
                                currentPart.width = 0
                            else
                                currentPart.width = 100

                        currentPart.element.css
                            width: currentPart.width
                            left: currentPart.left

                        nextCoord += currentPart.width

                    partCnt++

                # Cache of pixels and time
                realTime = {}
                realCoord = {}
                freeMinutes = {}
                bigMinutes = {}

                for communityId in group_cIds
                    freeMinutes[communityId] = {}
                    bigMinutes[communityId] = {}

                # Helpers
                fillRealTime = (from, to, left, width) ->
                    timeDelta = to - from
                    pixDelta = width

                    pixTime = Math.floor(timeDelta/pixDelta)

                    i = 0
                    for pix in [left..left+width]
                        pX = Math.floor(pix)
                        minutes = justMinutes(from + pixTime*i)

                        realTime[ pX ] = minutes
                        if !realCoord[ minutes ]? then realCoord[ minutes ] = pX

                        i++

                fillHalfDivideFull = (from, to, left, width, cIds) ->
                    tS = justMinutes from
                    tE = justMinutes to
                    middle = Math.floor width/2

                    for i in [left...left + middle]
                        realTime[i] = tS

                    for i in [left + middle...left + width]
                        realTime[i] = tE

                    #realCoord[tS] = left
                    for i in [tS...tE]
                        realCoord[i] = left
                    realCoord[tE] = left + width

                    for communityId in group_cIds
                        if !cIds? or communityId in cIds
                            bigMinutes[communityId][tS] = true
                            bigMinutes[communityId][tE] = true

                fillHalfDivide = (time, left, width, cIds) ->
                    fillHalfDivideFull time - MIN, time, left, width, cIds

                for part in interval.parts

                    switch part.type
                        when 'dayBreak'
                            # Add realTime cache.
                            # Divide in half, place 59 and 00
                            if blkCacheExt.offset.start > 0
                                #fillHalfDivideFull part.time, post.timeEnd, postLeft, post.width
                                nTime = part.time + (blkCacheExt.offset[communityId].start * MIN)
                                fillHalfDivideFull nTime, nTime, part.left, part.width
                            else
                                fillHalfDivide part.time, part.left, part.width

                        when 'hourMark'
                            # Add realTime cache.
                            # Divide in half, place 59 and 00
                            if part.realTime?
                                nTime = part.time + (part.realTime * MIN)
                                fillHalfDivideFull nTime, nTime, part.left, part.width

                                markTime = part.time / MIN | 0

                                for i in [markTime..markTime + part.realTime]
                                    for communityId in group_cIds
                                        freeMinutes[communityId][i] = true
                            else
                                fillHalfDivide part.time, part.left, part.width

                        when 'freePlace'
                            # Fill with time marks for posting
                            fillRealTime part.time + MIN, part.timeEnd, part.left, part.width

                            # Fill free minutes cache
                            for i in [justMinutes(part.time)..justMinutes(part.timeEnd)]
                                for communityId in group_cIds
                                    freeMinutes[communityId][i] = true

                        when 'regular'
                            if part.startOffset
                                leftBorder = (part.time / MIN) + part.offset
                                rightBorder = leftBorder + part.startOffset
                                for i in [leftBorder..rightBorder]
                                    for communityId in group_cIds
                                        freeMinutes[communityId][i] = true
                            # Every subpart
                            for mark, i in part.marks
                                # Fill with time marks for posting
                                if mark.locked
                                    fillHalfDivideFull mark.time, mark.timeEnd, mark.left + part.left, mark.width
                                else
                                    fillRealTime mark.time, mark.timeEnd, part.left+mark.left, mark.width

                                    for i in [justMinutes(mark.time)...justMinutes(mark.timeEnd)+1]
                                        for communityId in group_cIds
                                            freeMinutes[communityId][i] = true

                    if part.posts?.length > 0
                        # Everywhere allowed
                        for post in part.posts
                            for communityId in group_cIds
                                for i in [justMinutes(post.time)...justMinutes(post.timeEnd)+1]
                                    freeMinutes[communityId][i] = true

                        for post in part.posts
                            # Pre
                            postLeft = part.left + post.left
                            for i in [justMinutes(post.time)+1...justMinutes(post.timeEnd)]
                                delete freeMinutes[post.communityId][i]

                            fillHalfDivideFull post.time, post.timeEnd, postLeft, post.width, [post.communityId]

                # Start offset
                mFrom = justMinutes(interval.from)
                # End offset
                mTo = justMinutes(interval.to)
                # Loop
                for communityId in group_cIds
                    for i in [0...blkCacheExt.offset[communityId].start]
                        if freeMinutes[communityId][mFrom+i]
                            delete freeMinutes[communityId][mFrom+i]

                    if blkCacheExt.offset[communityId].start == 0
                        freeMinutes[communityId][mFrom-1] = true

                    for i in [0..blkCacheExt.offset[communityId].end]
                        freeMinutes[communityId][mTo+i] = true

                interval.realTime = realTime
                interval.realCoord = realCoord
                interval.freeMinutes = freeMinutes
                interval.bigMinutes = bigMinutes

                interval.width = nextCoord
                true

            markCache = (px, free, obj, leftMargin, markEnds) ->
                timeDelta = obj.timeEnd - obj.time
                pixDelta = obj.width
                left = leftMargin + obj.left
                pixTime = Math.floor(timeDelta/pixDelta)

                i = 0
                for pix in [left..left+obj.width]
                    px[Math.floor(pix)] = toMinutes obj.timeEnd - pixTime * (obj.width-i)
                    free[Math.floor(pix)] = false

                    if markEnds then if (i == 0) or (i+1 == obj.width)
                        free[Math.floor(pix)] = true
                        if i == 0
                            px[Math.floor(pix)] = obj.time
                        else
                            px[Math.floor(pix)] = obj.timeEnd
                    i++

            removeInterval = (int) ->
                $(int.eternity).remove()
                for tl in int.timelines
                    $(tl.element).remove()
                    tl.scope.$destroy()

            scope.jumpScroll = (go_now) ->
                keyInterval = null
                scope.group.scroll = null

                for int in scope.intervals
                    removeInterval int

                scope.intervals.length = 0

                scroll 0
                recalculateIntervals()

                if go_now
                    now = justMinutes(smartDate.getShiftTimeBar(new Date().getTime()))
                    scroll_val = keyInterval.realCoord[now]
                    if !scroll_val?
                        scroll_val = 0
                    scroll scroll_val

                #scope.$apply()

            scope.jumpTime = (ts) ->
                now = new Date ts
                daystart = justMinutes(new Date(now.getFullYear(), now.getMonth(), now.getDate())) * MIN

                hourVal = ts - daystart
                fullIntervals = hourVal / 3 * HOUR | 0
                daystart += 3 * HOUR * fullIntervals

                setGroupStart daystart

                scope.jumpScroll()

                minutes = justMinutes ts
                scroll_val = keyInterval.realCoord[minutes]
                if !scroll_val?
                    scroll_val = 0
                scroll scroll_val

            scope.scrollTo = (ts, all) ->
                if all
                    $('.feedGroup').each () ->
                        elem = @
                        r_scope = angular.element(elem).scope()
                        if r_scope != scope
                            r_scope.scrollTo()

                if ts
                    timeObj = new Date ts
                    hours = timeObj.getHours()
                    hours = Math.round(hours / 3)
                    hours *= 3

                    ts = new Date(timeObj.getFullYear(), timeObj.getMonth(), timeObj.getDate(), hours).getTime()

                    setGroupStart ts
                    scope.jumpScroll()
                else
                    # now
                    now = new Date()
                    now_ts = now.getTime()
                    day_ts = justMinutes(new Date(now.getFullYear(), now.getMonth(), now.getDate())) * MIN

                    hourVal = now_ts - day_ts
                    fullIntervals = hourVal / (3 * HOUR) | 0
                    day_ts += 3 * HOUR * fullIntervals

                    setGroupStart day_ts

                    scope.jumpScroll true

            scope.zoomIn = () ->
                if currentZoom > 0
                    currentZoom--
                    zoomObj = zoom[currentZoom]

                    recalculateIntervals()
                    scroll(0)

            scope.zoomOut = () ->
                if currentZoom < zoom.length-1
                    currentZoom++
                    zoomObj = zoom[currentZoom]

                    recalculateIntervals()
                    scroll(0)

            scrolling =
                I: null
                T: null
                inProgress: false
                animation: false

            scope.stepLeft = (e, to) ->
                if e.which == 1 and !multiselect.state.selectingInProgress
                    to = to || 0
                    scrolling.T = setTimeout ->
                        scope.step(-1, isCmd e)
                    , to

            scope.stepRight = (e, to) ->
                if e.which == 1 and !multiselect.state.selectingInProgress
                    to = to || 0
                    scrolling.T = setTimeout ->
                        scope.step(1, isCmd e)
                    , to

            scope.step = (sign, long) ->
                settings =
                    long: 500
                    short: 20

                if long and keyInterval?

                    scope.jumpTime keyInterval.from + sign*DAY
                    return

                    # settings =
                    #     long: keyInterval.width
                    #     short: 50

                if !scrolling.animation
                    scrolling.inProgress = scrolling.animation = true
                    $(element).find(".liveInterval").addClass("transition03s")
                    scroll sign * settings.long
                    setTimeout () ->
                        if scrolling.inProgress
                            scrolling.I = setInterval () ->
                                scroll sign * settings.short
                            , 20
                        $(element).find(".liveInterval").removeClass("transition03s")
                        scrolling.animation = false
                    , 350


            scope.stopStep = () ->
                clearTimeout scrolling.T
                clearInterval scrolling.I
                scrolling.inProgress = false
                #$(element).find(".liveInterval").removeClass("transition03s")

            scope.doScroll = (val) ->
                scroll val
                #scope.$apply()

            $(element).on 'mousewheel', (e, delta) ->
                if e.altKey
                    scroll -delta
                    e.preventDefault()
                    e.stopPropagation()
                    #scope.$apply()

            #scroll 0

            true