buzzlike.controller 'notificationViewerCtrl', ($scope, notificationService) ->
    
    $scope.stateTree.applyState
        escape: $scope.closeApp

    $scope.session.expandedHeader = false

    $scope.onEscape = $scope.closeApp

    $scope.currentPage = 0
    $scope.totalPages = 0

    $scope.notificationsList = []

    query = ->
        hei = $scope.session.size.height - 50 # $('body').height() - 100
        lines = Math.floor (hei - 60) / 81


        lines = 2 if lines < 1

        process = $scope.progress.add()
        notificationService.query 
            page: $scope.currentPage
            limit: lines
            sortBy: 'created'
            sortType: 'desc'
        , (items, total) ->
            $scope.totalPages = Math.ceil(total/lines)
            $scope.notificationsList = items
            $scope.progress.finish process

    query()

    $scope.onResize (wid, hei) ->
        query()

    $scope.$watch ->
        notificationService.storage
    , (nVal) ->
        query()
    , true

    $scope.goPage = (page) ->
        $scope.currentPage = page

        query()

    $scope.pageRight = ->
        $scope.currentPage++

        if $scope.currentPage > $scope.totalPages-1
            $scope.currentPage = $scope.totalPages-1

        query()

    $scope.pageLeft = ->
        $scope.currentPage--

        if $scope.currentPage < 0
            $scope.currentPage = 0

        query()