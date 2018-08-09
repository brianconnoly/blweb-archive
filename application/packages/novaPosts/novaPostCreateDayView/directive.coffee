*deps: statsCutService, scheduleService, localization, ruleService

body = $ 'body'
elem = $ element
jcanvas = elem.find('canvas')
canvas = jcanvas[0]
ctx = canvas.getContext('2d')

cWid = 240
cHei = 90
barHei = 57

canvas.width = cWid
canvas.height = cHei

redColor = "#CDCDCD" # "#E0A1A4"
greenColor = "#CDCDCD" # "#B0CC85"

period = HOUR
totalBars = 24
barWid = 10
spacer = 1

hourStats = null

if window.devicePixelRatio > 1
    canvas.width = cWid * window.devicePixelRatio
    canvas.height = cHei * window.devicePixelRatio

    ctx.scale window.devicePixelRatio, window.devicePixelRatio

drawGraph = (hours, maxValue) ->
    # console.log new Date(scope.postParams.timestamp), hours
    ctx.clearRect 0, 0, canvas.width, canvas.height

    for i in [0..totalBars-1]
        hour = hours[i]

        # Draw grey block
        if maxValue == 0
            hei = barHei
        else
            hei = Math.ceil hour.history / maxValue * barHei
        ctx.fillStyle = "#EEF0F2"
        if ts - DAY + (HOUR * i) <= scope.postParams.timestamp < ts - DAY + (HOUR * (i+1))
            ctx.fillStyle = "#2FA0F4"
        ctx.fillRect i*barWid, barHei-hei, (barWid-spacer), hei

        # Draw posts bricks
        rulesLen = hour?.placeholders?.length
        if rulesLen >= 5
            rulesMax = 5
            postsMax = 0
        rulesMax = rulesLen
        postsMax = 5 - rulesMax

        max = hour?.postsTotal or 0
        if max < postsMax
            postsMax = max

        lastY = barHei
        ctx.fillStyle = greenColor
        for j in [0...postsMax]
            ctx.fillRect i*barWid, barHei + 2 + (j*4), (barWid-spacer), 3
            lastY = barHei + 2 + (j*4) + 2

        for j in [0...rulesMax]
            if hour?.placeholders[j].timestamp == scope.postParams.timestamp
                ctx.fillStyle = "#2FA0F4"
            else if hour?.placeholders[j].combId? and hour?.placeholders[j].combId == scope.postParams.combId
                ctx.fillStyle = "#99CFF9"
            else
                ctx.fillStyle = '#EEF0F2'
            ctx.fillRect i*barWid, lastY + 2 + (j*4), (barWid-spacer), 3

        # Draw activityBlock
        if !hour? or hour.total == 0
            continue
        hei = Math.ceil hour.total / maxValue * barHei
        if hour.total < hour.history
            ctx.fillStyle = redColor # "#C1272D"
        else
            ctx.fillStyle = greenColor # "#8CC63F"
        if ts + (HOUR * i) <= scope.postParams.timestamp < ts + (hour * (i+1))
            ctx.fillStyle = "#3fa9f5"
        ctx.fillRect i*barWid, barHei-hei, (barWid-spacer), hei

    # Draw legend
    # * Font settings
    ctx.strokeStyle = 'rgb(230,230,230)'
    ctx.font = '300 8px Roboto'
    ctx.fillStyle = '#999999'
    ctx.textAlign = 'center'
    ctx.textBaseline = 'middle'

    # * Drawing loop
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
            placeholders: []
            postsTotal: 0
            postsGood: 0
            postsBad: 0

    for stat in scope.stats
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
        id = Math.floor (timestamp - realTs) / period

        hourStats[id].postsTotal++
        hourStats[id].posts.push
            type: 'post'

    pHoldersCache = {}
    if scope.rulesData[0]?.length > 0
        for rule in scope.rulesData[0]
            dO = new Date rule.timestampStart
            id = dO.getHours()
            dayTime = (HOUR * id) + (MIN * dO.getMinutes())
            ruleDayTs = realTs + dayTime
            if ruleDayTs < Date.now()
                continue

            if pHoldersCache[dayTime]?
                continue
            pHoldersCache[dayTime] = true

            if postStat[ruleDayTs]?
                continue

            hourStats[id].placeholders.push
                combId: rule.combId
                timestamp: ruleDayTs

        for id in [0..totalBars-1]
            hourStats[id].placeholders.sort (a,b) ->
                if a.timestamp > b.timestamp
                    return 1
                if a.timestamp < b.timestamp
                    return -1
                0

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
scope.rulesData = []
ts = null
realTs = null
reloadStats = ->
    scope.stats.length = 0
    scope.posts.length = 0
    scope.rulesData.length = 0

    dateObj = new Date scope.postParams.timestamp
    realTs = new Date(dateObj.getFullYear(), dateObj.getMonth(), dateObj.getDate()).getTime()
    ts = realTs + DAY

    if scope.postParams.channelId?
        scope.rulesData.push ruleService.fetchByGroupId scope.postParams.channelId

    for communityId in scope.postParams.pickedCommunities
        statsCutService.get
            timestamp: ts
            communityId: communityId
        , (res) ->
            scope.stats.push res

        scope.posts.push scheduleService.getCommunityDay realTs, communityId

scope.$watch 'postParams.pickedCommunities', (nVal) ->
    if !nVal?
        return
    reloadStats()
, true

scope.$watch 'postParams.timestamp', (nVal) ->
    if !nVal?
        return
    reloadStats()
    updateStats()

scope.$watch 'postParams.combId', (nVal) ->
    updateStats()

scope.goUp = ->
    scope.postParams.timestamp -= DAY
scope.goDown = ->
    scope.postParams.timestamp += DAY

scope.$watch 'stats', ->
    updateStats()
, true

scope.$watch 'posts', ->
    updateStats()
, true

scope.$watch 'rulesData', ->
    updateStats()
, true

# Open Range
elem.on 'mousedown', (e) ->
    e.stopPropagation()

    if scope.flow? and (scope.flowFrame?.active != true or scope.flowBox?.active != true)
        scope.flow.activate scope.flowFrame, scope.flowBox
        scope.$apply()

handleBarSelect = (e) ->
    x = e.pageX - jcanvas.offset().left
    y = barHei - (e.pageY - jcanvas.offset().top)
    barId = x / (barWid) | 0

    if y > 0
        # Random minutes
        # minutes = getRandomInt(0,59)

        # Height defined minutes
        minutes = 59 * (y / barHei) | 0
        scope.postParams.timestamp = ts - DAY + (HOUR * barId) + (MIN * minutes)
    else
        y += 2
        brickId = Math.abs(y) / 4 | 0
        rulesLen = hourStats[barId].placeholders.length
        if rulesLen >= 5
            postsLen = 0
            rulesLen = 5
        else
            postsLen = 5 - rulesLen

        if hourStats[barId].posts.length < postsLen
            postsLen = hourStats[barId].posts.length

        if brickId < postsLen
            return
        else if rulesLen > 0
            phId = brickId - postsLen
            if rulesLen <= phId
                phId = rulesLen - 1

            scope.postParams.timestamp = hourStats[barId].placeholders[phId].timestamp

    scope.$applyAsync()

jcanvas.on 'mousedown', (e) ->
    handleBarSelect e
    body.on 'mousemove.canvasBarSelect', handleBarSelect
    body.on 'mouseup.canvasBarSelect', (e) ->
        body.off 'mousemove.canvasBarSelect'
        body.off 'mouseup.canvasBarSelect'
