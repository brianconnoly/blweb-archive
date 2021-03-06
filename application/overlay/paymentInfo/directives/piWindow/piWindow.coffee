buzzlike.directive "piWindow", () ->
    restrict: "C"
    link: (scope, element, attrs) ->
        elem = $ element
        ###
        scope.resizepiWindow = ->
            outerH = window.innerHeight - 120
            innerH = elem.height() - elem.find('.head').height() - elem.find(".directPanel").height()

            elem.css
                height: outerH

            $(element).find('.scrollLayer, iframe').css
                height: innerH

        $(window).off '.pi'
        $(window).on 'resize.pi', scope.resizepiWindow
        setTimeout scope.resizepiWindow, 0
        ###
        true