buzzlike.controller 'marketCtrl', ($scope, $rootScope, lotService, multiselect) ->

    $scope.session.expandedHeader = false #true
    $scope.session.zoom = 'max'

    $scope.stateTree.applyState
        'escape': ->
            $scope.stepBack()

    $scope.sectionBackground = ->
        $scope.currentStep.background or '#fff'

    $scope.sectionPicture = ->
        if $scope.currentStep.src?
            return 'url(' + $scope.currentStep.src + ') center center no-repeat'
        'none'

    # 
    # Mode switcher
    #
    $scope.setMode = (mode) ->
        if $scope.currentStep.mode != mode

            $scope.stepStack.length = 0

            $scope.currentStep =
                translateTitle: 'marketApp_title'
                type: 'main'
                group: true
                mode: mode
                itemType: 'lot'

            $scope.stepStack.push $scope.currentStep

    #
    # Steps
    #

    $scope.stepStack = []

    $scope.currentStep =
        translateTitle: 'marketApp_title'
        type: 'main'
        group: true
        mode: 'repost'
        itemType: 'lot'

    $scope.stepStack.push $scope.currentStep

    #
    # Step navigarion
    #

    $scope.goSection = (section) ->
        multiselect.flush()
        id = $scope.stepStack.indexOf($scope.currentStep)
        if id < $scope.stepStack.length - 1
            $scope.stepStack.splice id+1, $scope.stepStack.length - id

        $scope.currentStep = angular.copy section # $scope.currentStep

        # updateObjectFull $scope.currentStep, section
        $scope.currentStep.group = false

        $scope.stepStack.push $scope.currentStep

    #
    # Go back
    #

    $scope.canGoBack = -> $scope.stepStack.indexOf($scope.currentStep) > 0
    $scope.stepBack = ->
        if $scope.stepStack.length > 1
            $scope.stepStack.pop()
            $scope.currentStep = $scope.stepStack[$scope.stepStack.length - 1]

    #
    # Groups generator
    #

    $scope.getGroups = (cb) ->
        result = []

        switch $scope.currentStep.mode
            when 'repost'
                result.push
                    translateTitle: 'marketApp_category_new'
                    fetchOnUpdate: true
                    type: 'lot'
                    mode: 'repost'
                    query: 
                        sortBy: 'lastUpdated'
                        sortType: 'desc'
                        lotType: 'repost'
            when 'post'
                result.push
                    translateTitle: 'marketApp_category_new'
                    fetchOnUpdate: true
                    type: 'lot'
                    mode: 'post'
                    query: 
                        sortBy: 'lastUpdated'
                        sortType: 'desc'
                        lotType: 'post'

        cb result
        result

    $scope.queryFunction = (query, cb) ->
        lotService.query query, cb

    true