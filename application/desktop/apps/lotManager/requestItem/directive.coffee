buzzlike.directive 'requestItem', (desktopService, communityService, account, requestService, confirmBox, complexMenu) ->
    restrict: 'C'
    link: (scope, element, attrs) ->

        commProc = scope.progress.add()
        scope.communityItem = communityService.getById scope.item.communityId, ->
            scope.progress.finish commProc

        scope.hasActions = -> scope.item.requestStatus in ['returned','created']

        initAction = ->
            scope.action = null

            if scope.item.fromUserId == account.user.id and scope.item.requestStatus == 'returned'
                scope.action = 'accept'

            else if scope.item.fromUserId == account.user.id and scope.item.requestStatus == 'created'
                scope.action = 'cancel'

            else if scope.item.toUserId == account.user.id and scope.item.requestStatus == 'created'
                scope.action = 'accept'

            else if scope.item.toUserId == account.user.id and scope.item.requestStatus == 'returned'
                scope.action = 'cancel'

        initAction()

        scope.cancel = ->
            confirmBox.init 
                phrase: 'lotManagerApp_confirm_cancel'
                description: 'lotManagerApp_confirm_cancel_description'
            , ->
                process = scope.progress.add()
                requestService.cancel scope.item.id, ->
                    scope.progress.finish process
                    initAction()

        scope.reject = ->
            confirmBox.init 
                phrase: 'lotManagerApp_confirm_reject'
                description: 'lotManagerApp_confirm_reject_description'
            , ->
                process = scope.progress.add()
                requestService.reject scope.item.id, ->
                    scope.progress.finish process
                    initAction()

        scope.accept = ->
            confirmBox.init 
                phrase: 'lotManagerApp_confirm_accept'
                description: 'lotManagerApp_confirm_accept_description'
            , ->
                process = scope.progress.add()
                requestService.accept scope.item.id, ->
                    scope.progress.finish process
                    initAction()

        scope.rejectFromUser = ->
            confirmBox.init 
                phrase: 'lotManagerApp_confirm_rejectFromUser'
                description: 'lotManagerApp_confirm_rejectFromUser_description'
            , ->
                process = scope.progress.add()
                requestService.rejectByUserId 
                    userId: scope.item.fromUserId
                    lotId: scope.item.lotId
                , (request) ->
                    scope.progress.finish process
                    initAction()   

        scope.return = ->
            desktopService.launchApp 'requestMaster',
                requestId: scope.item.id

        scope.showMenu = (e) ->
            actions = []

            if scope.item.toUserId == account.user.id

                switch scope.item.requestStatus 
                    when 'created'
                        actions.push 
                            phrase: 'request_accept'
                            action: scope.accept

                        actions.push 
                            phrase: 'request_reject'
                            action: scope.reject

                        actions.push
                            phrase: 'request_return'
                            action: scope.return

                        actions.push
                            phrase: 'request_rejectFromUser'
                            action: scope.rejectFromUser

                    when 'returned'
                        actions.push 
                            phrase: 'request_cancel'
                            action: scope.cancel

            else if scope.item.fromUserId == account.user.id

                switch scope.item.requestStatus 
                    when 'returned'
                        actions.push 
                            phrase: 'request_accept'
                            action: scope.accept

                        actions.push 
                            phrase: 'request_reject'
                            action: scope.reject

                        actions.push
                            phrase: 'request_return'
                            action: scope.return

                    when 'created'
                        actions.push 
                            phrase: 'request_cancel'
                            action: scope.cancel


            if actions.length < 1
                return

            complexMenu.show [
                    type: 'actions'
                    items: actions
            ],
                top: $(e.target).offset().top + 20
                left: $(e.target).offset().left - 180

