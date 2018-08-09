buzzlike.controller 'requestMasterCtrl', ($scope, account, smartDate, lotService, communityService, requestService, localization) ->

    $scope.session.expandedHeader = false

    if $scope.session.requestId?
        $scope.request = requestService.getById $scope.session.requestId

    if $scope.request?.id?
        $scope.session.lotId       = $scope.request.lotId
        $scope.session.communityId = $scope.request.communityId
        $scope.session.timestamp   = $scope.request.timestamp
        $scope.session.request     = $scope.request

    $scope.stateTree.applyState
        escape: $scope.closeApp
        enter: ->
            $scope.createRequest()

    $scope.onEscape = $scope.closeApp

    $scope.request  = 
        lotId:          $scope.session.lotId
        communityId:    $scope.session.communityId
        timestamp:      $scope.session.timestamp

    # Template variables ===========
    $scope.conclusionVars = {}

    process1 = $scope.progress.add()
    $scope.lot = lotService.getById $scope.session.lotId, ->
        $scope.progress.finish process1

    process2 = $scope.progress.add()
    lotService.fetchById $scope.session.lotId, (lotItem) ->
        $scope.progress.finish process2
        # Lot is loaded
        $scope.loaded = true
        $scope.lot = lotItem

        # Fill template object
        $scope.conclusionVars.summ = $scope.lot.price + ' ' + localization.declensionPhrase($scope.lot.price, 'roubles')
        $scope.conclusionVars.check = $scope.getCheckAfter $scope.lot.checkAfter

        $scope.request.cost     = $scope.lot.price
        $scope.request.postId   = $scope.lot.postId

        process3 = $scope.progress.add()
        $scope.fromCommunity    = communityService.getById $scope.lot.communityId, (item) ->
            $scope.progress.finish process3
            $scope.conclusionVars.comm1 = item.name

        process4 = $scope.progress.add()
        $scope.toCommunity      = communityService.getById $scope.session.communityId, (item) ->
            $scope.progress.finish process4
            $scope.conclusionVars.comm2 = item.name

        $scope.dateFrom = if $scope.lot.dateFrom then smartDate.getShiftTimeBar($scope.lot.dateFrom) else 0
        $scope.dateTo   = if $scope.lot.dateTo   then smartDate.getShiftTimeBar($scope.lot.dateTo)   else 0

        emptyDate = new Date(2012,1,1).getTime()

        $scope.timeFrom = emptyDate + $scope.lot.timeFrom
        $scope.timeTo   = emptyDate + $scope.lot.timeTo

        if $scope.session.request?
            $scope.request = $scope.session.request

    $scope.myRequest = -> !$scope.request.fromUserId? or $scope.request.fromUserId == account.user.id
    $scope.editRequest = -> $scope.request.id?

    $scope.createRequest = () ->
        if !$scope.checkTime() or !$scope.checkAudience()
            return false

        if $scope.request.id?
            requestService.makeBet
                id: $scope.request.id
                timestamp: $scope.request.timestamp
                cost: $scope.request.cost
        else
            requestService.create $scope.request
        $scope.closeApp()

    $scope.checkTime = () ->

        if !$scope.request?.timestamp?
            return

        dateObj = new Date smartDate.getShiftTimeBar $scope.request.timestamp
        justDate = new Date(dateObj.getFullYear(), dateObj.getMonth(), dateObj.getDate()).getTime()
        justTime = dateObj.getHours() * HOUR + dateObj.getMinutes() * MIN

        if justDate < $scope.dateFrom or justDate > $scope.dateTo
            return false

        if justTime < $scope.lot.timeFrom or justTime > $scope.lot.timeTo
            return false

        true

    $scope.checkAudience = -> $scope.lot?.minSubscribers < $scope.toCommunity?.membersCount

