*deps: statsCutService, scheduleService, localization

elem = $ element
jcanvas = elem.find('canvas')
canvas = jcanvas[0]
ctx = canvas.getContext('2d')

cWid = 240
cHei = 90
barHei = 57

canvas.width = cWid
canvas.height = cHei

redColor = "#E0A1A4"
greenColor = "#B0CC85"

switch scope.block.dayBreakType
    when 'week'
        period = DAY
        totalBars = 7
        barWid = 34
        spacer = 5

        scope.weekEnd = scope.block.timestamp + WEEK - DAY
    when 'month'
        period = DAY
        timeObj = new Date scope.block.timestamp
        totalBars = new Date(timeObj.getFullYear(), timeObj.getMonth()+1, 0).getDate();
        barWid = 240 / totalBars
        spacer = 1
    else
        period = HOUR
        totalBars = 24
        barWid = 10
        spacer = 1

if window.devicePixelRatio > 1
    canvas.width = cWid * window.devicePixelRatio
    canvas.height = cHei * window.devicePixelRatio

    ctx.scale window.devicePixelRatio, window.devicePixelRatio

drawGraph = (hours, maxValue) ->
    # console.log new Date(scope.block.timestamp), hours
    ctx.clearRect 0, 0, canvas.width, canvas.height

    for i in [0..totalBars-1]
        hour = hours[i]

        # Draw grey block
        if maxValue == 0
            hei = barHei
        else
            hei = Math.ceil hour.history / maxValue * barHei
        ctx.fillStyle = "#EEF0F2"
        ctx.fillRect i*barWid, barHei-hei, (barWid-spacer), hei

        # Draw posts bricks
        max = hour?.postsTotal or 0
        if max > 5
            max = 5
        if 0 < max < 6
            for j in [0...max]
                post = hour.posts[j]
                switch post
                    when '0'
                        ctx.fillStyle = '#EEF0F2'
                    when '-'
                        ctx.fillStyle = redColor # "#C1272D"
                    else
                        ctx.fillStyle = greenColor # "#8CC63F"

                ctx.fillRect i*barWid, barHei + 2 + (j*3), (barWid-spacer), 2

        # Draw activityBlock
        if !hour? or hour.total == 0
            continue
        hei = Math.ceil hour.total / maxValue * barHei
        if hour.total < hour.history
            ctx.fillStyle = redColor # "#C1272D"
        else
            ctx.fillStyle = greenColor # "#8CC63F"
        ctx.fillRect i*barWid, barHei-hei, (barWid-spacer), hei

    # Draw legend
    # * Font settings
    ctx.strokeStyle = 'rgb(230,230,230)'
    ctx.font = '300 8px Roboto'
    ctx.fillStyle = '#999999'
    ctx.textAlign = 'center'
    ctx.textBaseline = 'middle'
    # * Drawing loop
    switch scope.block.dayBreakType
        when 'week'
            for i in [0..totalBars-1]
                wd = i+1
                wd = 0 if wd > 6
                ctx.fillText localization.translate(147+wd)[1], (i+0.5)*barWid - spacer/2, barHei + 24
        when 'month'
            for i in [5..totalBars] by 5
                ctx.fillText i, (i-0.5)*barWid - spacer/2, barHei + 24
            ctx.fillText 1, (0.5)*barWid - spacer/2, barHei + 24
        when 'day'
            for i in [0..totalBars-1] by 6
                ctx.fillText i, (i+0.5)*barWid - spacer/2, barHei + 24
            ctx.fillText 23, (23.5)*barWid - spacer/2, barHei + 24


