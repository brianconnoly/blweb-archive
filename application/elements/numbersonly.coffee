buzzlike.directive "numbersonly", () ->
    restrict: "A"
    require: "ngModel"
    link: (scope, element, attrs, modelCtrl) ->
        modelCtrl.$parsers.push (inputValue) ->

            if !inputValue?
                return ''

            transformedInput = inputValue.replace(/[^0-9]/g, '')

            if transformedInput != inputValue
                modelCtrl.$setViewValue(transformedInput)
                modelCtrl.$render()

            transformedInput