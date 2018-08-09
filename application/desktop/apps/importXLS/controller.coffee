buzzlike.controller 'importXLSCtrl', ($scope, tableImport) ->

    $scope.stateTree.applyState
        'escape': $scope.closeApp

    $scope.session.expandedHeader = false

    $scope.download = (url) ->
        if url
            window.location = url

    $scope.doImport = ->
        tableImport.initiateUpload $scope.session.communityId

    $scope.getExampleHref = ->
        if $scope.session.communityId?
            return 'https://drive.google.com/a/buzzlike.ru/uc?id=0B1elezTkrbKVTktkV0ctZUY5SWs&export=download'
        else
            return 'https://docs.google.com/spreadsheets/d/1hWpxHYmKhmPpv5rQJa1-jI9HiNBWnhvz_DQX7FXM_fw/export?format=xlsx' #'https://drive.google.com/a/buzzlike.ru/uc?id=0B1elezTkrbKVV3R3OFVRMzlNTE0&export=download'

    $scope.onEscape = $scope.closeApp
