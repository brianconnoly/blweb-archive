buzzlike
    .directive "feedTimeline", (scheduleService, actionsService, complexMenu, desktopService, $rootScope, notificationCenter, communityService, groupService, dragMaster, ruleService, confirmBox, localization) ->
        restrict: 'E'
        template: templateCache['/pages/timeline/directives/feedTimeline']
        replace: true
        link: (scope, element, attrs) ->
            elem = $ element

            scope.item = communityService.getById scope.lineId

            #replaceImage = ->
            #    scope.image = scope.item.image
            #    if scope.item.image == 'http://vk.com/resources/images/question_a.gif' then scope.image = '' #vk empty
            #    if scope.item.image?.indexOf('://') < 0 then scope.image = ''
            #
            #scope.$watch 'item.image', replaceImage

            #blog scope.item

            timeBar = elem.children 'div.timebar'
            touchBar = elem.children 'div.touchBar'

            scope.snColor = (sn) ->
                $rootScope.networksData?[sn].background if sn?

            scope.openCommunity = () ->
                openCommunityPage scope.item

                null

            scope.hideTimebar = (e) ->
                e.stopPropagation()
                timeBar.css 'display', 'none'

                null

            scope.showTimebar = (e) ->
                e.stopPropagation()
                timeBar.css 'display', ''

                null

            scope.pickPost = () ->
                desktopService.launchApp 'postPicker',
                    communityId: scope.item.id
                    timestamp: touchBar.data('time')
                    socialNetwork: scope.item.socialNetwork

            scope.stepUp = () ->
                time = touchBar.data('time')
                time += 5 * MIN

                date_obj = getHumanDate time
                touchBar.data 'time', time

                touchBar.children('.time').html date_obj.time
                true

            scope.stepDown = () ->
                time = touchBar.data('time')
                time -= 5 * MIN

                date_obj = getHumanDate time
                touchBar.data 'time', time

                touchBar.children('.time').html date_obj.time
                true

            scope.removeFeedFromGroup = (e) ->
                shortName = scope.item.name
                group_id = scope.$parent.group.id
                if scope.item.name?.length > 25
                    shortName = scope.item.name.substr(0,25)
                    shortName += '...'
                title = localization.translate('popup_community_delete_title') + '<br><span style="font-size: 24px; font-weight: lighter">' + shortName + '</span><br><span style="font-size: 12px; ">' + localization.translate('popup_community_delete_subtitle') + '</span>'
                deleteGroup = isCmd e
                confirmBox.init title, () ->
                    
                    group = groupService.getById group_id

                    if deleteGroup
                        groupService.delete group, () ->
                            notificationCenter.addMessage
                                text: 114
                    else
                        for feed,i in group.feeds
                            if feed.communityId == scope.lineId
                                group.feeds.splice i, 1
                                break

                        groupService.save group, () ->
                            notificationCenter.addMessage
                                text: 114

            scope.goNow = (e) ->
                scope.$parent.scrollTo null, isCmd e

            scope.showFeedMenu = (e) ->
                itemsActions = actionsService.getActions
                    source: [scope.item]
                    sourceContext: scope.$parent.group

                if itemsActions.length > 0
                    groups = {}
                    list = []

                    for action in itemsActions
                        if !groups[action.category]?
                            groups[action.category] = 
                                type: 'actions' 
                                items: []

                        groups[action.category].items.push 
                            phrase: action.phrase
                            action: action.action
                            priority: action.priority

                    for k,actions of groups
                        actions.items.sort (a,b) ->
                            if a.priority > b.priority
                                return -1
                            if a.priority < b.priority
                                return 1
                            0

                groups[0] =
                    type: 'actions'
                    items: [
                            phrase: 'timelineApp_openCommPage'
                            action: ->
                                openCommunityPage scope.item
                    ]
                    
                groups[1] =
                    type: 'select'
                    object: scope.$parent.group
                    param: 'glued'
                    items: [
                            phrase: 'timelineApp_scale_mode_1min'
                            value: 0
                        ,   
                            phrase: 'timelineApp_scale_mode_3hour'
                            value: 1
                        ,
                            phrase: 'timelineApp_scale_mode_1day'
                            value: 2
                    ]

                groups[2] =
                    type: 'actions'
                    items: [
                            phrase: 'timelineApp_showCalendar'
                            action: ->
                                elem.find('.datePicker').click()
                        ,
                            phrase: 'timelineApp_jumpLastPost'
                            action: ->
                                scheduleService.query
                                    communityId: scope.item.id
                                    sortBy: 'timestamp'
                                    sortType: 'desc'
                                    limit: 1
                                , (items) ->   
                                    if items[0]?
                                        scope.$parent.scrollTo items[0].timestamp + (HOUR / 2)
                        ,
                            phrase: 'timelineApp_remove_mediaplan'
                            action: ->
                                desktopService.launchApp 'optionsList',
                                    message:
                                        'inspector_removeAllQuestion'
                                    options: [
                                        {
                                            text: 'inspector_removeAll'
                                            action: ->
                                                ruleService.removeByGroupId scope.$parent.group.id
                                        }
                                    ]
                        ,
                            phrase: 'timelineApp_remove_feed'
                            action: ->
                                scope.removeFeedFromGroup
                                    ctrlKey: false
                        ,
                            phrase: 'timelineApp_remove_feed_group'
                            action: ->
                                scope.removeFeedFromGroup
                                    ctrlKey: true
                    ]         

                groups[3] =
                    object: scope.item
                    type: 'checkbox'
                    selectFunction: ->
                        process = scope.progress.add()
                        communityService.save scope.item, ->
                            scope.progress.finish process

                    items: [
                            phrase: 'schedule_params_fromCommunity'
                            param: 'fromCommunity'
                            disabled: scope.item.communityType == 'profile'
                        ,
                            phrase: 'schedule_params_userSign'
                            param: 'useUserSign'
                            disabled: scope.item.fromCommunity == true or scope.item.communityType == 'profile'
                    ]

                if scope.$parent.group.teamId?
                    groups[0].items.push 
                        phrase: 'timelineApp_remove_team'
                        action: ->
                            confirmBox.init
                                phrase: 'communityGroup_unbind_team'
                                description: 'communityGroup_unbind_team_description'
                            , ->
                                groupService.call 'unbindTeam', scope.$parent.group.id, ->
                                    true
                            , ->
                                true

                complexMenu.show groups,
                    top: $(e.target).offset().top + 20
                    left: $(e.target).offset().left
                true

            true
