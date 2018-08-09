buzzlike.directive 'switcher', () ->
    restrict: 'E'
    require: 'ngModel'
    replace: true
    transclude: true
    template: tC['/inputs/switcher']
    scope: {}
    link: (scope, element, attrs, ctrl) ->
        elem = $ element
        options = []
        values = []
        counter = 0

        scope.next = ->
            counter++
            if counter >= options.length then counter = 0
            options.removeClass 'active'
            $(options[counter]).addClass 'active'
            ctrl.$setViewValue values[counter]

        ctrl.$render = ->
            values.length = 0
            options = elem.find('[option]')
            options.addClass('option').each (i, el) ->
                val = el.attributes.option.value
                vals = []

                if val.indexOf('/') > -1
                    vals_tmp = val.split('/')
                else
                    vals_tmp = [val]


                for v in vals_tmp
                    if v == 'null'
                        vals.push null
                    else if v == 'undefined'
                        vals.push undefined
                    else
                        intVal = +v
                        if not isNaN intVal then v = intVal
                        vals.push v
                
                val = vals[0]
                values.push val

                if ctrl.$viewValue in vals
                    options.removeClass 'active'
                    $(el).addClass 'active'
                    counter = i
        true
