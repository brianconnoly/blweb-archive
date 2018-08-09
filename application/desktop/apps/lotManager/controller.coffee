buzzlike
    .controller 'lotManagerCtrl', ($scope, $filter, smartDate, updateService, account, lotService, communityService, scheduleService, desktopService, requestService, confirmBox) ->
    
        $scope.session.expandedHeader = false
        $scope.requestLots = [] #lotService.storage
        
        $scope.user = account.user
        $scope.userMorpheus = ->
            if account.user?.roles?.Morpheus == true
                return true
            false

        $scope.openCommPage = (item) ->
            openCommunityPage item

        $scope.stateTree.applyState
            'escape': ->
                $scope.stepBack()

        #
        # Date format optimizer
        #

        tsCache = {}
        $scope.getFormatedDate = (ts) ->
            ts = smartDate.getShiftTimeline(ts)
            if !tsCache[ts]?
                tsCache[ts] = $filter('timestampMask')(ts, 'DD.M.YY hh:mm')
            tsCache[ts]

        #
        # Current lot
        #

        $scope.currentLot = null
        $scope.lotCommunity = null

        $scope.showSettings = false

        $scope.requests = []

        flushHandler = null
        flushLot = (lotId) ->
            if flushHandler != null

                clearTimeout flushHandler
                flushHandler = null

            flushHandler = setTimeout ->
                process = $scope.progress.add()
                lotService.flushNew lotId, ->
                    $scope.progress.finish process
            , 5000

        $scope.selectLot = (lot) ->

            $scope.progress.flush()

            if $scope.stepStack.length > 1
                $scope.stepStack.splice 1, $scope.stepStack.length - 1

            $scope.currentStep =
                translateTitle: if lot.name?.length > 0 then null else 'lotManagerApp_lotRequests'
                title: lot.name
                lotId: lot.id

            $scope.stepStack.push $scope.currentStep

            preloadLot(lot)

        preloadLot = (lot) ->
            $scope.currentLot = lot
            $scope.lotCommunity = null
            $scope.requests.length = 0

            $scope.resetRequestList()
            $scope.fetchRequestsPage()

            $scope.showSettings = !lot.published
            
            schedProcess = $scope.progress.add()
            scheduleService.getOriginalByPostId lot.postId, (schedItem) ->
                $scope.progress.finish schedProcess

                commProcess = $scope.progress.add()
                communityService.getById schedItem.communityId, (communityItem) ->
                    $scope.progress.finish commProcess
                    $scope.lotCommunity = communityItem

                    flushLot lot.id
            , true
            
            # applyStep $scope.currentStep


        $scope.previewLot = ->
            desktopService.launchApp 'lotPreview',
                lotId: $scope.currentLot.id

        $scope.saveLot = ->
            saveProcess = $scope.progress.add()
            lotService.save $scope.currentLot, ->
                $scope.progress.finish saveProcess

        $scope.triggerPublish = (invert = false) ->
            if ( $scope.currentLot.published == true and invert == false ) or ( $scope.currentLot.published == false and invert == true )

                confirmBox.init
                    phrase: 'confirmpublishlot'
                    description: 'confirmpublishlot_description'
                , ->
                    process = $scope.progress.add()
                    lotService.publish $scope.currentLot.id, ->
                        $scope.progress.finish process
                , ->
                    $scope.currentLot.published = false

            else

                confirmBox.init
                    phrase: 'unpublished_lot'
                    description: 'unpublished_lot_description'
                , ->
                    process = $scope.progress.add()
                    lotService.unpublish $scope.currentLot.id, ->
                        $scope.progress.finish process
                , ->
                    $scope.currentLot.published = true

        $scope.lotActive = -> $scope.currentLot?.dateTo > Date.now()

        $scope.deleteLot = ->
            actions = [
                {
                    text: 'textEditor_yes'
                    action: ->
                        lotService.delete $scope.currentLot, (result) ->
                            $scope.currentStep = $scope.stepStack[0]
                            $scope.stepStack.length = 1
                            applyStep $scope.currentStep
                },
                {
                    text: 'textEditor_no'
                    action: ->
                        false
                }
            ]
            
            desktopService.launchApp 'optionsList',
                message: 
                    phrase: 'requestmanager_removelot'
                    description: 'requestmanager_removelot_description'
                options: actions
                newSettings:
                    cancelButton: false

        #
        # Lot lazy loading
        #

        $scope.lotFilter = (item) -> item.deleted != true

        $scope.lotOrder = (item) ->
            map = item?.userUpdated?[0]
            if map?.userId == account.user.id
                if map.unread 
                    return '3' + map.timestamp 
                if map.updates > 0
                    return '2' + map.timestamp
                return '1' + map.timestamp

        $scope.lotParams =
            pageSize: 0
            page: 0
            total: 0
            isLoading: false
            reloadOnStart: false

        $scope.resetLotList = ->
            $scope.lotParams.pageSize = Math.ceil( ($scope.session.size.height - 100) / 120 ) * 2
            $scope.lotParams.page = 0
            $scope.lotParams.total = 0
            # $scope.requestLots.length = 0
            $scope.lotParams.isLoading = false
            $scope.lotParams.reloadOnStart = false

        $scope.resetLotList()

        $scope.fetchLotsPage = () ->
            if $scope.lotParams.isLoading == true
                return 

            requestsProcess = $scope.progress.add()
            $scope.lotParams.isLoading = true
            lotService.query
                updateUser: account.user.id
                limit: $scope.lotParams.pageSize
                page: $scope.lotParams.page
                sortBy: 'userUpdated.timestamp'
                sortType: 'desc'
                lotType: 'repost'
            , (items, total) ->
                if $scope.requestParams.page == 0
                    $scope.requests.length = 0

                $scope.progress.finish requestsProcess
                $scope.lotParams.page++
                $scope.lotParams.total = total

                for item in items
                    $scope.requestLots.push item if item not in $scope.requestLots

                $scope.lotParams.isLoading = false

        #
        # Requests lazy loading
        #

        $scope.requestOrder = (item) ->
            if item.toUserId == account.user.id and item.status in ['created']
                return '3' + (item.created or item.lastUpdated)
            if item.fromUserId == account.user.id and item.status in ['returned']
                return '3' + (item.created or item.lastUpdated)
            (item.created or item.lastUpdated)

        $scope.requestParams = 
            pageSize: 0
            page: 50
            total: 0
            isLoading: false
            reloadOnStart: false

        $scope.resetRequestList = ->
            $scope.requestParams.pageSize = Math.ceil( ($scope.session.size.height - 100) / 40 ) * 2
            $scope.requestParams.page = 0
            # $scope.requests.length = 0
            $scope.requestParams.total = 0
            $scope.requestParams.isLoading = false
            $scope.requestParams.reloadOnStart = false

        $scope.fetchRequestsPage = () ->
            if $scope.requestParams.isLoading == true
                return 

            $scope.requestParams.isLoading = true
            requestsProcess = $scope.progress.add()
            requestService.query
                lotId: $scope.currentLot?.id
                limit: $scope.requestParams.pageSize
                page: $scope.requestParams.page
                user: account.user.id
                sortBy: 'created'
                sortType: 'desc'
            , (items, total) ->
                if $scope.requestParams.page == 0
                    $scope.requests.length = 0

                $scope.requestParams.page++
                $scope.requestParams.total = total

                $scope.progress.finish requestsProcess

                for item in items
                    $scope.requests.push item if item not in $scope.requests

                $scope.requestParams.isLoading = false

        # fetchPage()

        updateId = updateService.registerUpdateHandler (data) ->
            if data['lot']? 
                if $scope.lotParams.page < 2 or $scope.tasksScrollValue < 300
                    $scope.resetLotList()
                    $scope.fetchLotsPage()
                else
                    $scope.lotParams.reloadOnStart = true

            if data['request']?
                if $scope.requestParams.page < 2 or $scope.tasksScrollValue < 300
                    $scope.resetRequestList()
                    $scope.fetchRequestsPage()
                else
                    $scope.requestParams.reloadOnStart = true

        $scope.$on '$destroy', ->
            if flushHandler != null
                clearTimeout flushHandler
            updateService.unRegisterUpdateHandler updateId

        $scope.fetchLotsPage()

        #
        # Steps
        #

        $scope.canGoBack = -> $scope.stepStack.indexOf($scope.currentStep) > 0

        $scope.stepBack = ->
            if $scope.stepStack.length > 1
                $scope.stepStack.pop()
                $scope.currentStep = $scope.stepStack[$scope.stepStack.length - 1]
                applyStep $scope.currentStep

        $scope.stepStack = []

        $scope.currentStep =
            translateTitle: 'lotManagerApp_title'

        $scope.stepStack.push $scope.currentStep

        applyStep = (step) ->
            $scope.progress.flush()
            $scope.showSettings = false

            if step.lotId?
                process = $scope.progress.add()
                lotService.getById step.lotId, (item) ->
                    $scope.progress.finish process

                    preloadLot item
                    # $scope.fetchRequestsPage()
            else
                $scope.resetRequestList()
                $scope.currentLot = null
                $scope.fetchRequestsPage()

        $scope.onJumpStep = ->
            applyStep $scope.currentStep

        if $scope.session.lotId?
            $scope.currentStep =
                translateTitle: 'lotManagerApp_lotRequests'
                lotId: $scope.session.lotId

            $scope.stepStack.push $scope.currentStep

        # 
        # Save state
        #

        $scope.stateSaver.add 'stepStack', ->
            # Saver
            stack: $scope.stepStack
            current: $scope.stepStack.indexOf($scope.currentStep)
        , (data) ->
            $scope.stepStack.length = 0
            # Loader
            for step in data.stack
                $scope.stepStack.push step

            $scope.currentStep = $scope.stepStack[data.current*1]
            # applyStep $scope.currentStep if $scope.currentStep?

        $scope.$watch 'currentStep', (nVal) ->
            $scope.stateSaver.save()

        applyStep $scope.currentStep

        true

    .directive 'rememberScroll', () ->
        restrict: 'C'
        scope: 
            scrollValue: '='
        priority: 1
        link: (scope, element, attrs) ->
            scope.$watch 'scrollValue', (nVal) ->
                element[0].scrollTop = nVal
