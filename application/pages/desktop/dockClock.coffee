buzzlike.directive 'dockClock', (localization) ->
    restrict: 'C'
    link: (scope, element, attrs) ->

        dateObj = new Date()
        vals = 
            day: dateObj.getDay()
            date: dateObj.getDate()
            month: dateObj.getMonth()
            year: dateObj.getYear()

        mode = 1

        updateTime = ->
            obj = new Date()
            hh = obj.getHours()
            mm = obj.getMinutes()
            ss = obj.getSeconds()

            if hh < 10 then hh = '0' + hh
            if mm < 10 then mm = '0' + mm
            if ss < 10 then ss = '0' + ss

            if mode == 0
                element.html vals.base + hh + ':' + mm + ':' + ss
            else
                element.html vals.base + hh + ':' + mm


        element.on 'dblclick', (e) ->
            if mode == 0
                clearInterval handler
                handler = setInterval updateTime, MIN
                mode = 1
            else
                clearInterval handler
                handler = setInterval updateTime, SEC
                mode = 0
            updateTime()

        localization.onLangLoaded ->
            
            vals.day = localization.translate(147 + vals.day)[1]
            vals.mon = localization.translate(154 + vals.month)[2]

            # vals.day[0] = vals.day[0].toUpperCase()
            vals.base = vals.day[0].toUpperCase() + vals.day[1] + ', ' + vals.date + ' ' + vals.mon.toLowerCase() + '. '

            handler = setInterval updateTime, MIN
            updateTime()