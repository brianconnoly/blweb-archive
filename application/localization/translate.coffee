buzzlike.directive 'translate', (localization, $parse) ->
    restrict: 'A'
    scope:
        translate: '=?'
        vars: '=?'
    link: (scope, element, attrs) ->

        refresh = ->
            code = ''
            if scope.translate?
                code += scope.translate

            if code?.length > 0
                result = localization.translate code, scope.vars
                if !DEV_MODE and result == code
                    result = '...'
                else
                    if attrs.index?
                        result = result[attrs.index]

                if attrs.translateCapitalize == 'true'
                    result = result.capitalizeFirstLetter()

                element.empty()
                element.html result

            if attrs.translateTitle?.length > 0
                code = $parse(attrs.translateTitle)(scope)
                result = localization.translate code, scope.vars
                if !DEV_MODE and result == code
                    result = '...'

                element.attr 'title', result

            if attrs.translatePlaceholder?.length > 0
                code = $parse(attrs.translatePlaceholder)(scope)
                result = localization.translate code, scope.vars
                if !DEV_MODE and result == code
                    result = '...'

                element.attr 'placeholder', result

        scope.state = localization.state
        scope.$watch 'state', (nVal) ->
            refresh()
            # console.log 'localization state updated!', nVal, localization.getList()
        , true

        scope.$watch 'translate', ->
            refresh()

        scope.$watch 'vars', ->
            refresh()
        , true

        refresh()

        scope.refresh = refresh

        true
