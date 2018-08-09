VerifyCtrl = ($scope, env, $location, $http) ->
    $scope.verified = false
    $http({
        method: 'GET'
        url: env.verify + '?' + $location.$$url.split("?")[1]
        withCredentials: true
    })
    .success (res) =>
        if !res.err
            $scope.verified = true
            setTimeout $location.path '/timeline', 1333