buzzlike.directive "marquee", () ->
    restrict: "AC"
    transclude: true
    template: '<div class="scrollContainer"><div class="scrolling" ng-transclude></div></div>'
    link: (scope, element, attrs) ->
        T = 0
        elem = $ element


        elem
            .on "mouseenter", ".scrolling", ->
                temp = this
                T = setTimeout ->
                    $(temp).addClass "scrolling-left"
                    if attrs.speed  #px per sec
                        time = 1/(attrs.speed / elem.find(".scrolling").width())
                        $(temp).css("animation-duration", time+"s") #"scrolling-left linear "+time+"s 1s infinite")
                , 600
            .on "mouseleave", ".scrolling", ->
                clearTimeout T
                $(this).removeClass "scrolling-left"