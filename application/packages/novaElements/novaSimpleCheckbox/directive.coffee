*require: '?ngModel'
*scope: true

if !ngModel then return

elem = $ element

ngModel.$render = () ->
    scope.value = !!ngModel.$viewValue
    true

elem.on 'click', (e) ->
    scope.value = !scope.value
    ngModel.$setViewValue scope.value
    scope.$apply()