updateStats = ->
    scope.total = 0
    scope.history = 0

    hourStats = {}
    maxValue = 0
    for i in [0..totalBars-1]
        hourStats[i] =
            history: 0
            total: 0
            posts: []
            postsTotal: 0
            postsGood: 0
            postsBad: 0

    for stat in scope.stats
        switch scope.block.dayBreakType
            when 'month'
                if !stat.month?.stats?
                    continue
                stat = stat.month
            when 'week'
                if !stat.week?.stats?
                    continue
                stat = stat.week
            when 'day'
                if !stat.day?.stats?
                    continue
                stat = stat.day

        scope.total += stat.stats.activity
        scope.history += stat.delta.activity

        # Fill hour history
        for hist in stat.forecast
            id = Math.floor hist.ts / period
            if id > totalBars - 1
                id = totalBars - 1
            hourStats[id].history += hist.delta.activity
            if hourStats[id].history > maxValue
                maxValue = hourStats[id].history

        # Fill hour total
        for hist in stat.history
            id = Math.floor (hist.ts - stat.timestamp + (totalBars * period)) / period
            if id > totalBars - 1
                id = totalBars - 1
            id = 0 if id < 0
            # if !hourStats[id]?
                # console.log id, hourStats, hist, stat.timestamp, (totalBars * period), period
            hourStats[id].total += hist.delta.activity
            if hourStats[id].total > maxValue
                maxValue = hourStats[id].total

    postStat = {}
    for commPosts in scope.posts
        for sched in commPosts

            if !postStat[sched.timestamp]?
                postStat[sched.timestamp] =
                    total: 0
                    history: 0

            postStat[sched.timestamp].total += sched.lastStats.activity or 0
            if sched.delta.activity*1 >= 0
                postStat[sched.timestamp].history += (sched.lastStats.activity * (1-sched.delta.activity)) or 0
            else
                postStat[sched.timestamp].history += (sched.lastStats.activity / (1+sched.delta.activity)) or 0

    for timestamp,stat of postStat

        id = Math.floor (timestamp - scope.block.timestamp) / period

        hourStats[id].postsTotal++
        if timestamp > Date.now()
            hourStats[id].posts.push '0'
        else
            if stat.history <= stat.total
                hourStats[id].postsGood++
                hourStats[id].posts.push '+'
            else
                hourStats[id].postsBad++
                hourStats[id].posts.push '-'

    drawGraph hourStats, maxValue

    if scope.total == scope.history
        scope.delta = 0
        return

    if scope.total == 0
        scope.delta = -100
        return
    if scope.history == 0
        scope.delta = 100
        return
    if scope.total > scope.history
        scope.delta = Math.ceil(scope.total / scope.history * 100) - 100
    else
        scope.delta = - 100 + Math.ceil(scope.total / scope.history * 100)
    # console.log 'TODO: update stats', scope.stats
    true

scope.stats = []
scope.posts = []
for communityId in scope.communityIds
    switch scope.block.dayBreakType
        when 'month'
            ts = scope.block.timestamp + totalBars * DAY
        when 'week'
            ts = scope.block.timestamp + WEEK
        else
            ts = scope.block.timestamp + DAY

    statsCutService.get
        timestamp: ts
        communityId: communityId
    , (res) ->
        scope.stats.push res

    switch scope.block.dayBreakType
        when 'month'
            scope.posts.push scheduleService.getCommunityMonth scope.block.timestamp, communityId
        when 'week'
            scope.posts.push scheduleService.getCommunityWeek scope.block.timestamp, communityId
        when 'day'
            scope.posts.push scheduleService.getCommunityDay scope.block.timestamp, communityId

scope.$watch 'stats', ->
    updateStats()
, true

scope.$watch 'posts', ->
    updateStats()
, true

# Open Range
elem.on 'mousedown', (e) ->
    e.stopPropagation()
    if scope.flowFrame.active != true or scope.flowBox.active != true
        scope.flow.activate scope.flowFrame, scope.flowBox
        scope.$apply()


elem.on 'dblclick', (e) ->
    scope.flowFrame.flowBox.addFlowFrame
        title: 'task'
        directive: 'novaTimelineRangeFrame'
        data:
            type: scope.block.dayBreakType
            timestamp: scope.block.timestamp
            communityIds: scope.communityIds
    , scope.flowFrame
