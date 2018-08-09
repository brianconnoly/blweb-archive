buzzlike.controller 'paymentOfferCtrl', ($scope, account) ->

    $scope.session.expandedHeader = false

    state =
        escape: $scope.closeApp

    $scope.stateTree.applyState state

    $scope.type = $scope.session.type # charge / prolong / market

    $scope.agreed = false
    $scope.agree = ->
        if !$scope.agreed then return false

        state.escape()
        account.Charge.makeOrder()

        true