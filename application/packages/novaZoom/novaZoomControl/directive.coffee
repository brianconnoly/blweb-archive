*deps: novaZoom
*require: '?ngModel'

scope.value = ngModel.$viewValue

elem = $ element
# elem.ColorPicker
#     onSubmit: (hsb, hex, rgb, el) ->
#         ngModel.$setViewValue rgb
#         scope.value = rgb
#         elem.ColorPickerHide()

ngModel.$render = () ->
    if ngModel.$viewValue?
        scope.value = ngModel.$viewValue
        novaZoom.setValue scope.value

scope.$on '$destroy', ->
    novaZoom.hide()

scope.showPicker = (e) ->
    e.stopPropagation()

    novaZoom.pick
        current: scope.value
        onChange: (nVal) ->
            ngModel.$setViewValue nVal
            scope.value = nVal

    true

