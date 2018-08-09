buzzlike.directive "onInput", () ->
    restrict: "A"
    scope:
        onInput: '='
        settings: '='
    link: (scope, element, attrs) ->
        elem = $ element

        defaultSettings =
            timeout: 1000
            blurOnEnter: false

        settings = updateObject defaultSettings, scope.settings

        T = null
        elem.on 'keydown', (e) ->
            if T
                clearTimeout T
                T = null
            T = setTimeout scope.onInput, settings.timeout

            if e.which == keyCodes.enter
                if settings.blurOnEnter then elem[0].blur()




