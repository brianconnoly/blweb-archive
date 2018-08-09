*deps: statsCutService

if !scope.scrollerParams.cursor?
    dateObj = new Date()
    scope.scrollerParams.cursor = new Date(dateObj.getFullYear(), dateObj.getMonth(), dateObj.getDate()).getTime()

dateObj = new Date scope.scrollerParams.cursor

monthStart = new Date(dateObj.getFullYear(), dateObj.getMonth(), 1)#.getTime()
monthEnd = new Date(dateObj.getFullYear(), dateObj.getMonth()+1, 0)#.getTime()

monthStartTs = monthStart.getTime()
monthEndTs = monthEnd.getTime()

scope.weeks = []

# Month switch
scope.currentMonthTime = monthStart
scope.nextMonth = ->
    scope.currentMonthTime = new Date(scope.currentMonthTime.getFullYear(), scope.currentMonthTime.getMonth()+1, 1)

    monthStart = scope.currentMonthTime
    monthEnd = new Date(scope.currentMonthTime.getFullYear(), scope.currentMonthTime.getMonth()+1, 0)

    monthStartTs = monthStart.getTime()
    monthEndTs = monthEnd.getTime()

    buildCalendar()
scope.prevMonth = ->
    scope.currentMonthTime = new Date(scope.currentMonthTime.getFullYear(), scope.currentMonthTime.getMonth()-1, 1)

    monthStart = scope.currentMonthTime
    monthEnd = new Date(scope.currentMonthTime.getFullYear(), scope.currentMonthTime.getMonth()+1, 0)

    monthStartTs = monthStart.getTime()
    monthEndTs = monthEnd.getTime()

    buildCalendar()

scope.$watch 'scrollerParams.cursor', (nVal) ->
    if !( monthStartTs < scope.scrollerParams.cursor < monthEndTs )
        dateObj = new Date nVal
        scope.currentMonthTime = new Date dateObj.getFullYear(), dateObj.getMonth(), 1

        monthStart = scope.currentMonthTime
        monthEnd = new Date(scope.currentMonthTime.getFullYear(), scope.currentMonthTime.getMonth()+1, 0)

        monthStartTs = monthStart.getTime()
        monthEndTs = monthEnd.getTime()
    buildCalendar()

# Click day
scope.clickDay = (day) ->
    scope.scrollerParams.cursor = day.timestamp
    dateObj = new Date scope.scrollerParams.cursor

    monthStart = new Date(dateObj.getFullYear(), dateObj.getMonth(), 1)#.getTime()
    monthEnd = new Date(dateObj.getFullYear(), dateObj.getMonth()+1, 0)#.getTime()

    monthStartTs = monthStart.getTime()
    monthEndTs = monthEnd.getTime()
    scope.currentMonthTime = monthStart

    # buildCalendar()
    scope.cursorChanged?()

scope.monthStats = []
scope.weekStats = []
scope.dayStats = []
buildCalendar = ->
    scope.weeks.length = 0

    weekDay = monthStart.getDay()
    weekDay--
    weekDay = 6 if weekDay < 0

    cursor = monthStartTs - DAY * weekDay # Week start

    # Add empty line if week starts from monday
    if weekDay == 0
        week =
            timestamp: cursor - WEEK
            days: []
            grey: true

        for i in [0...7]
            week.days.push
                timestamp: cursor - WEEK + i * DAY
                date: new Date(cursor - WEEK + i * DAY).getDate()
                grey: true

        scope.weeks.push week

    while cursor <= monthEndTs
        week =
            timestamp: cursor
            days: []

        week.current = true if cursor < scope.scrollerParams.cursor < cursor + WEEK

        for i in [0...7]
            week.days.push
                timestamp: cursor + i * DAY
                date: new Date(cursor + i * DAY).getDate()
                current: scope.scrollerParams.cursor == cursor + i * DAY
                grey: cursor + i * DAY > monthEndTs or monthStartTs > cursor + i * DAY

        scope.weeks.push week
        cursor += WEEK

    if scope.weeks.length < 6
        week =
            timestamp: cursor
            days: []
            grey: true

        for i in [0...7]
            week.days.push
                timestamp: cursor + i * DAY
                date: new Date(cursor + i * DAY).getDate()
                grey: true

        scope.weeks.push week

    # Stat cuts
    dateObj = new Date scope.scrollerParams.cursor
    weekDay = dateObj.getDay()
    weekDay--
    weekDay = 6 if weekDay < 0

    scope.monthStats.length = 0
    scope.weekStats.length = 0
    scope.dayStats.length = 0
    for communityId in scope.communityIds
        scope.monthStats.push statsCutService.get(
            communityId: communityId
            timestamp: monthEndTs
            statsCutType: 'month'
        )

        scope.weekStats.push statsCutService.get(
            communityId: communityId
            timestamp: new Date(dateObj.getFullYear(), dateObj.getMonth(), dateObj.getDate() - weekDay + 7).getTime()
            statsCutType: 'week'
        )

        scope.dayStats.push statsCutService.get(
            communityId: communityId
            timestamp: scope.scrollerParams.cursor + DAY
            statsCutType: 'day'
        )

# Watch stats blocks
# * Month
scope.monthPerc = 0
scope.monthVal = 0
scope.$watch 'monthStats', (nVal) ->
    scope.monthPerc = 0
    scope.monthVal = 0
    for stat in scope.monthStats
        if !stat.month
            continue
        stat = stat.month
        scope.monthPerc += (stat.stats.activity / stat.delta.activity) * 100
        scope.monthVal += stat.stats.activity
    scope.monthPerc /= scope.monthStats.length
    scope.monthPerc = scope.monthPerc | 0
, true

# * Week
scope.weekPerc = 0
scope.weekVal = 0
scope.$watch 'weekStats', (nVal) ->
    scope.weekPerc = 0
    scope.weekVal = 0
    for stat in scope.weekStats
        if !stat.week
            continue
        stat = stat.week
        scope.weekPerc += (stat.stats.activity / stat.delta.activity) * 100
        scope.weekVal += stat.stats.activity
    scope.weekPerc /= scope.weekStats.length
    scope.weekPerc = scope.weekPerc | 0
, true

# * Day
scope.dayPerc = 0
scope.dayVal = 0
scope.$watch 'dayStats', (nVal) ->
    scope.dayPerc = 0
    scope.dayVal = 0
    for stat in scope.dayStats
        if !stat.day
            continue
        stat = stat.day
        scope.dayPerc += (stat.stats.activity / stat.delta.activity) * 100
        scope.dayVal += stat.stats.activity
    scope.dayPerc /= scope.dayStats.length
    scope.dayPerc = scope.dayPerc | 0
, true


buildCalendar()
