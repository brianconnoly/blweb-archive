buzzlike
    .directive 'pollGraph', ($filter) ->
        restrict: 'C'
        link: (scope, element, attrs) ->

            workWidth = 332
            workHeight = 160

            elem = $ element
            
            canvas = elem.children('canvas')[0]
            context = canvas.getContext('2d')

            values = elem.children '.values'
            helper = elem.children '.helper'

            if window.devicePixelRatio > 1
                canvasWidth = canvas.width
                canvasHeight = canvas.height

                canvas.width = canvasWidth * window.devicePixelRatio
                canvas.height = canvasHeight * window.devicePixelRatio
                canvas.style.width = canvasWidth
                canvas.style.height = canvasHeight

                context.scale window.devicePixelRatio, window.devicePixelRatio

            positionHelper = (x, y) ->
                if x > 200
                    # left-side
                    helper.css
                        left: 'auto'
                        right: 400 - x + 15
                        top: y - 20
                else
                    helper.css
                        right: 'auto'
                        left: x + 15
                        top: y - 20

            drawLine = (startX, startY, endX, endY) ->
                context.beginPath()
                context.moveTo startX, startY
                context.lineTo endX, endY
                context.stroke()

            humanDays = (ts) ->
                if ts >= 30 * DAY
                    ts = ts / 30 * DAY | 0
                    return ts + ' м'

                if ts == 7 * DAY
                    return '1 н'

                if ts >= DAY
                    ts = ts / DAY | 0
                    return ts + ' д'

                if ts >= HOUR
                    ts = ts / HOUR | 0
                    return ts + ' ч'

                ts = ts / MIN | 0
                return ts + ' м'

            simpleCache = {}
            simpleNumber = (number) ->
                if simpleCache[number]?
                    return simpleCache[number]

                if number >= 1000000
                    simpleCache[number] = (number / 1000000).toFixed(1)
                    if simpleCache[number][simpleCache[number].length-1] == '0'
                        simpleCache[number] = simpleCache[number].substring(0, simpleCache[number].length - 2)
                    simpleCache[number] += 'm'
                
                else if number >= 1000
                    simpleCache[number] = (number / 1000).toFixed(1)
                    if simpleCache[number][simpleCache[number].length-1] == '0'
                        simpleCache[number] = simpleCache[number].substring(0, simpleCache[number].length - 2)
                    simpleCache[number] += 'k'
                else 
                    simpleCache[number] = number

                return simpleCache[number]

            horLine = (y, val, drawNum = true) ->
                drawLine 34, y, 34 + workWidth, y
                context.fillText simpleNumber(val,1), 25, y if drawNum

            drawGraph = ->
                context.clearRect 0, 0, canvas.width, canvas.height

                # Get maximum value
                max = 0
                minTime = 0
                maxTime = 0

                for stat in scope.poll.stats

                    if minTime == 0 or stat.ts < minTime
                        minTime = stat.ts

                    if maxTime == 0 or stat.ts > maxTime
                        maxTime = stat.ts

                    if scope.currentSchedule == null
                        answers = stat.stats.answers
                    else
                        answers = stat.stats.schedResults[scope.currentSchedule]?.answers

                    if !answers?
                        continue

                    for v,i in answers
                        if scope.hiddenAnswer[i] == true
                            continue
                        max = v if v > max

                diff = maxTime - minTime

                if diff < HOUR * 3
                    delta = HOUR / 4
                    dateObj = new Date minTime

                    hours = dateObj.getHours()
                    minutes = dateObj.getMinutes()
                    if minutes > 50
                        minutes = 0
                        hours++
                    else if minutes > 35
                        minutes = 45
                    else if minutes > 20
                        minutes = 30
                    else if minutes > 5
                        minutes = 15
                    else
                        minutes = 0

                    startBars = new Date(dateObj.getFullYear(),dateObj.getMonth(), dateObj.getDate(),hours, minutes).getTime()
                else if diff < DAY
                    delta = HOUR
                    dateObj = new Date minTime
                    startBars = new Date(dateObj.getFullYear(),dateObj.getMonth(), dateObj.getDate(),dateObj.getHours()).getTime() + HOUR
                else
                    delta = DAY
                    dateObj = new Date minTime
                    startBars = new Date(dateObj.getFullYear(),dateObj.getMonth(), dateObj.getDate()).getTime() + DAY

                # Get total records
                bars = scope.poll.stats.length

                # Draw coordinate lines
                context.lineWidth = 1
                context.strokeStyle = 'rgb(180,180,180)'
                drawLine 34, 24, 34, workHeight + 26
                drawLine 34, workHeight + 25, workWidth + 34, workHeight + 25

                # Draw grid
                context.lineWidth = 0.5
                context.strokeStyle = 'rgb(230,230,230)'

                context.font = '8px Helvetica Neue'
                context.fillStyle = '#aaa'
                
                # Vertical
                context.textAlign = 'center'
                lastMark = 34
                context.fillText $filter('timestampMask')(minTime, 'hh:mm'), 34, 25 + workHeight + 15

                for ts in [startBars..maxTime] by delta
                    x = 34 + ((ts - minTime) / diff) * workWidth

                    if x > 0
                        drawLine x, 25, x, workHeight + 25

                    if x - lastMark > 30 and x < 34 + workWidth - 30
                        lastMark = x
                        if delta < DAY
                            context.fillText $filter('timestampMask')(ts, 'hh:mm'), x, 25 + workHeight + 15
                        if delta == DAY
                            context.fillText $filter('timestampMask')(ts, 'DD MMM'), x, 25 + workHeight + 15

                # Last line
                drawLine workWidth + 34, 25, workWidth + 34, workHeight + 25
                context.fillText $filter('timestampMask')(maxTime, 'hh:mm'), workWidth + 34, 25 + workHeight + 15

                # Horizontal
                context.textAlign = 'right'
                dig = (max+"").length
                big = 1
                big *= 10 for i in [0...dig-1]

                bigLines = max/big | 0

                # for i in [0...bigLines]
                #     y = workHeight + 25 - (workHeight / max) * big
                #     horLine y, big
                if bigLines == 1
                    smallLines = big / 2 | 0

                    linesCnt = max / smallLines | 0

                    for i in [1..linesCnt]
                        y = workHeight + 25 - (workHeight / max) * (smallLines * i)
                        horLine y, (smallLines * i)

                # Last line
                horLine 25, max, !scope.scale and ( !y? or y - 25 > 15 )

                if scope.poll.stats.length < 2
                    return

                values.empty()

                if scope.currentSchedule == null
                    currList = scope.poll.lastStats.answers
                else
                    currList = scope.poll.lastStats.schedResults[scope.currentSchedule]?.answers

                drawingLine = false

                for graph,id in currList
                    if scope.hiddenAnswer[id] == true
                        continue

                    if !(graph > 0)
                        continue

                    lastValue = null

                    for stat,i in scope.poll.stats

                        if scope.currentSchedule == null
                            currStat = stat.stats.answers
                        else
                            currStat = stat.stats.schedResults[scope.currentSchedule]?.answers

                        if !currStat?[id]?
                            continue

                        # Determine x
                        x = 34 + ((stat.ts - minTime) / diff) * workWidth

                        # x = 34 + (workWidth / (bars-1)) * i
                        y = workHeight + 25 - (workHeight / max) * currStat[id]

                        if !drawingLine
                            context.beginPath()
                            context.lineWidth = 3
                            context.strokeStyle = scope.colors[id]
                            context.moveTo x, y
                            drawingLine = true
                        else
                            context.lineTo x, y

                        if i == bars - 1 and drawingLine
                            context.stroke()

                        # Create value dot

                        # Determine if should draw DOT
                        willChange = false
                        if !(i == bars - 1 or lastValue != currStat[id])
                            if scope.poll.stats[i+1]?
                                if scope.currentSchedule == null
                                    willStat = scope.poll.stats[i+1].stats.answers
                                else
                                    willStat = scope.poll.stats[i+1].stats.schedResults[scope.currentSchedule]?.answers

                                if willStat[id] != currStat[id]
                                    willChange = true

                        if willChange or i == bars - 1 or lastValue != currStat[id]
                            value = $ '<div>',
                                class: 'value'

                            value.css
                                'top': y + 'px'
                                'left': x + 'px'
                                'border-color': scope.colors[id]

                            do (x,y,stat,graph,currStat,id) ->
                                value.on 'mouseenter', () ->
                                    # fill helper
                                    statTS = stat.ts
                                    time1 = $filter('timestampMask')(statTS, 'DD MMM')
                                    time2 = $filter('timestampMask')(statTS, 'hh:mm')
                                    points = $filter('formatNumber')(currStat[id])
                                    helper.empty()
                                    helper.html "<div class='points'>#{points}</div><div class='time'>#{time2}</div><div class='time'>#{time1}</div>"
                                    # position helper
                                    positionHelper x, y
                                    # show helper
                                    helper.addClass 'visible'

                            value.on 'mouseleave', () ->
                                # hide helper
                                helper.removeClass 'visible'

                            values.append value

                        lastValue = currStat[id]

                    if drawingLine
                        context.stroke()
                        drawingLine = false

                # - reposts
                # - comments
                # - commLikes

            scope.$watch 'currentSchedule', () ->
                drawGraph()

            scope.$watch 'hiddenAnswer', (nVal) ->
                drawGraph()
            , true

            drawGraph()
            true