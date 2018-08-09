buzzlike
    .directive "feedInterval", (desktopService, actionsService, requestService, dropHelper, account, dragMaster, $rootScope, postService, combService, contentService, scheduleService, notificationCenter, smartDate, localization, ruleService, communityService) ->
        priority: 100
        restrict: 'C'
        replace: true
        template: templateCache["/pages/timeline/directives/feedInterval"]
        link: (scope, element, attrs) ->
            postLen = $rootScope.postLen

            interval = scope.interval
            elem = $(element)
            #timeShiftPlan = (1000 * 60 * 16) #Возможность постить через час + 16 минут
            timeShiftPlan = 1*MIN #Возможность постить через час + 16 минут

            lineId = scope.cId
            timebar = scope.timebar
            touchBar = scope.touchBar
            community = scope.$parent.item

            scope.groupId = groupId = scope.$parent.$parent.group.id
            groupItem = scope.$parent.$parent.group

            scope.makeDiff = (val) -> (Math.ceil val * 100) + '%'

            scope.getTimeItem = ->
                type: 'timeline'
                timestamp: scope.timeBarPos
                socialNetwork: scope.item.socialNetwork
                communityId: lineId
                groupId: groupId

            scope.intervalDblClick = (e) ->
                e = fixEvent e
                offset = $(element).offset()

                timeRes = findPostTime timeBarPos
                if !timeRes
                    return false
                time = timeRes.time

                tObj = new Date time
                tstamp = new Date tObj.getFullYear(), tObj.getMonth(), tObj.getDate(), tObj.getHours(), tObj.getMinutes()

                # Don't plan in the past
                now = new Date()
                ts = toMinutes(now.getTime()) + timeShiftPlan
                if tObj.getTime() < smartDate.getShiftTimeBar(ts)
                    return false

                # Start planning
                # timebar.addClass('hidden')

                group = false
                if scope.$parent.$parent.group.feeds.length > 1
                    group = scope.$parent.$parent.group

                desktopService.launchApp 'postPicker',
                    groupId: scope.$parent.$parent.group.id
                    group: group
                    communityId: lineId
                    timestamp: smartDate.getShiftTimeline( tstamp.getTime() )
                    socialNetwork: community.socialNetwork
                , e

                # tutorialService.nextLesson('createemptyposts', [1])

                true

            element.off 'mousemove'
            element.on 'mousemove', (e) ->
                e = fixEvent e
                timebarMove e.pageX, true, e #e.shiftKey

            scope.timeBarPos = timeBarPos = 0
            timeBarDirection = 'right'

            toMinutes = (ts) ->
                obj = new Date ts
                new Date(obj.getFullYear(), obj.getMonth(), obj.getDate(), obj.getHours(), obj.getMinutes()).getTime()

            findPostTime = (time) ->
                hTime = getHumanDate(time).time
                left = false

                if hTime == '23:59' and time < interval.from
                    left = true

                # check right
                possible = true
                from = justMinutes time
                to = from + postLen

                lastPossible = justMinutes time

                for i in [from...to]
                    if !interval.freeMinutes[lineId][i]
                        possible = false
                        break
                    else
                        lastPossible = i

                if possible
                    return {
                        time: time
                        left: left
                    }

                # check left
                possible = true
                from = lastPossible - postLen
                to = lastPossible

                for i in [from...to]
                    if !interval.freeMinutes[lineId][i]
                        possible = false

                if possible
                    return {
                        time: (lastPossible - postLen) * (60*1000)
                        left: left
                    }

                return false

            scope.touchbarMove = (left) ->
                left = left | 0
                coord = left - interval.left

                realTime = interval.realTime[ coord ]

                # Step
                nT = Math.round(realTime / 5)
                nT = nT * 5

                if interval.freeMinutes[lineId][nT]
                    realTime = nT

                realCoord = interval.realCoord[ realTime ]

                time = realTime * 60 * 1000
                left = interval.left + realCoord

                timeBarPos = time
                scope.timeBarPos = time
                date_obj = getHumanDate time
                touchBar.data 'time', time

                touchBar.children('.time').html if date_obj.time? then date_obj.time else ""
                touchBar.css
                    left: left

                now = new Date()
                ts = now.getTime() + timeShiftPlan

                $('.touchBar').hide()
                if date_obj.date.getTime() < smartDate.getShiftTimeBar(ts)
                    true
                else
                    touchBar.show()

            timebarMove = (left, magnet, e) ->
                left -= scope.session.coords.x

                tgt = $(e.target)
                if tgt.parent().hasClass('addPostArea') or tgt.hasClass('addPostArea') or tgt.hasClass 'feedInterval'
                    timebar.removeClass 'hidden'
                    scope.$parent.cursor.removeClass 'hidden'
                else
                    timebar.addClass 'hidden'
                    scope.$parent.cursor.addClass 'hidden'
                    return

                left = left | 0
                coord = left - interval.left

                realTime = interval.realTime[ coord ]
                time = realTime * 60 * 1000

                # Step
                if magnet and e.shiftKey
                    nT = Math.round(realTime / 5)
                    nT = nT * 5

                    if interval.freeMinutes[lineId][nT]
                        realTime = nT

                now = new Date()
                ts = now.getTime() + timeShiftPlan
                realTs = toMinutes smartDate.getShiftTimeBar(ts)
                if time < realTs and time > realTs - 15 * MIN
                    realTime = justMinutes realTs
                    time = toMinutes realTs

                realCoord = interval.realCoord[ realTime ]

                if interval.bigMinutes[lineId][realTime]?
                    timebar.addClass 'big'
                else
                    timebar.removeClass 'big'

                
                left = interval.left + realCoord

                timeBarPos = time
                scope.timeBarPos = time
                date_obj = getHumanDate time
                timebar.data 'time', time

                timebar.children('.time').html if date_obj.time? then date_obj.time else ""
                timebar.css
                    left: left

                scope.$parent.cursor.css
                    left: left

                if date_obj.date.getTime() < realTs
                    timebar.children('.time').css
                        'color': '#C1272D'
                else
                    timebar.children('.time').css
                        'color': '#fff'

            currentActions = null
            new dragMaster.dropTarget element[0],
                enter: (elem, e) ->
                    timebar.addClass 'showed'
                    scope.$parent.cursor.addClass 'showed'
                    dropHelper.show currentActions, scope.timeBarPos
                    # scope.$apply()
                leave: (elem) ->
                    timebar.removeClass 'showed'
                    scope.$parent.cursor.removeClass 'showed'
                canAccept: (elem, e) ->
                    currentActions = actionsService.getActions 
                        sourceContext: elem.sourceContext
                        source: elem.dragObject.items
                        target: scope.getTimeItem()
                        context: groupItem
                        targetOnly: true
                        actionsType: 'dragndrop'
                    currentActions.length > 0
                move: (elem, e) ->
                    dragItem = elem.dragObject.dragMulti[0].elem
                    offset = elem.dragObject.offset
                    left = $(dragItem).position().left + offset.x

                    dropHelper.setTime scope.timeBarPos
                    # timebarMove left, true, e #e.shiftKey
                drop: (elem, e) ->
                    currentActions = actionsService.getActions
                        sourceContext: elem.sourceContext 
                        source: elem.dragObject.items
                        target: scope.getTimeItem()
                        context: groupItem
                        targetOnly: true
                        actionsType: 'dragndrop'

                    dropHelper.show currentActions, scope.timeBarPos

                    dropHelper.activate e, elem.sourceContext?.type == 'rightPanel'
                    scope.$apply()

