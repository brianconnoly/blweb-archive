buzzlike
    .directive 'proposedItem', (contentService, postService, userService, desktopService, scheduleService, ugcService, notificationCenter, ruleService, confirmBox) ->
        restrict: 'C'
        link: (scope, element, attrs) ->

            scope.goOwnerPage = ->
                # find vk
                usr = scope.user or scope.item

                for acc in usr.accounts
                    if acc.socialNetwork == 'vk'
                        openCommunityPage
                            communityType: 'profile'
                            socialNetwork: acc.socialNetwork
                            socialNetworkId: acc.publicId
                        return

                acc = usr.accounts[0]
                openCommunityPage
                    communityType: 'profile'
                    socialNetwork: acc.socialNetwork
                    socialNetworkId: acc.publicId

            # scope.$watch 'proposedParams.usersFilter', () ->
            #     if scope.proposedParams.usersFilter.length > 0
            #         ugcService.call 'getUserStats',
            #             userId: scope.item.id
            #             ugcId: scope.currentCollector.id
            #         , (stats) ->
            #             scope.place = stats.place
            
            # scope.place = scope.$index + 1

            if scope.item.type == 'user'
                return true


            #
            # Actions switcher and scheduler
            #
            scope.actionsMode = 'default'
            scope.schedParams = {}
            scope.schedParams.scheduleTimestamp = toMinutes Date.now()

            if scope.item.proposeStatus == 'published'
                scope.actionsMode = 'used'

            scope.switchMode = (mode) ->
                scope.actionsMode = mode

                if mode == 'planner'
                    scope.schedParams.scheduleTimestamp = scope.lastPlanned
                    if scope.schedParams.scheduleTimestamp < Date.now() + (2 * MIN)
                        scope.schedParams.scheduleTimestamp = toMinutes Date.now() + (2 * MIN)

                if mode == 'mediaplanner'
                    # Prepare mediaplan
                    reqTime = toMinutes Date.now()
                    ruleService.call 'getNextPlaceholders',
                        communityId: scope.currentCollector.communityId
                        timestamp: reqTime
                    , (res) ->
                        scope.schedParams.data = res

                        diff = null
                        for time in res.timestamps
                            if diff == null or Math.abs(reqTime - time) < diff
                                scope.schedParams.scheduleTimestamp = time
                                diff = Math.abs(reqTime - time)

                            # console.log new Date(time), 'right:', res.jumpRight[time], 'left:', res.jumpLeft[time], 'rule:', res.rule[time]

                        recountArrows()

            recountArrows = ->
                index = scope.schedParams.data.timestamps.indexOf scope.schedParams.scheduleTimestamp
                if index > 0
                    scope.schedParams.canGoLeft = true
                else
                    scope.schedParams.canGoLeft = false

                if index < scope.schedParams.data.timestamps.length - 1
                    scope.schedParams.canGoRight = true
                else
                    scope.schedParams.canGoRight = false

            scope.nextTime = ->
                index = scope.schedParams.data.timestamps.indexOf scope.schedParams.scheduleTimestamp
                if scope.schedParams.data.timestamps.length >= index+1
                    scope.schedParams.scheduleTimestamp = scope.schedParams.data.timestamps[index+1]

                # console.log scope.schedParams.data.timestamps.length-1 - (index+1)
                if scope.schedParams.data.timestamps.length-1 - (index+1) < 3
                    loadMore()

                recountArrows()

            scope.prevTime = ->
                index = scope.schedParams.data.timestamps.indexOf scope.schedParams.scheduleTimestamp
                if index-1 >= 0
                    scope.schedParams.scheduleTimestamp = scope.schedParams.data.timestamps[index-1]

                if index < 3
                    loadMore()

                recountArrows()

            counter = 0
            loadMore = ->
                counter++

                fireCallBack = (cnt) ->
                    (res) ->
                        if cnt != counter
                            console.log 'cancelled', cnt
                            return
                        # console.log 'worked', cnt
                        scope.schedParams.data = res
                        recountArrows()

                ruleService.call 'getNextPlaceholders',
                    communityId: scope.currentCollector.communityId
                    timestamp: scope.schedParams.scheduleTimestamp
                , fireCallBack counter #(res) ->
                    # scope.schedParams.data = res
                    # recountArrows()

            scope.jumpTime = (time) ->
                scope.schedParams.scheduleTimestamp = time
                scope.schedParams.canGoRight = false
                scope.schedParams.canGoLeft = false

                ruleService.call 'getNextPlaceholders',
                    communityId: scope.currentCollector.communityId
                    timestamp: time
                , (res) ->
                    scope.schedParams.data = res

                    console.log 'Time arrived:'
                    for time in res.timestamps
                        console.log '   ', new Date(time), 'right:', res.jumpRight[time], 'left:', res.jumpLeft[time], 'rule:', res.rule[time]

                    recountArrows()


            doSchedule = ->
                scheduleService.create
                    scheduleType: 'post'
                    timestamp: scope.schedParams.scheduleTimestamp
                    postId: scope.item.id
                    communityId: scope.currentCollector.communityId
                , ->
                    scope.$parent.lastPlanned = scope.schedParams.scheduleTimestamp + (scope.currentCollector.settings.scheduleInterval * MIN)
                    console.log scope.currentCollector.settings.scheduleInterval * MIN, scope.schedParams.scheduleTimestamp

            scope.schedulePost = ->
                if scope.schedParams.scheduleTimestamp < Date.now()
                    notificationCenter.addMessage
                        realText: 'Нельзя планировать в прошлое'
                        error: true
                    return

                scheduleService.call 'timeAvailable',
                    timestamp:   scope.schedParams.scheduleTimestamp
                    communityId: scope.currentCollector.communityId
                , (avail) ->
                    if avail == true
                        if scope.item.proposeStatus == 'created'
                            scope.acceptPost scope.item, ->
                                doSchedule()
                        else
                            doSchedule()
                    else
                        notificationCenter.addMessage
                            realText: 'Время занято'
                            error: true

            # Prepare user
            scope.user = userService.getById scope.item.userId

            # Prepare post attaches
            scope.attaches = []
            for type,ids of scope.item.contentIds
                if type != 'text'
                    for id in ids
                        scope.attaches.push id

            # Prepare text
            scope.text = ""
            contentService.getByIds scope.item.contentIds.text, (items) ->
                scope.text = ""
                for item in items
                    scope.text += "\n" if scope.text != ""
                    scope.text += item.value

                scope.$watch ->
                    items
                , (nVal) ->
                    scope.text = ""
                    for item in items
                        scope.text += "\n" if scope.text != ""
                        scope.text += item.value
                , true

            scope.removeAttach = (id) ->
                # contentService.getById id, (item) ->
                confirmBox.init 'UGCApp_proposedPost_removeContent_confirm', () ->
                    postService.removeContentIds scope.item.id, [id], ->
                        removeElementFromArray id, scope.attaches

            #
            # Preview
            #
            scope.previewPic = (e, id) ->
                e.stopPropagation()
                e.preventDefault()
                desktopService.launchApp 'mediaPreview',
                    contentId: id
                    list: scope.attaches

            scope.previewText = (e, post) ->
                if post.contentIds.text?.length > 0
                    e.stopPropagation()
                    e.preventDefault()

                    desktopService.launchApp 'textEditor',
                        textId: post.contentIds.text[0]
                        proposedPost: post.id

            if scope.item.proposeStatus == 'published'
                scheduleService.getOriginalByPostId scope.item.id, (sched) ->
                    if sched?.timestamp?
                        scope.schedDate = sched.timestamp
                , true

            true

    .directive 'lazyProposed', () ->
        restrict: 'C'
        link: (scope, element, attrs) ->

            elem = $ element
            body = elem.parents('.leftPanel')
            elem.on 'mousewheel', (e) ->
                scope.proposedScrollValue = elem[0].scrollTop
                if scope.proposedParams.isLoading == true 
                    return

                if elem[0].scrollTop == 0 and scope.proposedParams.reloadOnStart == true
                    scope.proposedParams.reloadOnStart = false
                    scope.resetProposedList()
                    scope.fetchProposedPage()
                    scope.$apply()

                else if scope.proposedParams.pageSize * (scope.proposedParams.page) < scope.proposedParams.total
                    if elem[0].scrollTop + elem.height() > elem[0].scrollHeight - 200
                        scope.fetchProposedPage()
                        scope.$apply()