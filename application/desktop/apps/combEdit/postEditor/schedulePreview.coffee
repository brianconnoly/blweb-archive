buzzlike.directive 'postSchedule', (communityService, scheduleService, confirmBox, smartDate, actionsService, complexMenu, postService) ->
    restrict: 'C'
    link: (scope, element, attrs) ->

        # Stats stuff
        scope.showGhaph = 
            likes: true
            comments: true
            reposts: true
            commLikes: true

        scope.triggerStat = (type) ->
            if scope.graphShown == true
                scope.showGhaph[type] = !scope.showGhaph[type]
            else
                scope.graphShown = true

        scope.hideGraph = ->
            scope.graphShown = false
            for k,v of scope.showGhaph
                scope.showGhaph[k] = true
        # ---------

        scope.community = communityService.getById scope.schedule.communityId

        removing = false

        scope.sendNow = ->
            scheduleService.sendNow scope.schedule.id

        scope.saveTime = ->
            process = scope.progress.add()
            scheduleService.save
                id: scope.schedule.id
                timestamp: scope.schedule.timestamp
            , ->
                scope.progress.finish process

        scope.removeSchedule = ->
            if removing
                return false
            removing = true

            confirmBox.init 52, () ->
                process = scope.progress.add()
                scheduleService.delete
                    id: scope.schedule.id
                    type: 'schedule'
                , ->
                    scope.progress.finish process

        scope.scheduleAction = (e) ->
            itemsActions = actionsService.getActions
                source: [scope.schedule]
                context: scope.comb

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

            groups.a =
                object: scope.post
                type: 'checkbox'
                selectFunction: ->
                    process = scope.progress.add()
                    postService.save scope.post, ->
                        scope.progress.finish process

                items: [
                        phrase: 'schedule_params_fromCommunity'
                        param: 'fromCommunity'
                        disabled: scope.community.communityType == 'profile'
                    ,
                        phrase: 'schedule_params_userSign'
                        param: 'useUserSign'
                        disabled: scope.post.fromCommunity == true or scope.community.communityType == 'profile'
                ]

            groups.b =
                type: 'select'
                object: scope.post
                param: 'deletionTime'
                items: [
                        phrase: 'schedule_params_dont_remove'
                        value: 0
                    ,   
                        phrase: 'schedule_params_remove_15'
                        value: 15 * MIN
                    ,
                        phrase: 'schedule_params_remove_hour'
                        value: 1 * HOUR
                    ,
                        phrase: 'schedule_params_remove_day'
                        value: 1 * DAY
                ]

            complexMenu.show groups,
                top: $(e.target).offset().top + 20
                left: $(e.target).offset().left
            true