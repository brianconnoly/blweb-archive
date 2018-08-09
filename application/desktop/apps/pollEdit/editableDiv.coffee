buzzlike.directive 'editableDiv', ($sce, localization, $parse) ->
    restrict: 'C'
    require: '?ngModel'
    link: (scope, element, attrs, ngModel) ->
        
        if !ngModel then return

        # Init
        elem = element[0]
        jElem = $ elem
        elem.contentEditable = true

        # Placeholder
        if attrs.placeholderText?
            placeholder = localization.translate $parse(attrs.placeholderText)(scope)

            if $sce.getTrustedHtml(ngModel.$viewValue || '') == ''
                element.html placeholder

            scope.$watch ->
                localization.state
            , (nVal) ->
                placeholder = localization.translate $parse(attrs.placeholderText)(scope)

                if element.hasClass 'placeholder'
                    element.html placeholder
            , true

        # Ng-model settings
        ngModel.$render = () ->
            value = $sce.getTrustedHtml(ngModel.$viewValue || '')

            element.removeClass 'placeholder'
            if document.activeElement != elem and value == '' and placeholder?.length > 0
                value = placeholder
                element.addClass 'placeholder'

            element.html value

        element.on 'blur keyup change', ->
            scope.$evalAsync read

        element.on 'paste', (e) ->
            setTimeout ->
                html = elem.innerText || elem.textContent
                element.html html
                ngModel.$setViewValue html
            , 0

        element.on 'mousedown', (e) ->
            e.stopPropagation()

        element.on 'focus', (e) ->
            html = elem.innerText || elem.textContent
            if html == placeholder
                element.html ''
                element.removeClass 'placeholder'

        element.on 'blur', (e) ->
            html = elem.innerText || elem.textContent
            if html == ''
                element.html placeholder
                element.addClass 'placeholder'

        read = ->
            # html = element.html()
            html = elem.innerText || elem.textContent
            if html == placeholder
                html = ''
            ngModel.$setViewValue html

        # Disabled
        if attrs.disabled?
            scope.$watch attrs.disabled, (nVal) ->
                if nVal == true
                    elem.contentEditable = false
                else
                    elem.contentEditable = true

        # Run
        read()

        true