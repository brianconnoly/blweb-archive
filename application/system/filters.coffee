buzzlike.filter 'combcat', ($rootScope) ->
    (items, search) ->
        if !items?
            return []

        if !search
            return items

        if !search || '' == search
            return items
        #TODO - fix this - items couldn't be underfined!

        # Map array from object
        array = []
        for k,v of items
            array.push v if v != 0

        res = array.filter (element, index, array) ->
            id = false

            if search != -1
                if element.mediaplans?
                    id = search in element.mediaplans
            else
                if !element.mediaplans? or element.mediaplans.length == 0
                    id = true

            id

        $rootScope.combCatCache[search] = res.length
        res

buzzlike.filter 'groupfilter', () ->
    (items, search) ->
        if !search
            return items

        if !search || '' == search
            return items

        items.filter (element, index, array) ->
            search == element.group

buzzlike.filter 'combfilter', ($rootScope) ->
    (items, search) ->
        if $rootScope.timelineFilter.length == 0
            return items

        items.filter (element, index, array) ->
            for tl in $rootScope.timelineFilter
                if element.mediaplans? && element.mediaplans.length > 0
                    if tl.id in element.mediaplans
                        return true
                else
                    return true
            return false

buzzlike.filter 'reverse', () ->
    (items) ->
        if !items?
            return []

        if typeof items == 'object'
            items.slice().reverse()
        else
            items.reverse()

buzzlike.filter 'toHTML', () ->
    (text) ->
        text?.replace(/\n/g, '<br>')

buzzlike.filter 'dateOnly', (localization) ->
    (items, search) ->
        if !items?
            return

        D = new Date items
        if search == "DDD"  #day of week from 3 sings: Mon, Tue....
            return localization.translate(147+D.getDay())[1]
        if search == "DDDD" #whole day of week
            return localization.translate(147+D.getDay())[0]
        if search == "MMM"
            return localization.translate(154+D.getMonth())[2]
        if search == "MMMM"
            return localization.translate(154+D.getMonth())[0]
        if search == "MMMM2" #родительный падеж
            return localization.translate(154+D.getMonth())[1]
        if search == "YYYY"
            return D.getFullYear()
        if search == "YY"
            year = D.getFullYear()+''
            return year.substr(2)
        if search == "d"   #day number
            return D.getDate()
        if search == "dd"
            d = D.getDate()
            if d<10 then d = "0"+d
            return d

        if search == "HH:MM"
            h = D.getHours()
            if h < 10 then hh = "0"+h else hh = h
            m = D.getMinutes()
            if m < 10 then mm = "0"+m else mm = m
            return hh+":"+mm

        if search == "dd.mm.yyyy"
            separator = "."
            d = D.getDate()
            if d < 10 then dd = "0"+d else dd = d
            m = D.getMonth()
            if m < 10 then mm = "0"+m else mm = m
            yyyy = D.getFullYear()
            return dd + separator + mm + separator + yyyy

timestampCache = {}

buzzlike.filter 'timestampMask', (localization) ->
    (items, search) ->
        if timestampCache[items+':'+search]?
            return timestampCache[items+':'+search]

        if items? and !isNaN(items)
            DATE = new Date items
            lib = {}
            #Date: 01.01.1970
            lib.D = DATE.getDate()
            if lib.D < 10 then lib.DD = "0"+lib.D else lib.DD = lib.D

            lib.M = DATE.getMonth()+1 # хватит удалять эту единичку! Январь - 0
            if lib.M < 10 then lib.MM = "0"+lib.M else lib.MM = lib.M

            lib.MMM  = localization.translate(153+lib.M)[2] # сокращённый месяц (Янв)
            lib.MMMM = localization.translate(153+lib.M)[0] # полный месяц (Январь)
            lib.ofMMMM = localization.translate(153+lib.M)[1] #родительный падеж (Января)

            lib.YYYY = DATE.getFullYear() # год
            lib.YY = (''+lib.YYYY).substr 2

            lib.wk = DATE.getWeekNumber()

            #Time: 11:11:11, Friday
            lib.h = DATE.getHours()
            if lib.h < 10 then lib.hh = "0"+lib.h else lib.hh = lib.h

            lib.m = DATE.getMinutes()
            if lib.m < 10 then lib.mm = "0"+lib.m else lib.mm = lib.m

            lib.s = DATE.getSeconds()
            if lib.s < 10 then lib.ss = "0"+lib.s else lib.ss = lib.s

            lib.d = DATE.getDay() # день недели
            lib.ddd  = localization.translate(147+lib.d)[1] # сокращённый день недели (пт)
            lib.dddd = localization.translate(147+lib.d)[0] # полный день недели (Пятница)

            nowYEAR = new Date().getFullYear()
            if lib.YYYY != nowYEAR
                lib.optYY = "'" + lib.YY
                lib.optYYYY = lib.YYYY
            else
                lib.optYY = ''
                lib.optYYYY = ''

            str = search or localization.translate "timestampMask"
            str = str.replace /(date|time)/g, (mem) -> localization.translate "timestampMask_"+mem
            str = str.replace /(DD|D|ofMMMM|MMMM|MMM|MM|M|YYYY|YY|optYYYY|optYY|hh|h|mm|m|ss|s|dddd|ddd|d|wk)/g, (mem) -> lib[mem]

            timestampCache[items+':'+search] = str

            str

