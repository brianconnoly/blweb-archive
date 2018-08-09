# Deprecated ----------------
# timePicker is new directive
buzzlike.directive "timeinput", ($filter, stateManager, ruleService, $rootScope, inspectorService) ->
    restrict: "C"
    scope: true
    template: templateCache['/elements/timeinput']
    link: (scope, element, attrs) ->

        scope.sched = null
        scope.rule = null

        hourStep = 1
        if attrs.minstep
            minStep = Math.floor(attrs.minstep)
        else
            minStep = 1

        scope.$watch () ->
            inspectorService.status.currentRule
        , (nValue) ->
            if nValue?
                scope.sched = nValue
                scope.rule = scope.sched.rule
                init()
                inspectorService.appendHandlers()
        , true

        init = ->
            if $(element).hasClass('startTime')
                time = getHumanDate( scope.rule.timestampStart )
            else if $(element).hasClass('endTime')
                time = getHumanDate( scope.rule.timestampEnd )
            else if $(element).hasClass('timeinputinterval')
                time = scope.rule.interval
                convertedTime = convertTimeToHumanTime(time,'min').split(':')
                time = { hours: convertedTime[0], min: convertedTime[1] }

            timeHour = time.hours
            timeMin = time.min

            scope.hour = timeHour
            scope.min = timeMin

            setMinMinutesStep(true)

        placeholderEdit = (step) ->
            rules = ruleService.rules[scope.rule.communityId]
            for item in rules
                if item.id == scope.rule.id

                    dayStart = new Date( item.timestampStart )
                    dayStart.setHours(0,0,0,0)

                    dayEnd = new Date( item.timestampEnd )
                    dayEnd.setHours(0,0,0,0)

                    if $(element).hasClass('startTime')
                        if item.timestampStart?
                            item.timestampStart = dayStart.getTime() + step
                    else if $(element).hasClass('endTime')
                        if item.timestampEnd?
                            item.timestampEnd = dayEnd.getTime() + step

                    if $(element).hasClass('timeinputinterval')
                        item.interval = (Math.floor( scope.hour ) * 60) + Math.floor(scope.min)

        scope.toSlider = ->
            if $(element).hasClass('timeinputinterval')
                min = (Math.floor( scope.hour ) * 60) + Math.floor(scope.min)
                setTimeout ->
                    if $('.slider .ui-slider-handle').length > 0
                        $('.slider').slider 'value', min
                , 10
            null

        scope.formatHour = () ->
            scope.hour = $filter('hh')(scope.hour)
            scope.min = $filter('mm')(scope.min)

            scope.toSlider()

        setMinMinutesStep = (firstTime) ->

            if $(element).hasClass('timeinputinterval')
                if minStep == 5
                    scope.min = Math.floor scope.min

                    res = scope.min % minStep
                    if res != 0 and res >= 3
                        scope.min += (minStep-res)
                    else
                        scope.min -= res

                    if scope.min == 60
                        scope.min = 0

                        scope.hour = Math.floor(scope.hour) + 1

                    if Math.floor(scope.hour) == 0 and scope.min < 3
                        scope.min = 5
            else
                if minStep == 5
                    scope.min = Math.floor scope.min

                    res = scope.min % minStep
                    if res != 0 and res >= 3
                        scope.min += (minStep-res)
                    else
                        scope.min -= res

                    if scope.min == 60 and scope.hour < 23
                        scope.min = 0
                        scope.hour = Math.floor(scope.hour) + 1

                    if scope.min > 55 and scope.hour == 23
                        scope.min = 55

            scope.formatHour()
            time = convertTimeToNix(scope.hour, scope.min)
            placeholderEdit(time)
            if !firstTime
                scope.$apply()

        upTime = ->
            if $('.timeinput input:focus').length > 0
                ngModel = $('.timeinput input:focus').attr('ng-model')

                if ngModel == 'min'
                    scope[ngModel] = Math.floor(scope[ngModel]) + minStep
                else
                    scope[ngModel] = Math.floor(scope[ngModel]) + hourStep

                if ngModel == 'min'
                    ngModelHour = 'hour'
                    if scope[ngModel] > 59 and scope[ngModelHour] < 23
                        scope[ngModel] = 0
                        scope[ngModelHour] = Math.floor(scope[ngModelHour]) + hourStep

                setMinMinutesStep()

        downTime = ->
            if $('.timeinput input:focus').length > 0
                ngModel = $('.timeinput input:focus').attr('ng-model')

                if ngModel == 'min'
                    scope[ngModel] = Math.floor(scope[ngModel]) - minStep
                else
                    scope[ngModel] = Math.floor(scope[ngModel]) - hourStep

                if ngModel == 'min'
                    ngModelHour = 'hour'
                    if scope[ngModel] < 0 and scope[ngModelHour] > 0
                        if minStep == 5
                            scope[ngModel] = 55
                        else
                            scope[ngModel] = 59
                        scope[ngModelHour] = Math.floor(scope[ngModelHour]) - hourStep

                setMinMinutesStep()

        leftInput = (obj) ->
            if $('.timeinput input:focus').length > 0

                if obj.caret() == 0
                    par = $('.timeinput input:focus').parent()
                    par.children('input').first().focus()

        rightInput = (obj) ->
            if $('.timeinput input:focus').length > 0

                if obj.caret() == 2
                    par = $('.timeinput input:focus').parent()
                    par.children('input').last().focus()

        $(element).on 'keyup', 'input', (e) ->
            setMinMinutesStep()

        $(element).on 'keydown', 'input', (e) ->
            if e.keyCode == 37
                leftInput $(this)
            if e.keyCode == 39
                rightInput $(this)
            if e.keyCode == 38
                upTime $(this)
            if e.keyCode == 40
                downTime $(this)

        true