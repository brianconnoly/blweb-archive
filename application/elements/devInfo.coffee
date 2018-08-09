buzzlike.directive "devInfo", (account) ->
    restrict: "A"
    link: (scope, element, attrs) ->
        user = account.user
        elem = $ element

        if !DEV_MODE
            setTimeout ->
                elem.removeAttr 'dev-info'
            , 0
            return false

        devInspector = $ "#devInspector"
        if !devInspector.length
            devInspector = $('<div id="devInspector">').html("dev info here")
            devInspector.appendTo "body"

        elem.on 'mouseenter.dev', ->
            info = attrs.devInfo
            devInspector.html info.replace(/,/g, "<br>")
