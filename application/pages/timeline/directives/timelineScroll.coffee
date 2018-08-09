buzzlike
    .directive 'timelineScroll', () ->
        restrict: 'C'
        template: '<div class="scroller"></div><div class="current-time tl_eveningtime tl_nowbutton" translate="\'go_now\'"></div>'
        replace: false
        link: (scope, element, attrs) ->
            element = $(element)
            handler = $("div.timeline")
            scrollerWidth = 0
            intervalId = null
            scrollSpeed = 0
            scope.inProcess = false

            setEvents = (elem) ->
                scope.inProcess = true
                handler
                    .on 'mousemove', (e) ->
                        e = fixEvent(e)
                        setGradient(e, elem)
                    .on('mouseup', removeEvents)
                    .on('dragstart selectstart', () -> false)

            removeEvents = () ->
                handler.off 'mousemove mouseup dragstart selectstart'
                scope.inProcess = false
                scrollSpeed = 0
                clearInterval intervalId
                intervalId = null

            scrollFunction = () ->
                if scrollSpeed != 0
                    scope.doScroll(scrollSpeed/5)

            initSpeed = (e) ->
                scrollerWidth = element.width()
                scrollerCenterX = element.offset().left + scrollerWidth/2
                dx = e.pageX - scrollerCenterX
                if dx < 30 and dx > -30 then dx = 0
                if dx > scrollerWidth/2 then dx = scrollerWidth/2
                if dx < -scrollerWidth/2 then dx = -scrollerWidth/2
                dx

            setGradient = (e, elem) ->
                scrollSpeed = initSpeed(e)
                w2 = scrollerWidth/2
                x = scrollSpeed
                h = -(125/(w2*w2))*x*x+120
                s = '100%'
                l = '70%'
                angle = 'left'
                webkitAngle = '0deg'
                startColor = "hsla("+h+","+s+", "+l+", 0) 0%"
                endColor = "hsla("+h+","+s+", "+l+", 1) 100%"
                params = {
                    'width': Math.abs(scrollSpeed)
                    'marginLeft': ''
                }
                if scrollSpeed < 0
                    params.marginLeft = scrollSpeed
                    angle = '-90deg'
                    webkitAngle = '180deg'
                $(elem).children('.scroller')
                    .css('background-image', '-webkit-linear-gradient('+webkitAngle+', '+startColor+', '+endColor+')')
                    .css('background-image', '-moz-linear-gradient('+angle+', '+startColor+', '+endColor+')')
                    .css('background-image', '-o-linear-gradient('+angle+', '+startColor+', '+endColor+')')
                    .css('background-image', '-ms-linear-gradient('+angle+', '+startColor+', '+endColor+')')
                    .css('filter', 'progid:DXImageTransform.Microsoft.gradient(startColorstr='+startColor+',endColorstr='+endColor+',GradientType=0)')
                    .css('background-image', 'linear-gradient('+angle+', '+startColor+', '+endColor+')')
                    .css params

            $(element)
                .bind 'mousemove', (e) ->
                    e = fixEvent(e)
                    setGradient(e, this)
                .bind 'mousedown', (e) ->
                    if scope.inProcess then return removeEvents()
                    setEvents(this)
                    setGradient e, this
                    intervalId = setInterval () ->
                        scrollFunction()
                    , 20
                # .bind 'mouseup', (e) ->
                #     removeEvents()
                .parent().parent().bind 'click', () ->
                    if scope.inProcess then return removeEvents()
                .find(".current-time").click (e) ->

                    e.stopPropagation()

                    scope.scrollTo(null, isCmd e)
                    # tutorialService.nextLesson('timelinepage', [5])
