buzzlike
    .controller 'pollEditCtrl', ($scope, contentService) ->

        $scope.session.expandedHeader = false
        $scope.poll = contentService.getById $scope.session.pollId

        $scope.pollEdit =
            name: ""
            anonymous: false
            value: ""
            answers: []
            lastUpdated: 0

        $scope.$watch 'poll', (nVal) ->
            if nVal.lastUpdated > $scope.pollEdit.lastUpdated
                $scope.pollEdit.lastUpdated = nVal.lastUpdated
                $scope.pollEdit.value = nVal.value
                $scope.pollEdit.answers = nVal.answers
                $scope.pollEdit.name = nVal.name
                $scope.pollEdit.anonymous = nVal.anonymous
        , true

        $scope.stateTree.applyState
            enter: 'default'
            'enter cmd': ->
                $scope.closeApp()
                
            delete: 'default'
            escape: $scope.closeApp

        $scope.savePoll = ->
            process = $scope.progress.add()
            contentService.save 
                id: $scope.poll.id
                type: 'poll'
                value: $scope.pollEdit.value
                answers: $scope.pollEdit.answers
                name: $scope.pollEdit.name
                anonymous: $scope.pollEdit.anonymous
            , ->
                $scope.progress.finish process

        # New variant
        $scope.newAnswer = ""
        $scope.addAnswer = ->
            $scope.poll.answers.push "" + $scope.newAnswer
            $scope.newAnswer = ""
            $scope.savePoll()

        $scope.newAnswerKey = (e) ->
            if e.which == 13
                e.stopPropagation()
                e.preventDefault()

                $scope.addAnswer()

        $scope.removeAnswer = (answer) ->
            removeElementFromArray answer, $scope.poll.answers
            $scope.savePoll()


        # Poll results stuff

        $scope.hasDifferentSchedules = ->
            if !$scope.poll.lastStats?.schedResults?
                return false
            Object.keys($scope.poll.lastStats.schedResults).length > 1

        $scope.currentSchedule = null
        $scope.pickSchedule = (id) ->
            $scope.currentSchedule = id
            getMaxVotes()


        maxVotes = 0
        getMaxVotes = ->
            if $scope.poll.stats.length < 1
                return

            maxVotes = 0

            if $scope.currentSchedule == null
                list = $scope.poll.lastStats.answers
            else
                list = $scope.poll.lastStats.schedResults[$scope.currentSchedule].answers

            for votes in list
                if votes > maxVotes
                    maxVotes = votes

        $scope.$watch 'poll.lastStats', (nVal) ->
            if nVal?
                getMaxVotes()

        $scope.colors = [
            '#D50000'
            '#AA5D00'
            '#726012'
            '#4B6A88'
            '#3E3E3E'
            '#DB0A5B'
            '#8A2BE2'
            '#336E7B'
            '#005051'
            '#008040'
            '#4B6319'
            '#005031'
        ]
        $scope.getRate = (index) ->
            if $scope.currentSchedule == null
                stat = $scope.poll.lastStats
            else
                stat = $scope.poll.lastStats.schedResults[$scope.currentSchedule]

            (stat.answers[index] / stat.total * 100 | 0) + '%'

        $scope.getWidth = (index) ->
            if $scope.currentSchedule == null
                stat = $scope.poll.lastStats
            else
                stat = $scope.poll.lastStats.schedResults[$scope.currentSchedule]

            (stat.answers[index] / maxVotes * 100 | 0) + '%'

        $scope.getVotes = (index) ->
            if $scope.currentSchedule == null
                stat = $scope.poll.lastStats
            else
                stat = $scope.poll.lastStats.schedResults[$scope.currentSchedule]

            stat.answers[index]

        $scope.hasVotes = (index) ->
            if $scope.currentSchedule == null
                stat = $scope.poll.lastStats
            else
                stat = $scope.poll.lastStats.schedResults[$scope.currentSchedule]

            stat.answers[index] > 0

        # Hide graphs
        $scope.hiddenAnswer = {}
        $scope.triggerAnswer = (index, e) ->
            if isCmd e
                for answer,i in $scope.poll.answers
                    $scope.hiddenAnswer[i] = true
                $scope.hiddenAnswer[index] = false
            else
                $scope.hiddenAnswer[index] = !$scope.hiddenAnswer[index]

        true

    .directive 'pollSchedulePreview', (communityService,scheduleService, $filter) ->
        restrict: 'C'
        link: (scope, element, attrs) ->
            scheduleService.getById scope.id, (sched) ->
                scope.community = communityService.getById sched.communityId

                scope.time = $filter('timestampMask')(sched.timestamp, 'hh:mm')
                scope.date = $filter('timestampMask')(sched.timestamp, 'DD MMM')
            true