# Переводим секунды в hh:mm:ss используется при показе превью видео
buzzlike.filter 'secondsToHumanTime', () ->
    (items, search) ->
        seconds = items

        if search? and search == 'ms'
            seconds = seconds / 1000

        hours = 0
        minutes = Math.floor(seconds / 60)
        mod = seconds % 60
        result = ''

        if minutes > 59
            hours = Math.floor(minutes / 60)
            minutes = Math.floor(minutes % 60)

        if minutes < 10
            minutes = '0' + minutes
        if hours < 10
            hours = '0' + hours
        if mod < 10
            mod = '0' + mod

        if parseInt(hours) > 0
            result = hours + ':' + minutes + ':' + mod
        else
            result = minutes + ':' + mod

        if search? and search == 'ms'
            result = hours + ':' + minutes

        result

# Форматируем числа, x xxx xxx xxx по умолчанию разделитель - пробел
# В фильтре можно указать любой разделитель передав параметр - anyNumber | formatNumber:', '
buzzlike.filter 'formatNumber', () ->
    (num, separator) ->
        if !separator
            separator = " "

        if num
            bNegative = (num < 0)
            sDecimalSeparator = "."
            sOutput = num.toString()

            nDotIndex = sOutput.lastIndexOf(sDecimalSeparator)
            if nDotIndex == -1
                nDotIndex = sOutput.length

            sNewOutput = sOutput.substring(nDotIndex)
            nCount = -1

            for i in [nDotIndex..0]
                nCount++
                if ((nCount % 3 == 0) and (i != nDotIndex) and (!bNegative or (i > 1)))
                    sNewOutput = separator + sNewOutput
                sNewOutput = sOutput.charAt(i-1) + sNewOutput

            return sNewOutput
        num

buzzlike.filter 'hh', () ->
    (num, search) ->
        n = '00'
        if num
            if num.length >= 3
                num = num.replace(/0/,'')
                if $('.timeinput input:focus').caret() == 2
                    num = num.substr(0,num.length-1)

            n = Math.floor(num)
            if n > 23
                n = 23
            else if n <= 0
                n = 0
            if n < 10
                n = '0'+n
        n

buzzlike.filter 'mm', () ->
    (num, mod) ->
        n = '00'
        if num
            if num.length >= 3
                num = num.replace(/0/,'')
                if $('.timeinput input:focus').caret() == 2
                    num = num.substr(0,num.length-1)

            n = Math.floor(num)
            if n > 59
                n = 59
            else if n <= 0
                n = 0
            if n < 10
                n = '0'+n
        n

buzzlike.filter 'startFrom', () ->
    (input, start) ->
        start = +start
        input.slice(start)

buzzlike.filter 'shortInt', () ->
    (int, mod) ->
        chars =
            1000000000: 'M'
            1000000: 'm'
            1000: 'k'

        for k, v of chars
            if int > k
                res = Math.floor int/k
                return res+v
        int



###
buzzlike.filter 'categoriesFilter', (lotService) ->
    (item, type) ->
        newList = []
        for i in item
            if i.categoryIds? and i.categoryIds[0]? and i.categoryIds.length > 0
                if lotService.categoriesList[i.categoryIds[0]]? and lotService.categoriesList[i.categoryIds[0]].key == type
                    newList.push i
        newList
###
