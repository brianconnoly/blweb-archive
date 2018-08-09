buzzlike
    .controller 'sendLogViewerCtrl', ($scope, scheduleService) ->

        $scope.session.expandedHeader = false

        $scope.stateTree.applyState
            'escape': $scope.closeApp

        $scope.schedule = scheduleService.getById $scope.session.scheduleId
        scheduleService.fetchById $scope.session.scheduleId

        $scope.logOrder = (item) -> item.code + (if item.type == 'answer' then 1 else 0)

        true