*deps: $compile, operationsService, $parse
*replace: true
*require: '?ngModel'
*scope: true

    if !ngModel then return
    scope.phrase = attrs.phrase

    if attrs.customValue?
        unreg = scope.$watch attrs.customValue, (nVal) ->
            scope.customValue = nVal #$parse(attrs.customValue)(scope)
            unreg()

    elem = $ element
    rootScreen = $ elem.parents('.novaScreen')[0]
    container = rootScreen.parent()
    newScreen = null

    scope.backScreen = ->
        if newScreen?
            newScreen.addClass 'hideRight'
            rootScreen.removeClass 'hideLeft'

            setTimeout ->
                newScreen.remove()
                newScreen = null
            , 200

    scope.setNewValue = (value) ->
        ngModel.$setViewValue value
        scope.value = operationsService.get attrs.itemType, ngModel.$viewValue
        elem.removeClass 'placeholder'
        scope.backScreen()

    ngModel.$render = () ->
        if ngModel.$viewValue?
            elem.removeClass 'placeholder'
            scope.value = operationsService.get attrs.itemType, ngModel.$viewValue
        else
            elem.addClass 'placeholder'
            scope.value = null

    scope.pickValue = ->
        newScreen = $ '<div>',
            class: 'novaScreen hideRight novaScreenPicker' + attrs.itemType.capitalizeFirstLetter()
        newScreen = $ $compile(newScreen)(scope)
        container.append newScreen

        setTimeout ->
            rootScreen.addClass 'hideLeft'
            newScreen.removeClass 'hideRight'
        , 100

        true
