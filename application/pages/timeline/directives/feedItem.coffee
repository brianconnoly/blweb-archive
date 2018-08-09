buzzlike
    .directive "feedItem", ($compile, communityService, $rootScope, postService, combService, inspectorService, multiselect, account, scheduleService, desktopService) ->
        restrict: 'C'
        link: (scope, element, attrs) ->
            elem = $ element

            postId = null
            lastFocusedCnt = 0

            groupId = scope.$parent.$parent.group.id
            lineId = scope.$parent.cId

            if scope.sched?
                postId = scope.sched.postId
                scope.item = scope.sched
                scope.postId = postId

            scope.user = account.user
            # TODO: Check if admin
            # $(element).attr 'dev-info', 'id: ' + scope.sched.id + ', status: ' + scope.sched.status + ', requestStatus: ' + scope.sched.requestStatus + ', errCode: ' + scope.sched.resultCode

            #console.log $(element).css('left'), scope.item.left[groupId]
            if elem
                elem
                    .css('left', scope.item.left?[groupId] + 'px')
                    .css('width', scope.item.width + 'px')
                    .css('z-index', scope.item.zindex)

            scope.recalc = ->
                $(element)
                    .css('left', scope.item.left?[groupId] + 'px')
                    .css('width', scope.item.width + 'px')
                    .css('z-index', scope.item.zindex)

                $(element).find('.tl_timeleft').html scope.sched.humanStartTime
                $(element).find('.tl_timeright').html scope.sched.humanEndTime

            # Repost
            #if scope.sched.scheduleType == 'repost' or scope.sched.scheduleType == 'requestRepost'
            #    element.append '<div class="repost-label">R</div>'

            # Mediaplan
            pHolder = null
            if scope.sched.pholders?[groupId]?
                pHolder = scope.sched.pholders[groupId]

            if scope.item.rule?
                pHolder = scope.item

            if pHolder?            
                elem.addClass('ruleItem').addClass('placeholder')
                elem.append '<div class="placeholder_highlighter"></div>'
                if scope.user.id == pHolder.rule.userId
                    mp_icon = $('<div class="ruleIcon ios-nodelay flushMousedown ruleIcon_' + pHolder.rule.ruleType + '"></div>') #(scope)
                    elem.append mp_icon

                    mp_icon.on 'click.mp', (e) ->
                        scope.showInspector e
                        scope.$apply()

                elem.addClass 'rule_' + pHolder.rule.id
                elem.addClass 'placeholder_' + pHolder.rule.id + '_' + pHolder.id

                if !scope.sched.postId?
                    elem.append '<div class="timeInfo pHolderTime">' + scope.sched.humanStartTime + '</div>'

                if pHolder.rule.ad && scope.sched.scheduleType != 'request'
                    elem.append '<div class="ruleAdIcon"></div>'

                if inspectorService.status.currentRule?.id == pHolder.rule.id
                    elem.addClass('placeholder_highlighted')

            if scope.sched.scheduleType == 'ugc'
                elem.addClass 'ratingApp'
                elem.append $ '<img>',
                    # html: 'Автоматический пост: рейтинг участников UGC'
                    class: 'ratingAppSchedule'
                    src: '/resources/images/ratingApp.svg'

            # Time circles
            # if !scope.sched.noLeft
            #     elem.append '<div class="timeLeft addPostArea" data-time="' + (scope.sched.timeStart - (5 * MIN)) + '"><div class="circle tl_timeleft">' + scope.sched.humanStartTime + '</div></div>'

            # if !scope.sched.noRight
            #     elem.append '<div class="timeRight addPostArea" data-time="' + scope.sched.timeEnd + '"><div class="circle tl_timeright">' + scope.sched.humanEndTime + '</div></div>'

            if scope.sched.scheduleType == 'repost'
                element.append '<div class="repost-label">repost</div>'

            refreshSched = () ->
                scope.post = postService.getById postId

            if scope.sched?

                postId = scope.sched.postId
                if postId? and postId != 'empty'
                    refreshSched()

                scope.sendNow = (e) ->
                    scheduleService.sendNow scope.sched.id

                # if scope.sched.status == 'error'
                #     element.append $compile('<div class="sendNowButton flushMousedown", ng-click="sendNow($event)" title="Отправить сейчас"></div>')(scope)

            if multiselect.isFocused scope.sched
                element.addClass 'selected'

            scope.showInspector = (e) ->
                inspectorService.initInspector pHolder, e
                # desktopService.launchApp 'ruleInspector',
                #     pHolder: pHolder
                #     schedule: scope.sched
                true

            # Graph stuff
            scope.showGraph = () ->
                desktopService.launchApp 'graph',
                    item: scope.sched

# Deprecated
buzzlike.filter 'feedFilter', (smartDate) ->
    (items, search) ->
        if !search
            return items

        if !search || '' == search
            return items

        result = []
        for k, element of items
            if (element.communityId == search.communityId) &&
                (smartDate.getShiftTime(element.timestamp) >= search.startTime) &&
                (smartDate.getShiftTime(element.timestamp) < search.endTime) && element.collapsed != true
                    result.push element
        result