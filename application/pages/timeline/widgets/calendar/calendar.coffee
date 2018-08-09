buzzlike
    .directive 'datePicker', (stateManager, smartDate, desktopService) ->
        restrict: 'EAC'
        require: '?ngModel'
        link: (scope, elem, attrs, ngModel) ->

            if !ngModel.$viewValue?
                ngModel.$setViewValue Date.now()
                # scope.$apply()

            scope.date = ngModel.$viewValue # new Date().getTime()

            calendarSession = null

            setElemDate = (result) ->
                scope.date = result
                #elem.html result.getDate() + '.' + (result.getMonth() * 1 + 1) + '.' + result.getFullYear()
                true

            scope.$on '$destroy', () ->
                if calendarSession?
                    calendarSession.scope.closeApp()

            elem.on 'click', (e,param) ->
                # get current date
                d = new Date smartDate.getShiftTimeBar(ngModel.$viewValue)

                if !calendarSession?.session?
                    if attrs.options == 'inspector'
                        calendarEdge = scope.$eval(attrs.edgetime)
                        pos =
                            top: $(elem).offset().top
                            left: $(elem).offset().left
                    else
                        if attrs.options == 'rightSide'
                            calendarEdge = 0
                            pos =
                                top: $(elem).offset().top
                                left: $('body').width() - 265
                        else
                            calendarEdge = 0
                            pos =
                                top: $(elem).offset().top
                                left: 0

                    calendarSession = desktopService.launchApp 'calendar',
                        cursor: d
                        calendarEdge: calendarEdge or null
                        coords:
                            x: e.clientX #pos.left
                            y: e.clientY #pos.top
                        api: 
                            pick: (result) =>
                                if result.hide
                                    return true

                                newVal = result

                                if attrs.dateonly?
                                    d = new Date smartDate.getShiftTimeBar(ngModel.$viewValue)
                                    newVal = new Date result.getFullYear(), result.getMonth(), result.getDate(), d.getHours(), d.getMinutes()

                                setElemDate newVal.getTime()
                                ngModel.$setViewValue smartDate.resetShiftTimeBar( newVal.getTime() ) # newVal.getTime() #

                                scope.$eval attrs.jump
                    , e, true

                else
                    calendarSession.scope.closeApp()

                if $(e.target).hasClass 'noDigest'
                    return 
                    
                scope.$apply()

            ngModel.$render = () ->
                if !ngModel.$viewValue?
                    ngModel.$setViewValue Date.now()
                
                d = new Date smartDate.getShiftTimeBar(ngModel.$viewValue)

                if calendarSession?.cursor?
                    calendarSession.cursor = d
                setElemDate d.getTime()


            true