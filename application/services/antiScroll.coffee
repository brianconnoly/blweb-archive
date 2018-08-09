buzzlike.directive "antiscroll", (antiscroll) ->
    replace: true
    transclude: true
    template: (element, attrs) ->
        size = antiscroll.getSize()

        window.os = (/(win|mac|linux|sunos|solaris)/.exec(navigator.platform.toLowerCase()) || [""])[0]

        if os && size>0
            window.antiscrollOn = true
            elem = $ element

            pos = elem.css("position")
            R = elem.css("right")
            scrollTop = attrs.scrollTop
            scrollTop = if scrollTop then "scroll-top='#{scrollTop}'" else ""

            return "
                <div class='antiscroll'>
                    <div class='scroll-box' #{scrollTop}><div ng-transclude class='size'></div></div>
                    <div class='scrollbar-bottom'><div class='scroll-bottom animate'></div></div>
                    <div class='scrollbar-right'><div class='scroll-right animate'></div></div>

                </div>
            "
        else
            window.antiscrollOn = false
            return '<div class="no-antiscroll" ng-transclude></div>'


    link: (scope, element, attrs) ->
        size = antiscroll.getSize()
        if !window.os || !size then return true
        elem = $ element
        w = h = W = H = kw = kh = 0
        scrollableY = false
        scrollableX = false

        #blog elem, elem[0].style
        setTimeout ->
            padding = elem.css("padding") || elem.css("padding-top")+" "+elem.css("padding-right")+" "+elem.css("padding-bottom")+" "+elem.css("padding-left")
            elem.find(".scroll-box").css("padding", padding)
        , 0

        setVEvents = (e, scroller) ->
            pos = e.pageY
            top = scroller.css("top")
            scroller.removeClass("animate")
            max = h - scroller.height()
            if top.indexOf("%")+1 then top = h*(parseInt(top))/100 else top = parseInt(top)
            $(document)
                .on "mousemove.scroll", (e) ->
                    dy = e.pageY-pos
                    y = top + dy
                    if y < 0 then y = 0 else
                        if y > max then y = max
                    Y = y/kh
                    scroller.css({"top": y.toFixed(3)+"px"})
                    elem.find(".scroll-box").scrollTop(Y)
                .on "mouseup.scroll", () ->
                    $(document).off(".scroll")
                    scroller.addClass("animate")

        setHEvents = (e, scroller) ->
            pos = e.pageX
            left = scroller.css("left")
            scroller.removeClass("animate")
            max = w - scroller.width()
            if left.indexOf("%")+1 then left = w*(Math.floor(left))/100 else left = Math.floor(left)
            $(document)
                .on "mousemove.scroll", (e) ->
                    dx = e.pageX-pos
                    x = left + dx
                    if x < 0 then x = 0 else
                        if x > max then x = max
                    X = x/kw
                    scroller.css({"left": x.toFixed(3)+"px"})
                    elem.find(".scroll-box").scrollLeft(X)
                .on "mouseup.scroll", () ->
                    $(document).off(".scroll")
                    scroller.addClass("animate")

        elem
            .on "mouseenter", (e) ->
                w = elem[0].clientWidth
                h = elem[0].clientHeight
                W = elem.find(".scroll-box")[0].scrollWidth
                H = elem.find(".scroll-box")[0].scrollHeight
                if elem[0].getBoundingClientRect().top == 0
                    elem.find(".scrollbar-right").css("top", $("#nav").height() + "px")
                    h -= 42
                    H -= 42
                kw = w/W
                kh = h/H
                if w<W-1
                    scrollableX = true
                    elem.find(".scrollbar-bottom").css("display", "block")
                    elem.find(".scroll-bottom").css("width", Math.floor(100*w/W)+"%")
                else scrollableX = false
                if h<H-1
                    scrollableY = true
                    elem.find(".scrollbar-right").css("display", "block")
                    elem.find(".scroll-right").css("height", 100*h/H+"%")
                else scrollableY = false
                elem.addClass("show") if e.which != 1
                elem.addClass "hover"

            .on "mouseleave", (e) ->
                if e.which != 1
                    elem.removeClass "show"
                    elem.find(".scrollbar-bottom, .scrollbar-right").css("display", "")
                elem.removeClass "hover"

            .find(".scroll-box").on "scroll", (e) ->
                if scrollableY
                    y = elem.find(".scroll-box").scrollTop()
                    y = 100*y/H
                    elem.find(".scroll-right").css("top", y.toFixed(3)+"%")
                if scrollableX
                    x = elem.find(".scroll-box").scrollLeft()
                    x = 100*x/W
                    elem.find(".scroll-bottom").css("left", x.toFixed(3)+"%")

            .on "mousewheel", (e, d, dx, dy) ->
                if scrollableX and !scrollableY
                    dy *= -100 if Math.abs(dy) < 9
                    box = elem.find(".scroll-box")
                    x = box.scrollLeft()
                    x += dy
                    x = box.scrollLeft(x)
                    x = 100*x/W
                    elem.find(".scroll-bottom").css("left", x.toFixed(3)+"%")

        elem.find(".scroll-right").on "mousedown", (e) ->
            setVEvents(e, $(this))

        elem.find(".scroll-bottom").on "mousedown", (e) ->
            setHEvents(e, $(this))

        true

buzzlike.factory "antiscroll", () ->
    size = undefined
    getSize : () ->
        if size == undefined
            div = $(
                '<div class="antiscroll-inner" style="width:50px;height:50px;overflow-y:scroll;position:absolute;top:-200px;left:-200px;">
                                    <div style="height:100px;width:100%">
                                </div>'
            )
            $('body').append(div)
            w1 = $(div).innerWidth()
            w2 = $('div', div).innerWidth()
            $(div).remove()

            window.scrollbarWidth = size = w1 - w2
            if size>0
                for i in document.styleSheets
                    if i.href?.indexOf("main.css")+1
                        num = i?.rules?.length || i?.cssRules?.length || 10000
                        i.insertRule?(".antiscroll .scroll-box{right: -"+size+"px !important; bottom: -"+size+"px !important;}", num)
            else size = 0
        return size