TableImportCtrl = ($scope, stateManager, tableImport) ->
    stateManager.applyState
        noMenu: true
        hideRight: true
        escape: tableImport.close

    $scope.$on '$destroy', stateManager.goBack

    $scope.state = tableImport.state

    $scope.uploadCommTable = () ->
        $('#importCommunityHelper').click()
        true

    $scope.uploadFullTable = () ->
        $('#importFullHelper').click()
        true

    $scope.download = (url) ->
        if url
            window.location = url

    $scope.onEscape = tableImport.close
