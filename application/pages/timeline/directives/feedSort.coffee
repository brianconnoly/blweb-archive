buzzlike.directive 'feedSort', (stateManager, communityService, groupService, notificationCenter, account) ->
    restrict: 'C'
    link: (scope, element, attrs) ->
        elem = $ element
        groupElem = $(elem).parents('.feedGroup')
        baseGroupScope = null
        feed = $(elem).parents('.feedTimeline')
        feedId = null
        feedExOrder = null

        scrollBlock = $('.timeline-top')[0]

        placeholderGroup = $ '<div class="feedGroup layout_item"><ul class="timelines"><li class="feedTimeline placeholder"></li></ul></div>'
        placeholderFeed = $ '<li class="feedTimeline placeholder"></li>'
        placeholder = placeholderFeed

        helper = null

        feedHeight = 150

        threshold = 20

        positionCache = []

        groupsCache = []
        count = 0
        exValue = 0
        dragGroup = false
        startPoint =
            x: 0
            y: 0

        status = 'still'
        currentPosition = null

        elem.bind 'mousedown', (e) ->

            # if !tutorialService.lockAction 'button_addcomm'
            #     return false

            if account.user.settings.compactTimeline == true
                feedHeight = 100
            else
                feedHeight = 150

            e = fixEvent e
            groupElem = $(elem).parents('.feedGroup')
            feed = $(elem).parents('.feedTimeline')

            baseGroupScope = angular.element(groupElem[0]).scope()
            feedId = angular.element(feed[0]).scope().lineId

            startPoint.x = e.pageX
            startPoint.y = e.pageY

            dragGroup = isCmd e

            setEvents()
            false

        dragState =
            'escape': () ->
                dragFail()

        cacheGroups = () ->
            groups = $ '.feedGroup'
            groupsCache.length = 0
            positionCache.length = 0

            count = 0
            # New group from start

            groupId = 0
            groups.each () ->

                if $(@).hasClass 'currentDragging'
                    return

                groupScope = angular.element(@).scope()

                groupsCache.push groupScope.group.id

                positionCache.push
                    from: count
                    to: count + 12
                    result: 'create'
                    params:
                        type: 'before'
                        group: groupId #groupScope.group.orderNumber
                        groupScope: groupScope
                        elem: $ @

                groupElement = $ @

                count += 12

                timelines = $(@).find('li.feedTimeline')
                tlId = 0
                timelines.each ->

                    if $(@).hasClass('currentDragging')
                        return

                    if dragGroup
                        positionCache.push
                            from: count
                            to: count + feedHeight
                            result: 'create'
                            params:
                                type: if timelines.length / 2 > tlId then 'before' else 'after'
                                group: groupId #groupScope.group.orderNumber
                                groupScope: groupScope
                                elem: groupElement

                        count += feedHeight
                    else
                        positionCache.push
                            from: count
                            to: count + Math.ceil(feedHeight/2)
                            result: 'insert'
                            params:
                                type: 'before'
                                group: groupId #groupScope.group.orderNumber
                                elem: $ @
                                feedId: tlId
                                groupScope: groupScope

                        count += 75

                        positionCache.push
                            from: count
                            to: count + 75
                            result: 'insert'
                            params:
                                type: 'after'
                                group: groupId #groupScope.group.orderNumber
                                elem: $ @
                                feedId: tlId
                                groupScope: groupScope

                        count += 75
                    
                    tlId++

                positionCache.push
                    from: count
                    to: count + 12
                    result: 'create'
                    params:
                        type: 'after'
                        group: groupId #groupScope.group.orderNumber
                        groupScope: groupScope
                        elem: $ @

                count += 12
                groupId++

        setEvents = () ->
            document.onmousemove = mousemove
            document.onmouseup = mouseup
            document.ondragstart = document.body.onselectstart = () -> false

        removeEvents = () ->
            document.onmousemove = document.onmouseup = document.ondragstart = document.body.onselectstart = null

        mousemove = (e) ->
            e = fixEvent e

            if status == 'still' and ( Math.abs(e.pageX - startPoint.x) > threshold or Math.abs(e.pageY - startPoint.y) > threshold )
                status = 'moving'

                index = $(groupElem.children('ul.timelines')[0]).children('.feedTimeline').index feed[0]
                feedExOrder = index
                exValue = index * 174

                helper = feed.clone()
                # if dragGroup
                #     placeholder.css
                #         'height': feedHeight * baseGroupScope.group.feeds.length + 'px'
                # else
                #     placeholder.css
                #         'height': feedHeight + 'px'
                helper.css
                    'opacity': '0.4'
                helper.appendTo('body').addClass('collapsed')

                if dragGroup
                    groupElem.hide()
                    groupElem.addClass('currentDragging')
                else
                    feed.hide()
                    feed.addClass('currentDragging')

                    if baseGroupScope.group.feeds.length == 1
                        groupElem.hide()
                        groupElem.addClass('currentDragging')

                cacheGroups()
                if dragGroup
                    groupElem.before placeholder
                else
                    feed.before placeholder

                stateManager.applyState dragState

            if status == 'moving'
                helper.removeClass('top').removeClass('bottom')
                top = e.pageY - 32
                cursorTop = top + scrollBlock.scrollTop

                helper.css
                    'top': top + 'px'

                for pos,i in positionCache

                    if pos.from < cursorTop and pos.to > cursorTop or ( i == positionCache.length-1 and pos.from < cursorTop )

                        currentPosition = pos

                        switch pos.result
                            when 'insert'
                                placeholder.detach()
                                placeholder = placeholderFeed

                                if pos.params.type == 'before'
                                    pos.params.elem.before placeholder

                                if pos.params.type == 'after'
                                    pos.params.elem.after placeholder
                                break
                            when 'create'

                                placeholder.detach()
                                placeholder = placeholderGroup

                                if pos.params.type == 'before'
                                    pos.params.elem.before placeholder

                                if pos.params.type == 'after'
                                    pos.params.elem.after placeholder
                                break

            false

        mouseup = (e) ->
            if status == 'moving'
                if currentPosition.result == 'insert'
                    if currentPosition.params.groupScope.group.feeds.length == 0
                        if currentPosition.params.groupScope.group.feeds[0].communityId == feedId
                            dragFail()
                            return

                helper.remove()

                feed.show()
                feed.removeClass 'currentDragging'
                groupElem.show()
                groupElem.removeClass 'currentDragging'

                if dragGroup

                    # Reordering
                    newOrder = if currentPosition.params.type == 'before' then currentPosition.params.group else currentPosition.params.group + 1
                    groupsCache.splice newOrder, 0, baseGroupScope.group.id
                    groupService.setOrder groupsCache

                else

                    if currentPosition.result == 'create'

                        index = if currentPosition.params.type == 'before' then currentPosition.params.group else currentPosition.params.group + 1

                        groupService.insertFeed
                            communityId: feedId
                            newGroup: index
                            from: baseGroupScope.group.id

                    if currentPosition.result == 'insert'
                        index = if currentPosition.params.type == 'before' then currentPosition.params.feedId else currentPosition.params.feedId + 1

                        groupService.insertFeed
                            groupId: currentPosition.params.groupScope.group.id
                            communityId: feedId
                            index: index
                            from: baseGroupScope.group.id

                status = 'still'
                placeholder.detach()

                #saveOrder()

                stateManager.goBack()

            removeEvents()
            scope.$apply()
            false

        dragFail = () ->
            status = 'still'

            placeholder.detach()
            helper.remove()

            feed.show()
            groupElem.show()
            feed.removeClass 'currentDragging'
            groupElem.removeClass 'currentDragging'

            removeEvents()
            stateManager.goBack()

        saveOrder = () ->
            # make map
            list = []
            cnt = 0

            groups = $ '.feedGroup'
            groups.each () ->
                el_scope = angular.element(this).scope()
                list.push el_scope.group.id
                el_scope.group.orderNumber = cnt
                cnt++

            communityService.saveFeedOrder list, () ->
                notificationCenter.addMessage
                    text: 128


        true