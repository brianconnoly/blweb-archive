buzzlike.directive 'timePicker', (smartDate) ->
    restrict: 'EAC'
    template: tC['/elements/timePicker']
    require: '?ngModel'
    scope:
        model: '=ngModel'
    link: (scope, element, attrs, ngModel) ->
        elem = $ element
        min_inp = elem.children '.minutes'
        hour_inp = elem.children '.hours'

        if attrs.min?
            min_value = attrs.min * 1
        else
            min_value = 0

        changeOnce = attrs.changeonce

        typing =
            min_val: ''
            min_time: 0

            hour_val: ''
            hour_time: 0

        scope.hours = '00'
        scope.minutes = '00'

        ngModel.$render = () ->
            if attrs.options == 'inspectorInterval' || attrs.options == 'cleartime'
                time = ngModel.$viewValue

                if attrs.options == 'inspectorInterval'
                    convertedTime = convertTimeToHumanTime(time,'min').split(':')
                else
                    convertedTime = convertTimeToHumanTime(time,'ms').split(':')

                scope.hours = convertedTime[0]*1
                scope.minutes = convertedTime[1]*1
            else
                d = new Date smartDate.getShiftTimeBar(ngModel.$viewValue)

                scope.hours = d.getHours()
                scope.minutes = d.getMinutes()

            if scope.hours < 10
                scope.hours = '0' + scope.hours

            if scope.minutes < 10
                scope.minutes = '0' + scope.minutes

        setModelTime = () ->
            if attrs.options == 'inspectorInterval'
                minutes = (Math.floor( scope.hours ) * 60) + Math.floor(scope.minutes)
                if minutes <= min_value
                    minutes = min_value
                    scope.minutes = '0' + min_value
                ngModel.$setViewValue minutes
            else if attrs.options == 'cleartime'
                minutes = (Math.floor( scope.hours ) * 60 * 60 * 1000) + Math.floor(scope.minutes) * 60 * 1000
                ngModel.$setViewValue minutes
            else
                d = new Date smartDate.getShiftTimeBar(ngModel.$viewValue)
                dnewD = new Date d.getFullYear(), d.getMonth(), d.getDate(), scope.hours, scope.minutes

                # d.setHours(0,0,0,0)
                # res = (scope.hours*60*60*1000) + (scope.minutes*60*1000)
                # res = d.getTime() + res
                ngModel.$setViewValue smartDate.resetShiftTimeBar( dnewD.getTime() )

        switchInputFocus = (e) ->
            # left key
            if (e.keyCode == 37 or e.keyCode == 9) and $(e.target).hasClass('minutes')
                $(element).children('input').first().focus()

            # right key
            if (e.keyCode == 39 or e.keyCode == 9) and $(e.target).hasClass('hours')
                $(element).children('input').last().focus()

        scope.minutes_keys = (e) ->
            e.preventDefault()
            e.stopPropagation()
            min = parseInt scope.minutes
            hour = parseInt scope.hours

            switchInputFocus(e)

            if e.keyCode == 38
                if e.shiftKey
                    min += 1
                else
                    min += 5

                if min >= 60
                    min -= 60
                    hour++

                    if hour >= 24
                        hour = 0

            if e.keyCode == 40
                if e.shiftKey
                    min -= 1
                else
                    min -= 5

                if min < 0
                    min += 60
                    hour--

                    if hour < 0
                        hour = 23

            if (e.keyCode*1 >= 48 and e.keyCode*1 <= 57) or (e.keyCode*1 >= 96 and e.keyCode*1 <= 105)
                # numbers
                now = new Date().getTime()
                diff = now - typing.min_time
                typing.min_time = now

                if diff > 1 * SEC
                    typing.min_val = ''

                if typing.min_val.length >= 2
                    typing.min_val = ''

                if e.keyCode >= 96
                    typing.min_val += (e.keyCode - 96)
                else
                    typing.min_val += (e.keyCode - 48)

                # determine value to display
                display_value = typing.min_val *1

                if display_value < min_value
                    display_value = min_value

                if display_value >= 60
                    display_value = 59

                min = display_value

            if e.keyCode == 8
                min = 0
                typing.min_val = ''
                typing.min_time = 0

            if !e.shiftKey and (e.keyCode == 38 or e.keyCode == 40)
                min /= 5
                min = Math.round min
                min *= 5

            if hour < 10
                hour = '0' + hour

            if min < 10
                min = '0' + min

            scope.minutes = min
            scope.hours = hour

            if e.keyCode == 13
                setModelTime()

            if changeOnce
                return

            setModelTime()

        scope.hour_keys = (e) ->
            e.preventDefault()
            e.stopPropagation()
            min = parseInt scope.minutes
            hour = parseInt scope.hours

            switchInputFocus(e)

            if e.keyCode == 38
                hour += 1

                if hour >= 24
                    hour = 0

            if e.keyCode == 40
                hour -= 1

                if hour < 0
                    hour = 23

            if (e.keyCode*1 >= 48 and e.keyCode*1 <= 57) or (e.keyCode*1 >= 96 and e.keyCode*1 <= 105)
                # numbers
                now = new Date().getTime()
                diff = now - typing.hour_time
                typing.hour_time = now

                if diff > 1 * SEC
                    typing.hour_val = ''

                if typing.hour_val.length >= 2
                    typing.hour_val = ''

                if e.keyCode >= 96
                    typing.hour_val += (e.keyCode - 96)
                else
                    typing.hour_val += (e.keyCode - 48)

                # determine value to display
                display_value = typing.hour_val * 1
                if display_value < 0 then display_value = 0
                if display_value == 24
                    display_value = 0
                else
                    if display_value > 23 then display_value = 23

                hour = display_value

            if e.keyCode == 8
                hour = 0
                typing.hour_val = ''
                typing.hour_time = 0

            if hour < 10
                hour = '0' + hour

            if min < 10
                min = '0' + min

            scope.minutes = min
            scope.hours = hour

            if e.keyCode == 13
                setModelTime()

            if changeOnce
                return
                
            setModelTime()
