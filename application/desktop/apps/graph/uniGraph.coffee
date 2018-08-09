buzzlike.directive 'uniGraph', ($filter,localization) ->
    restrict: 'C'
    link: (scope, element, attrs) ->

        elem = $ element
        dots = $ elem.find('.dots')[0]
        helper = $ elem.find('.helper')[0]
        hoverBar = $ elem.find('.hoverBar')[0]
        canvas = elem.find('canvas')[0]
        jcanvas = $ canvas
        ctx = canvas.getContext('2d')

        globalHelper = $('#graphHelper')
        globalHelperText = $ globalHelper.children('.plate')[0]
        showHelper = (text, x, y) ->
            globalHelper.addClass 'visible'
            globalHelperText.html text
            globalHelper.css
                top: y + scope.session.coords.y + 30 + 90 - 53
                left: x + scope.session.coords.x + 30

        hideHelper = ->
            globalHelper.removeClass 'visible'

        sideMargin = 40
        topMargin = 10
        bottomMargin = 40
        workWidth = 0
        workHeight = 0

        graphMode = 0 # 0 - compact, 1 - real

        scope.graphType = 'cumulative'
        scope.setGraphType = (type) ->
            scope.graphType = type
            buildLines()
            rebuildGraph()

        scope.linesType = 'overall'
        scope.toggleLinesType = ->
            if scope.linesType == 'discrete'
                scope.linesType = 'overall'
            else
                scope.linesType = 'discrete'
            buildLines()
            rebuildGraph()

        lineColors =
            activity: '#555454'
            likes: '#D50000'
            reposts: '#4B6A88'
            comments: '#3E3E3E'
            commLikes: '#8A2BE2'

        linesCnt = 0
        maxValue = 0
        minTime = 0
        maxTime = 0
        scope.showLine = 
            likes: true
            comments: true
            commLikes: true
            reposts: true
            activity: true

        scope.lines = []
        scope.toggleLine = (line) ->
            scope.showLine[line.type] = !scope.showLine[line.type]
            rebuildGraph()

        buildLines = ->
            scope.lines.length = 0

            switch scope.item?.type
                when 'statsCut'
                    graphMode = 1

                    switch scope.item.statsCutType 
                        when 'day'
                            minTime = scope.item.timestamp - DAY
                            maxTime = scope.item.timestamp
                        when 'week'
                            minTime = scope.item.timestamp - WEEK
                            maxTime = scope.item.timestamp
                        when 'month'
                            dObj = new Date scope.item.timestamp
                            maxTime = scope.item.timestamp
                            minTime = new Date(dObj.getFullYear(), dObj.getMonth()-1).getTime()

                    if scope.linesType == 'discrete'
                        for k,v of scope.item.stats
                            if k not in ['likes','reposts','commLikes','comments'] then continue

                            newLine =
                                type: k
                                color: lineColors[k]
                                total: v
                                active: true
                                dots: [
                                    ts: minTime
                                    val: 0
                                ]
                                avgs: [
                                    ts: minTime
                                    val: 0
                                ]

                            val = 0
                            for stat,i in scope.item.history
                                if scope.graphType == 'cumulative'
                                    val += stat.delta[k]
                                else
                                    val = stat.delta[k] / ((stat.ts - (scope.item.history[i-1]?.ts or 0)) / MIN)
                                if val > maxValue then maxValue = val
                                
                                if stat.ts > maxTime or stat.ts < minTime
                                    continue

                                newLine.dots.push
                                    ts: stat.ts
                                    val: val

                            newLine.dots.push 
                                ts: maxTime
                                val: val

                            val = 0
                            for stat,i in scope.item.forecast
                                if scope.graphType == 'cumulative'
                                    val += stat.delta[k]
                                else
                                    val = stat.delta[k] / ((stat.ts - (scope.item.forecast[i-1]?.ts or 0)) / MIN)
                                if val > maxValue then maxValue = val
                                
                                ts = minTime + stat.ts
                                if ts > maxTime or ts < minTime
                                    continue
                                if ts < 0
                                    continue

                                newLine.avgs.push
                                    ts: minTime + stat.ts
                                    val: val

                            newLine.avgs.push 
                                ts: maxTime
                                val: scope.item.delta[k]

                            scope.lines.push newLine
                    else
                        k = 'activity'
                        newLine = 
                            type: k
                            color: lineColors[k]
                            total: scope.item.stats[k]
                            active: true
                            dots: [
                                ts: minTime
                                val: 0
                            ]
                            avgs: [
                                ts: minTime
                                val: 0
                            ]

                        val = 0
                        for stat,i in scope.item.history
                            if scope.graphType == 'cumulative'
                                val += stat.delta[k]
                            else
                                # console.log stat.delta[k], ((stat.ts - (scope.item.history[i-1]?.ts or 0)) / MIN)
                                val = stat.delta[k] / ((stat.ts - (scope.item.history[i-1]?.ts or 0)) / MIN)
                            if val > maxValue then maxValue = val

                            if stat.ts > maxTime or stat.ts < minTime
                                continue

                            newLine.dots.push
                                ts: stat.ts
                                val: val

                        newLine.dots.push
                            ts: maxTime
                            val: val

                        val = 0
                        for stat,i in scope.item.forecast
                            if scope.graphType == 'cumulative'
                                val += stat.delta[k]
                            else
                                val = stat.delta[k] / ((stat.ts - (scope.item.forecast[i-1]?.ts or 0)) / MIN)
                            if val > maxValue then maxValue = val
                            
                            ts = minTime + stat.ts
                            if ts > maxTime or ts < minTime
                                continue
                            if ts < 0
                                continue

                            newLine.avgs.push
                                ts: minTime + stat.ts
                                val: val

                        newLine.avgs.push
                            ts: maxTime
                            val: scope.item.delta[k]

                        scope.lines.push newLine

                when 'schedule'
                    graphMode = 0

                    if scope.linesType == 'discrete'
                        for k,v of scope.item.lastStats
                            if k not in ['likes','reposts','commLikes','comments'] then continue

                            newLine =
                                type: k
                                color: lineColors[k]
                                total: v
                                active: true
                                dots: [
                                    ts: 0
                                    val: 0
                                ]
                                avgs: [
                                    ts: 0
                                    val: 0
                                ]

                            for stat,i in scope.item.stats
                                if scope.graphType == 'cumulative'
                                    val = stat.stats[k]
                                else
                                    val = (stat.stats[k] - (scope.item.stats[i-1]?.stats[k] or 0)) / (stat.delay / MIN)
                                if val > maxValue then maxValue = val
                                if stat.delay < minTime or minTime == 0 then minTime = stat.delay
                                if stat.delay > maxTime or maxTime == 0 then maxTime = stat.delay
                                newLine.dots.push
                                    ts: stat.delay
                                    val: val

                            for stat,i in scope.item.stats
                                if scope.graphType == 'cumulative'
                                    val = stat.avgStats[k]
                                else
                                    val = (stat.avgStats[k] - (scope.item.stats[i-1]?.avgStats[k] or 0)) / (stat.delay / MIN)
                                if val > maxValue then maxValue = val
                                if stat.delay < minTime or minTime == 0 then minTime = stat.delay
                                if stat.delay > maxTime or maxTime == 0 then maxTime = stat.delay
                                newLine.avgs.push
                                    ts: stat.delay
                                    val: val

                            scope.lines.push newLine
                    else
                        k = 'activity'
                        newLine = 
                            type: k
                            color: lineColors[k]
                            total: scope.item.lastActivity
                            active: true
                            dots: [
                                ts: 0
                                val: 0
                            ]
                            avgs: [
                                ts: 0
                                val: 0
                            ]


                        for stat,i in scope.item.stats
                            if scope.graphType == 'cumulative'
                                val = stat.stats[k]
                            else
                                val = (stat.stats[k] - (scope.item.stats[i-1]?.stats[k] or 0)) / (stat.delay / MIN)
                            if val > maxValue then maxValue = val
                            if stat.delay < minTime or minTime == 0 then minTime = stat.delay
                            if stat.delay > maxTime or maxTime == 0 then maxTime = stat.delay
                            newLine.dots.push
                                ts: stat.delay
                                val: val

                        for stat,i in scope.item.stats
                            if scope.graphType == 'cumulative'
                                val = stat.avgStats[k]
                            else
                                val = (stat.avgStats[k] - (scope.item.stats[i-1]?.avgStats[k] or 0)) / (stat.delay / MIN)
                            if val > maxValue then maxValue = val
                            if stat.delay < minTime or minTime == 0 then minTime = stat.delay
                            if stat.delay > maxTime or maxTime == 0 then maxTime = stat.delay
                            newLine.avgs.push
                                ts: stat.delay
                                val: val

                        scope.lines.push newLine
            true

        drawLine = (startX, startY, endX, endY) ->
            ctx.beginPath()
            ctx.moveTo startX - 0.5, startY + 0.5
            ctx.lineTo endX - 0.5, endY + 0.5
            ctx.stroke()

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

        positionHelper = (x, y) ->
            if x > workWidth / 2 + sideMargin
                # left-side
                helper.css
                    left: 'auto'
                    right: workWidth + sideMargin * 2 - x + 15
                    top: y - 20
            else
                helper.css
                    right: 'auto'
                    left: x + 15
                    top: y - 20

        drawSeries = (series, line, avg = false) ->
            for dot,i in series
                if i > 0 and dot.val == series[i-1].val and i < series.length - 1 and dot.val == series[i+1].val
                    continue

                # Determine x
                if graphMode == 0
                    x = sideMargin + i / (scope.item.stats.length) * workWidth
                else
                    x = sideMargin + (dot.ts - minTime) / (maxTime - minTime) * workWidth
                    # console.log x, dot.ts, maxTime, minTime
                # Determine y
                y = topMargin + workHeight - dot.val / maxValue * workHeight

                if i == 0
                    ctx.moveTo x, y
                else
                    ctx.lineTo x, y

                if !avg
                    dotElem = $ '<div>',
                        class: 'dot'
                        css: 
                            top: y
                            left: x
                            borderColor: line.color
                            borderWidth: if avg then 2


                    do (x,y,dot,line) ->
                        dotElem.on 'mouseenter', () ->
                            # fill helper
                            if scope.item.type == 'statsCut'
                                # console.log scope.item.statsCutType, scope.item.timestamp, dot.ts
                                # switch scope.item.statsCutType
                                #     when 'day'
                                #         statTS = scope.item.timestamp - DAY + dot.ts
                                #     when 'week'
                                #         statTS = scope.item.timestamp - WEEK + dot.ts
                                #     when 'month'
                                #         dObj = new Date scope.item.timestamp
                                #         statTS = new Date(dObj.getFullYear(), dObj.getMonth()-1).getTime() + dot.ts
                                statTS = dot.ts
                            else
                                statTS = scope.item.timestamp - dot.ts

                            time1 = $filter('timestampMask')(statTS, 'DD MMM')
                            time2 = $filter('timestampMask')(statTS, 'hч. mмин.')

                            # Leave maximum 1 number after dot
                            points = 10 * dot.val
                            points = points | 0
                            points /= 10
                            intPoints = points | 0
                            points = $filter('formatNumber')(points)

                            localization.onLangLoaded ->
                                text = points + ' '
                                text += localization.declensionPhrase intPoints, 'graphApp_points_type_' + line.type

                                if scope.graphType != 'cumulative'
                                    text += ' в минуту'
                                    forWord = 'на'
                                    if scope.item.type == 'schedule'
                                        forWord = 'спустя'
                                else
                                    forWord = 'за'
                                text += '<br>'

                                switch scope.item.statsCutType 
                                    when 'day'
                                        if statTS == scope.item.timestamp
                                            if scope.graphType != 'cumulative'
                                                text += 'на конец дня'
                                            else
                                                text += forWord + ' день'
                                        else
                                            text += forWord + ' '
                                            text += time2
                                    when 'week'
                                        if statTS == scope.item.timestamp
                                            if scope.graphType != 'cumulative'
                                                text += 'на конец недели'
                                            else
                                                text += forWord + ' неделю'
                                        else
                                            text += forWord + ' '
                                            localTS = dot.ts - scope.item.timestamp + WEEK
                                            if localTS > DAY
                                                text += (localTS / DAY | 0) + 'д. '
                                            text += time2
                                    when 'month'
                                        if statTS == scope.item.timestamp
                                            if scope.graphType != 'cumulative'
                                                text += 'на конец месяца'
                                            else
                                                text += forWord + ' месяц'
                                        else
                                            text += forWord + ' '
                                            dObj = new Date scope.item.timestamp
                                            localTS = dot.ts - new Date(dObj.getFullYear(), dObj.getMonth()-1).getTime()
                                            if localTS > DAY
                                                text += (localTS / DAY | 0) + 'д. '
                                            text += time2

                                if scope.item.type == 'schedule'
                                    text += forWord + ' '
                                    text += humanDays dot.ts

                                showHelper text, x, y

                    dotElem.on 'mouseleave', () ->
                        hideHelper()

                    dots.append dotElem


        drawGraph = ->
            cWid = scope.session.size.width - 60
            cHei = scope.session.size.height - 190

            workWidth = cWid - ( 2 * sideMargin )
            workHeight = cHei - topMargin - bottomMargin

            canvas.width = cWid
            canvas.height = cHei

            if window.devicePixelRatio > 1
                canvas.width = cWid * window.devicePixelRatio
                canvas.height = cHei * window.devicePixelRatio

                ctx.scale window.devicePixelRatio, window.devicePixelRatio

            jcanvas.width cWid
            jcanvas.height cHei

            # Clear
            ctx.clearRect 0, 0, canvas.width, canvas.height
            dots.empty()

            # Draw coordinate lines
            ctx.lineCap = 'butt'
            ctx.lineWidth = 1
            ctx.strokeStyle = 'rgb(180,180,180)'
            # drawLine sideMargin, topMargin, sideMargin, topMargin + workHeight
            # drawLine sideMargin, topMargin + workHeight, workWidth + sideMargin, topMargin + workHeight

            if !scope.item?.stats? then return

            # Draw vertical lines
            ctx.strokeStyle = 'rgb(230,230,230)'
            ctx.font = '12px Helvetica Neue'
            ctx.fillStyle = '#554545'
            ctx.textAlign = 'center'
            ctx.textBaseline = 'middle'

            captWid = 20
            switch scope.item.statsCutType 
                when 'day'
                    linesCnt = 24
                    captWid = 40
                when 'week'
                    linesCnt = 7
                when 'month'
                    linesCnt = (maxTime - minTime) / DAY | 0
                else
                    linesCnt = scope.item.stats.length or 0

            lineWid = workWidth / linesCnt
            lastX = sideMargin
            lastMark = 0
            for i in [0...linesCnt]
                lastX += lineWid
                x = Math.ceil(lastX)
                # drawLine x, topMargin, x, topMargin + workHeight-1
                # Time mark
                if lastX - lastMark > captWid
                    lastMark = lastX
                    
                    switch scope.item.statsCutType 
                        when 'day'
                            caption = (i+1)
                            if caption < 10
                                caption = '0' + caption
                            caption += ':00'
                        when 'week'
                            if i == linesCnt - 1
                                caption = localization.translate(147)[1]
                            else
                                caption = localization.translate(147 + i + 1)[1]

                            x -= lineWid / 2
                        when 'month'
                            caption = (i+2)
                        else
                            caption = humanDays(scope.item.stats[i].delay)
                    ctx.fillText caption, x, topMargin + workHeight + 20

            # Horizontal
            ctx.textAlign = 'right'
            dig = (maxValue+"").length
            big = 1
            big *= 10 for i in [0...dig-1]

            bigLines = maxValue/big | 0

            for i in [0..bigLines]
                y = workHeight + topMargin - (workHeight / maxValue) * (big * i)
                y = Math.ceil y
                drawLine sideMargin+1, y, sideMargin + workWidth, y
                if i > 0
                    ctx.fillText simpleNumber(big*i,1), sideMargin - 15, y

            if bigLines == 1
                smallLines = big / 2 | 0

                horLinesCnt = maxValue / smallLines | 0

                for i in [1..horLinesCnt]
                    y = workHeight + topMargin - (workHeight / maxValue) * (smallLines * i)
                    y = Math.ceil y
                    drawLine sideMargin+1, y, sideMargin + workWidth, y
                    ctx.fillText simpleNumber(smallLines*i,1), sideMargin - 15, y

            # Last line
            drawLine sideMargin+1, topMargin, sideMargin + workWidth, topMargin
            if ( !y? or y - topMargin > 12 )
                ctx.fillText simpleNumber(maxValue,1), sideMargin - 15, topMargin


            # Draw lines
            ctx.lineCap = 'round'
            for line in scope.lines
                if !scope.showLine[line.type] then continue

                # Line
                ctx.beginPath()
                ctx.lineWidth = 2
                ctx.strokeStyle = line.color
                ctx.setLineDash []
                drawSeries line.dots, line
                ctx.stroke()

                # Average
                ctx.beginPath()
                ctx.lineWidth = 1
                ctx.strokeStyle = line.color
                ctx.setLineDash [5,5]
                drawSeries line.avgs, line, true

                ctx.stroke()

            true

        rebuildGraph = ->
            maxValue = 0

            if graphMode == 0
                minTime = 0
                maxTime = 0

            for line in scope.lines
                if !scope.showLine[line.type] then continue

                for dot in line.dots
                    if dot.val > maxValue then maxValue = dot.val

                    if graphMode == 0
                        if dot.ts < minTime or minTime == 0 then minTime = dot.ts
                        if dot.ts > maxTime or maxTime == 0 then maxTime = dot.ts

                for dot in line.avgs
                    if dot.val > maxValue then maxValue = dot.val

                    if graphMode == 0
                        if dot.ts < minTime or minTime == 0 then minTime = dot.ts
                        if dot.ts > maxTime or maxTime == 0 then maxTime = dot.ts

                maxValue = Math.ceil maxValue

            drawGraph()
            true

        elem.on 'mousemove', (e) ->
            x = e.pageX - scope.session.coords.x - 40 - 30
            bar = x / workWidth * linesCnt | 0
            barWid = (workWidth / linesCnt)

            if bar > linesCnt - 1
                bar = linesCnt - 1

            hoverBar.css 
                left: bar * barWid
                width: barWid

        buildLines()
        rebuildGraph()

        scope.onResizeProgress ->
            drawGraph()
        , false

