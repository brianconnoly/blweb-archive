buzzlike.directive "mediaSearch", () ->     # go fuck yourself
    restrict: 'A',
    require: '?ngModel',
    link: (scope, element, attrs, ngModel) ->

        placeholderRemoved = false
        if !ngModel
            return false

        ngModel.$render = ->
            if attrs.placeholder
                placeholderText = ''
                if ngModel.$viewValue == '' and attrs.placeholder != ''
                    placeholderText = '<span class="placeholder">'+attrs.placeholder+'</span>'

                element.html ngModel.$viewValue || placeholderText

        element.on 'blur keyup', ->
            readViewText()

        element.on 'keydown', ->
            if placeholderRemoved == false
                placeholderRemoved = true
                element.html('')

        element.on 'click', ->
            if element.text() == attrs.placeholder
                $(element).caret(0)

        readViewText = ->
            html = element.html()

            placeholderText = ''
            if html == '' and attrs.placeholder != ''
                placeholderRemoved = false
                placeholderText = '<span class="placeholder">'+attrs.placeholder+'</span>'

                safari = false
                if /Safari/gi.test(navigator.userAgent) and !/Chrome/gi.test(navigator.userAgent)
                    safari = true

                if !safari
                    element.html(placeholderText)

                $(element).caret(0)

            if html != attrs.placeholder
                ngModel.$setViewValue html