buzzlike.directive "radio", () ->
    restrict: "E"
    replace: true
    scope:
        model: '=ngModel'
        value: '=ngValue'
    template: (elem, attrs) ->
        '<div class="bl-radio" tabindex="0" ng-class="{\'checked\':model == value}">
            <label>
                <input type="radio" ng-model="model" ng-value="value">
            </label>
        </div>'

buzzlike.directive "droplist", (stateManager, $compile, localization) ->
    restrict: "E"
    replace: "true"
    require: "ngModel"
    template: (elem, attrs) ->
        type = attrs.type || "single"
        if type == "single"
            return "
                <ul class='bl-droplist'>
                    <div class='list-value'></div>
                    <div class='list-position' style='display: none'>
                        <div class='list-animation' antiscroll>
                            <li ng-repeat='option in "+attrs.options+"' value='{{option.value}}'>{{option.title}}</li>
                        </div>
                    </div>
                </ul>
                "
        if type == "utc"
            return "
                <ul class='bl-droplist'>
                    <div class='list-value'></div>
                    <div class='list-position' style='display: none'>
                        <div class='list-animation' antiscroll>
                            <li ng-repeat='option in "+attrs.options+"' value='{{option.value}}'>
                                <div class='left'>{{option.utc}}</div><div class='marquee' speed='60'>&#160;{{option.title}}</marquee>
                            </li>
                        </div>
                    </div>
                </ul>
                "
    link: (scope, element, attrs, ctrl) ->
        elem = $ element
        lineH = 29 #Высота каждой линейки
        maxH = 0   #Высота видимой области
        lines = 0
        bottomOffset = 0
        container = elem.find(".list-position")
        T = 0

        dropListState =
            'escape': () ->
                container.fadeOut().removeClass("visible")
                elem.parents(".label").removeClass("selected")
                stateManager.goBack()

        elem
            .click (e) ->
                e.stopPropagation()
                container.fadeToggle().toggleClass("visible")
                elem.parents(".label").toggleClass("selected")
                if container.hasClass("visible")
                    ctrl.$render()
                    stateManager.applyState dropListState
                else
                    elem.parents(".label").removeClass("selected")
                    stateManager.goBack()

            .on "click.li", "li", ->
                ctrl.$setViewValue $(this).attr("value")
                scope.$apply()
                ctrl.$render()

        if attrs.type == "utc"
            scope.$watch ->
                localization.getLang()
            , ->
                scope.getTimezone?()
                ctrl.$render()

        ctrl.$render = () ->
            init()
            value = ctrl.$viewValue
            list = scope[attrs.options]
            for i in list
                if i.value == value
                    html = i.title
                    if attrs.type == "utc" then html = $compile("<div style='float: left; width: 100px;'>#{i.utc}</div><div class='marquee' speed='60' style='width: 220px; float: left; overflow: hidden'>#{i.title}</marquee>")(scope.$new())
                    elem.find(".list-value").html( html )

                    top = _i*lineH + 7
                    scrollTop = container.scrollTop()
                    container.css({"top": -top+"px"})
                    offset = container.offset().top
                    if offset <= 0 then top = maxH-bottomOffset
                    a1 = window.innerHeight
                    a2 = offset + container.height()
                    if a1 < a2 then top += Math.floor( (a2-a1)/lineH )*lineH + lineH
                    container.css({"top": -top+"px"})
                    container.find("li").removeClass("selected")[_i]?.classList.add("selected")
                    offset = elem.offset().top
                    offset2 = elem.find(".selected").offset()?.top
                    d = offset2 - offset
                    container.find('.scroll-box').scrollTop(scrollTop+d) if scrollTop+d

        init = ->
            list = scope[attrs.options]
            if !container.length then container = elem.find(".list-position")
            lines = Math.floor( window.innerHeight/lineH ) - 2
            bottomOffset = window.innerHeight - elem.offset().top
            bottomOffset = Math.floor(bottomOffset/lineH)*lineH
            maxH = lines*lineH
            H = list.length*lineH
            if H > maxH then H = maxH
            container.css({"max-height": H + 20, "overflow": "auto"})
            #container.find(".list-animation").css("height", container[0].scrollHeight)
            container.find(".list-animation").css("height", H)