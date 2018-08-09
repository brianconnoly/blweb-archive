buzzlike.controller 'calendarCtrl', ($scope) ->

    $scope.stateTree.applyState
        'escape': $scope.closeApp

    $scope.session.expandedHeader = false
    
    now = new Date()
    $scope.current =
        year: now.getFullYear()
        month: now.getMonth()
        day: now.getDate()

    initial = {}

    $scope.$watch 'session.cursor', (nVal) ->
        if nVal?
            $scope.current.year = $scope.session.cursor.getFullYear()
            $scope.current.month = $scope.session.cursor.getMonth()
            $scope.current.day = $scope.session.cursor.getDate()

            updateObject initial, $scope.current

            fillCalendar()
    , true

    currentCallback = null

    $scope.days = days = []

    getDay = (date) ->
        day = date.getDay()
        if day == 0 then day = 7
        day - 1

    fillCalendar = () ->
        year = $scope.current.year
        month = $scope.current.month
        d = new Date year, month

        days.length = 0
        curWeek = 0
        days.push []

        # Last month
        prevDays = new Date(year, month, 0).getDate()
        before = getDay(d)

        # Empty days on start
        if before > 0
            for i in [prevDays - before + 1..prevDays]

                days[0].push
                    type: 'empty'
                    other: true
                    date: i
                    date_obj: new Date(year, month-1, i)
                    active: true

        # Date days
        while d.getMonth() == month
            date = d.getDate()
            date_obj = new Date $scope.current.year, $scope.current.month, date

            active = true
            if $scope.session.calendarEdge > 0
                calendarEdgeWithoutTime = new Date(Math.floor($scope.session.calendarEdge))
                calendarEdgeWithoutTime.setHours(0,0,0,0)

                if date_obj.getTime() < calendarEdgeWithoutTime.getTime()
                    active = false

            day =
                date: date
                date_obj: date_obj
                active: active

            if $scope.current.year == initial.year and $scope.current.month == initial.month and date == initial.day
                day.selected = true

            if getDay(d) == 0 and days[curWeek].length > 0
                curWeek++
                days.push []

            days[curWeek].push day
            d.setDate d.getDate() + 1

        # Empty days if needed
        if getDay(d) != 0
            afterDays = 7 - getDay(d)
            for i in [0...afterDays]
                days[curWeek].push
                    type: 'empty'
                    other: true
                    date: i+1
                    date_obj: new Date(year, month+1, i+1)
                    active: true

        curWeek++

        $scope.setHeight ( 30 + 56 + 40 ) + ( curWeek * 33 ) + 20, true

        true

    fillCalendar()

    $scope.goRight = () ->
        $scope.current.month++
        if $scope.current.month > 11
            $scope.current.month = 0
            $scope.current.year++
        fillCalendar()
        true

    $scope.goLeft = () ->
        $scope.current.month--
        if $scope.current.month < 0
            $scope.current.month = 11
            $scope.current.year--
        fillCalendar()
        true

    $scope.pickDate = (day, e) ->
        if !day.active then return false
        # calendar.pick day.date_obj, !isCmd(e)
        initial.year = day.date_obj.getFullYear()
        initial.month = day.date_obj.getMonth()
        initial.day = day.date_obj.getDate()

        $scope.session.api.pick day.date_obj

        updateObject $scope.current, initial
        fillCalendar()
        if !e.altKey and $scope.session.stay != true
            $scope.closeApp()
            
        false

    $scope.hide = () ->
        $scope.closeApp()

    true