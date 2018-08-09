buzzlike.directive "checkbox", () ->
    restrict: "E"
    replace: true
    transclude: true
    require: 'ngModel'
    template: (element, attrs) ->
        tmpl = attrs.template or 'default'
        tC['/inputs/checkbox/templates/'+tmpl]

    link: (scope, element, attrs, ctrl) ->
        elem = $(element)
        checked = null
        #value = attrs.value

        anim = false
        elem
        .on 'dblclick', () ->
                false

        .on 'keydown click', (e) ->
                if elem.attr('disabled') == 'disabled' or anim
                    return false
                if !(e.which == 32 or e.which == 1) #space or lmb
                    return true

                anim = true
                if attrs.options != 'confirmbox'
                    checked = !checked

                    if checked
                        elem.addClass 'checked'
                    else
                        elem.removeClass 'checked'

                    setTimeout ->
                        anim = false
                        ctrl.$setViewValue(checked)
                        scope.$apply()
                    , 333 #выполняем ng-change сразу после анимации

        ctrl.$render = () ->
            checked = ctrl.$viewValue
            if checked then elem.addClass("checked") else elem.removeClass("checked")

