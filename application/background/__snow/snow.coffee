buzzlike.directive "snowScreen", (user, resize) ->
    restrict: "AC"
    template: '<div class="fpsCounter"></div><canvas class="snow" width="'+window.innerWidth+'" height="'+window.innerHeight+'"></canvas><canvas class="snowStack" width="'+window.innerWidth+'" height="'+window.innerHeight+'"></canvas>'
    link: (scope, element, attrs) ->
        elem = $ element
        canvas = {
            canv: elem.find('canvas.snow')[0]
            ctx:  elem.find('canvas.snow')[0].getContext('2d')
            canvStack: elem.find('canvas.snowStack')[0]
            ctxStack:  elem.find('canvas.snowStack')[0].getContext('2d')
            width: window.innerWidth
            height: window.innerHeight
            fpsCounter: elem.find('.fpsCounter')
        }

        phys = {
            allowAnimation: false
            gravity: 80 #px per sec down
            wind: getRandomInt -20, 20
        }

        clearCanvas = ->
            canvas.ctx.clearRect(0, 0, canvas.width, canvas.height)
            canvas.fpsCounter.html ''

        clearStackCanvas = ->
            canvas.ctxStack.clearRect(0, 0, canvas.width, canvas.height)

        createSnowflake = ->
            snowflake = {
                x: getRandomInt -150, canvas.width+150
                y: getRandomInt -canvas.height, -10
                size: getRandomInt 1, 3
                speed: getRandomInt -20, 20
            }
            snow.push snowflake

        drawSnowflake = (sf) ->
            canvas.ctx.arc(sf.x, sf.y, sf.size, 0, 2*Math.PI)
            canvas.ctx.closePath()

        drawSnowStackFlake = (sf) ->
            clearStackCanvas()
            newY = Math.floor(sf.y)
            curX = Math.floor(sf.x)

            #snowflakesStack.push {x: sf.x, y: sf.y, size: sf.size}
            #snowflakesStack.shift() if snowflakesStack.length > 50 # stack limit

            #canvas.ctxStack.beginPath()
            #for i in snowflakesStack
            #    canvas.ctxStack.arc(i.x, i.y+i.size/2, i.size, 0, 2*Math.PI)
            #    canvas.ctxStack.closePath()
            #canvas.ctxStack.fill()

            for i in [curX-sf.size-5...curX+sf.size+5]
                x2 = (curX-i)*(curX-i) #x^2
                dy = sf.size*sf.size - x2/2

                sy = snowStack[i] + snowStack[i-1]
                if !sy then sy = canvas.height*2
                snowStack[i] = snowStack[i-1] = sy/2

                if dy > 0
                    y = Math.sqrt dy
                    snowStack[i] -= y

            canvas.ctxStack.beginPath()
            canvas.ctxStack.moveTo 0, canvas.height
            for i in [0...canvas.width] by 3
                canvas.ctxStack.bezierCurveTo i, snowStack[i], i+1, snowStack[i+1], i+2, snowStack[i+2]
            canvas.ctxStack.lineTo canvas.width, canvas.height
            #canvas.ctxStack.stroke()

            canvas.ctxStack.closePath()
            canvas.ctxStack.fill()

        maxFlakes = +localStorage['buzzlike.user.snowflakes'] || 50
        snow = []
        snowflakesStack = []
        snowStack = {}
        lastFrameTime = 0
        frames = 0
        fps = 0
        temperature = 0.2

        init = ->
            #snow.length = 0
            #snowflakesStack.length = 0
            #lastFrameTime = 0

            dx = window.innerWidth - canvas.width
            dy = window.innerHeight - canvas.height
            canvas.width = canvas.canv.width = canvas.canvStack.width = window.innerWidth
            canvas.height = canvas.canv.height = canvas.canvStack.height = window.innerHeight

            canvas.ctx.fillStyle = 'rgba(255, 255, 255, 0.7)'
            canvas.ctxStack.fillStyle = 'rgba(255, 255, 255, 0.7)'

            for i in [0...canvas.width+50]
                if snowStack[i]
                    snowStack[i] += dy
                else
                    snowStack[i] = snowStack[i-1]+getRandomInt(-3,3)

            if !snow.length
                for i in [0...maxFlakes]  #flakes limit
                    createSnowflake()

            localStorage['buzzlike.user.snowflakes'] = maxFlakes

        draw = (time) ->
            clearCanvas()
            frame_dt = (time - lastFrameTime) || 0
            frames++

            canvas.ctx.beginPath()

            for sf in snow
                if sf.y+sf.size < (snowStack[Math.round(sf.x)] or canvas.height)

                    sf.y += (phys.gravity+sf.speed)*frame_dt/1000
                    if phys.wind
                        sf.x += phys.wind*frame_dt/1000
                    else
                        sf.x += getRandomInt(-6, 6)*frame_dt/1000
                else
                    drawSnowStackFlake(sf)
                    sf.y = -10
                    sf.x = getRandomInt -150, canvas.width+150

                drawSnowflake(sf)

            canvas.ctx.fill()

            #flakes benchmark
            fps = Math.floor 1000/frame_dt if frame_dt
            if fps > 35 then maxFlakes++
            if fps < 25 then maxFlakes--

            if !(frames%20)
                #fps = Math.floor 1000/frame_dt
                #if fps > 35 then maxFlakes *= fps/35
                #if fps < 25 then maxFlakes -= 25-fps
                if fps < 15 then maxFlakes *= fps/15
                if maxFlakes < 30 then maxFlakes = 30
                #
                maxFlakes = Math.floor maxFlakes
                if snow.length > maxFlakes
                    snow.length = maxFlakes
                else
                    dmax = maxFlakes - snow.length
                    for i in [0...dmax]
                        createSnowflake()

                #canvas.fpsCounter.html "FPS: " + fps + ", Flakes: " + snow.length
                localStorage['buzzlike.user.snowflakes'] = snow.length

                maxH = snowStack[100]
                for i of snowStack
                    maxH = snowStack[i] if snowStack[i]<maxH
                    snowStack[i] += temperature if snowStack[i] < canvas.height and temperature

                temperature = maxFlakes/2000 + (1 - maxH/canvas.height) #speed of snow disappearing
                #blog temperature, maxH, canvas.height

            lastFrameTime = time

            if !(frames%2000) then phys.wind = getRandomInt -20, 20


        Loop = (time) ->
            if phys.allowAnimation
                requestAnimFrame Loop
                draw(time)
            else return false

        #Loop()

        scope.$watch () ->
            user.animPrefs.snow
        , (nVal) ->
            if nVal
                init()
                phys.allowAnimation = true
                Loop()
            else
                phys.allowAnimation = false
                clearCanvas()
                clearStackCanvas()

        , true

        resize.registerCb init
