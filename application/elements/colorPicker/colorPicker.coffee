buzzlike.directive 'colorPicker', () ->
    restrict: 'E'
    scope: true
    require: '?ngModel'
    template: tC['/elements/colorPicker']
    replace: true
    link: (scope, element, attrs, ngModel) ->

        scope.value = ngModel.$viewValue

        elem = $ element
        elem.ColorPicker
            onSubmit: (hsb, hex, rgb, el) ->
                ngModel.$setViewValue rgb
                scope.value = rgb
                elem.ColorPickerHide()

        ngModel.$render = () ->
            if ngModel.$viewValue?
                scope.value = ngModel.$viewValue
                elem.ColorPickerSetColor ngModel.$viewValue

        scope.$on '$destroy', ->
            elem.ColorPickerDestroy()

        scope.getColor = ->
            "rgb(#{scope.value.r},#{scope.value.g},#{scope.value.b})"
        true