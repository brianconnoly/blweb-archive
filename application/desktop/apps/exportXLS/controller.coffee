buzzlike.controller 'exportXLSCtrl', ($scope, communityService, rpc) ->

    $scope.stateTree.applyState
        'escape': $scope.closeApp

    $scope.session.expandedHeader = false

    # Init
    $scope.params =
        forcedName: ""
        from: Date.now()
        to: Date.now() + DAY
        communityId: $scope.session.communityId

    $scope.community = communityService.getById $scope.session.communityId, (item) ->
        $scope.params.forcedName = item.name

    $scope.doExport = () ->
        process = $scope.progress.add()
        rpc.call 'export.exportXLS', $scope.params, (res) ->
            $scope.progress.finish process
            if typeof res == 'string'
                window.location = res

    $scope.onEscape = $scope.closeApp

    #
    # Presets
    #

    $scope.activePreset = null
    $scope.changedDate = ->
        $scope.activePreset = null

    $scope.presets = [
        'currentMonth'
        'nextMonth'
        'currentWeek'
        'nextWeek'
    ]

    $scope.setPreset = (preset) ->
        $scope.activePreset = preset

        switch preset
            when 'currentWeek'
                now = new Date()
                day = now.getDay()
                day--

                if day < 0
                    day = 6

                cursor = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime()

                $scope.params.from = cursor - ( day * DAY )
                $scope.params.to   = cursor + ( ( 7 - day ) * DAY ) - MIN

            when 'nextWeek'
                now = new Date()
                day = now.getDay()
                day--

                if day < 0
                    day = 6

                cursor = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime()

                $scope.params.from = cursor - ( day  * DAY ) + WEEK
                $scope.params.to   = cursor + ( ( 7 - day ) * DAY ) - MIN + WEEK

            when 'currentMonth'
                now = new Date()
                
                days = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate()
                day = now.getDate()

                cursor = new Date(now.getFullYear(), now.getMonth(), 1).getTime()

                $scope.params.from = cursor
                $scope.params.to   = cursor + ( days * DAY ) - MIN

            when 'nextMonth'
                now = new Date()
                
                days = new Date(now.getFullYear(), now.getMonth() + 2, 0).getDate()
                day = now.getDate()

                cursor = new Date(now.getFullYear(), now.getMonth() + 1, 1).getTime()

                $scope.params.from = cursor
                $scope.params.to   = cursor + ( days * DAY ) - MIN



