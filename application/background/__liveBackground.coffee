buzzlike.directive 'liveBackground', (user) ->
    restrict: 'C'
    link: (scope, element, attrs) ->
        scope.prefs = user.animPrefs
        available = true
        counter = 0
        cnt = 0
        body = $('body')
        container = $(element).children('.container')

        drawCircle = (ctx, size, blurry, opacity) ->
            # Draw random circle
            gradSize = Math.floor size/2
            #radgrad = ctx.createRadialGradient(gradSize,gradSize,gradSize*blurry,gradSize,gradSize,gradSize)
            #radgrad.addColorStop(0, 'rgba(255,255,255,'+opacity+')')
            #radgrad.addColorStop(blurry, 'rgba(255,255,255,'+0.1+')')
            #radgrad.addColorStop(1, 'rgba(255,255,255,0)')
            #ctx.fillStyle = radgrad
            #ctx.fillRect(0,0,size,size)

            ctx.beginPath()
            ctx.arc(gradSize,gradSize,gradSize/1.5,0,2*Math.PI)
            ctx.closePath()
            ctx.fillStyle = 'rgba(255,255,255,'+opacity+')'
            ctx.fill()

            true

        drawPoly = (ctx, size, blurry, opacity, angles) ->
            ctx.beginPath();
            size = size/3
            ctx.shadowBlur = 5
            ctx.shadowColor = "rgba(255, 255, 255, 1)"
            ctx.lineJoin = "round"
            ctx.translate(size, size)

            ctx.rotate(2*Math.PI/angles)
            ctx.moveTo(0,size);
            for i in [0..angles]
                ctx.rotate(2*Math.PI/angles)
                ctx.lineTo(0,size);

            #ctx.fillStyle = radgrad
            ctx.fillStyle = "rgba(255, 255, 255, "+opacity/100+")"
            ctx.fill()


        true

        random = (from,to) -> Math.floor(Math.random()*(to-from+1)+from)

        createRandom = (pos) ->
            counter++
            size = random 20, 300 #250

            blurry = random(60, 95) / 100
            opacity = random(30, 60) / 100

            #cnv = $ '<canvas class="circles anim-show-hide" width='+size+' height='+size+' >'
            cnv = $ '<div class="circles anim-show-hide">'
            time = ( random(50, 100) / 10 ) * 2

            cnv.css
                'position': 'absolute'
                'width': size + 'px'
                'height': size + 'px'
                'top': (pos.y - Math.floor(size/2)) + 'px'
                'left': (pos.x - Math.floor(size/2)) + 'px'
                'opacity': 0
                '-webkit-animation-duration': time+'s'
                'animation-duration': time+'s'
                'transform': 'translate('+(random(-80, 80)||5555) + 'px, ' + (random(-80, 80)||5555) + 'px)'
                '-webkit-transform': 'translate('+(random(-80, 80)||5555) + 'px, ' + (random(-80, 80)||5555) + 'px)'
                'border-radius': '50%'
                'background': 'rgba(255, 255, 255, '+opacity+')'
                #'-webkit-filter': 'blur(20px)'

            #ctx = cnv[0].getContext('2d')
            #drawCircle(ctx, size, blurry, opacity)

            cnt++
            container.append cnv

            setTimeout () ->
                cnv.remove()
                cnt--
            , time*1000

        play = scope.prefs.liveWp
        burst = () ->
            for i in [0..2]
                pos =
                    x: random 0, body.width()
                    y: random 0, body.height()

                createRandom pos
            newRandom()

        newRandom = () ->
            if available
                pos =
                    x: random 0, body.width()
                    y: random 0, body.height()

                createRandom pos

                nextTime = random(1, 10)
                if cnt > 10
                    nextTime = 20

            if play then setTimeout newRandom, nextTime * 1000

        scope.$watch () ->
            user.animPrefs
        , (nVal) ->
            if nVal.liveWp
                play = true
                container.css
                    'opacity': 1
                burst()
            else
                play = false
                container.css
                    'opacity': 0

            if nVal.blurBg
                $('.nwfl_viewport').addClass('option-blur-on')
            else
                $('.nwfl_viewport').removeClass('option-blur-on')
        , true

        if play then newRandom()

        body
            .on 'click', (e) ->
                if e.altKey
                    createRandom
                        x: e.pageX
                        y: e.pageY
            .on 'keydown', (e) ->
                if e.altKey && (e.ctrlKey || e.metaKey) && e.which == 32 #space
                    available = !available
                    if !available
                        container.html ''
                    else
                        newRandom()

        true