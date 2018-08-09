buzzlike.directive 'statsGraph', ($rootScope, $filter) ->
    restrict: 'C'
    link: (scope, element, attrs) ->

        workWidth = 240
        workHeight = 110

        elem = $ element
        
        canvas = elem.children('canvas')[0]
        context = canvas.getContext('2d')

        values = elem.children '.values'
        helper = elem.children '.helper'

        scope.scale = false
        scope.switchScale = (val) ->
            scope.scale = val
            drawGraph()

        if window.devicePixelRatio > 1
            canvasWidth = canvas.width
            canvasHeight = canvas.height

            canvas.width = canvasWidth * window.devicePixelRatio
            canvas.height = canvasHeight * window.devicePixelRatio
            canvas.style.width = canvasWidth
            canvas.style.height = canvasHeight

            context.scale window.devicePixelRatio, window.devicePixelRatio

        positionHelper = (x, y) ->
            if x > 160
                # left-side
                helper.css
                    left: 'auto'
                    right: 308 - x + 15
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

            if scope.scale
                maxGraphs = {}

            # Get maximum value
            max = 0
            for stat in scope.schedule.stats
                for k,v of stat.stats
                    if scope.showGhaph[k] != true
                        continue
                    max = v if v > max

                    if scope.scale
                        maxGraphs[k] = 0 if !maxGraphs[k]?
                        if v > maxGraphs[k]
                            maxGraphs[k] = v

            # Get total records
            bars = scope.schedule.stats.length

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
            for i in [0...bars]
                x = 34 + (workWidth / (bars-1)) * i

                if i > 0
                    drawLine x, 25, x, workHeight + 25

                # Time mark
                context.fillText humanDays(scope.schedule.stats[i].delay), x, 25 + workHeight + 15

            # Horizontal
            if !scope.scale
                context.textAlign = 'right'
                dig = (max+"").length
                big = 1
                big *= 10 for i in [0...dig-1]

                bigLines = max/big | 0

                for i in [0..bigLines]
                    y = workHeight + 25 - (workHeight / max) * (big * i)
                    horLine y, big * i

                if bigLines == 1
                    smallLines = big / 2 | 0

                    linesCnt = max / smallLines | 0

                    for i in [1..linesCnt]
                        y = workHeight + 25 - (workHeight / max) * (smallLines * i)
                        horLine y, (smallLines * i)

            # Last line
            horLine 25, max, !scope.scale and ( !y? or y - 25 > 12 )

            if scope.schedule.stats.length < 2
                return

            # Draw lines
            graphs = [
                id: 'likes'
                color: '#D50000' # '#ff0000'
            ,
                id: 'reposts'
                color: '#4B6A88' # '#0000ff'
            ,
                id: 'comments'
                color: '#3E3E3E' # '#00ff00'
            ,
                id: 'commLikes'
                color: '#8A2BE2' # 'yellow'
            ]

            values.empty()

            drawingLine = false

            for graph in graphs
                if scope.showGhaph[graph.id] != true
                    continue

                if !(scope.schedule.lastStats[graph.id] > 0)
                    continue

                lastValue = null

                for stat,i in scope.schedule.stats
                    if !stat.stats?[graph.id]?
                        continue

                    x = 34 + (workWidth / (bars-1)) * i
                    if scope.scale
                        y = workHeight + 25 - (workHeight / maxGraphs[graph.id]) * stat.stats[graph.id]
                    else
                        y = workHeight + 25 - (workHeight / max) * stat.stats[graph.id]

                    if !drawingLine
                        context.beginPath()
                        context.lineWidth = 3
                        context.strokeStyle = graph.color
                        context.moveTo x, y
                        drawingLine = true
                    else
                        context.lineTo x, y

                    if i == bars - 1 and drawingLine
                        context.stroke()

                    # Determine if should draw DOT
                    willChange = false
                    if !(i == bars - 1 or lastValue != stat.stats[graph.id])
                        if scope.schedule.stats[i+1]?
                            if scope.schedule.stats[i+1].stats[graph.id] != stat.stats[graph.id]
                                willChange = true

                    if willChange or i == bars - 1 or lastValue != stat.stats[graph.id]
                        # Create value dot
                        value = $ '<div>',
                            class: 'value'

                        value.css
                            'top': y + 'px'
                            'left': x + 'px'
                            'border-color': graph.color

                        do (x,y,stat,graph) ->
                            value.on 'mouseenter', () ->
                                # fill helper
                                statTS = scope.schedule.timestamp + stat.delay
                                time1 = $filter('timestampMask')(statTS, 'DD MMM')
                                time2 = $filter('timestampMask')(statTS, 'hh:mm')
                                points = $filter('formatNumber')(stat.stats[graph.id])
                                helper.empty()
                                helper.html "<div class='points'><div class='icon #{graph.id}'></div>#{points}</div><div class='time'>#{time2}</div><div class='time'>#{time1}</div>"
                                # position helper
                                positionHelper x, y
                                # show helper
                                helper.addClass 'visible'

                        value.on 'mouseleave', () ->
                            # hide helper
                            helper.removeClass 'visible'

                        values.append value

                    lastValue = stat.stats[graph.id]

                if drawingLine
                    context.stroke()
                    drawingLine = false

            # - reposts
            # - comments
            # - commLikes

        drawGraph()

        scope.$watch 'showGhaph', (nVal) ->
            drawGraph()
        , true

        true