#CONST
SEC = 1000
MIN = 60 * SEC
HOUR = MIN * 60
DAY = HOUR * 24
WEEK = DAY * 7
MONTH = DAY * 30
YEAR = 365 * DAY

rightPanelWidth = 200
leftPanelWidth = 250

proxyPrefix = '' # 'https://proxy.buzzlike.pro/?url='

String::capitalizeFirstLetter = () -> this.charAt(0).toUpperCase() + this.slice(1)

Array::move = (old_index, new_index) ->
    if new_index >= this.length
        k = new_index - this.length

        while (k--) + 1
            this.push undefined

    @splice new_index, 0, @splice(old_index, 1)[0]
    return this

Date::getWeekNumber = () ->
    d = new Date +@
    d.setHours 0, 0, 0
    d.setDate d.getDate() + 4 - ( d.getDay() || 7 )
    Math.ceil (((d-new Date(d.getFullYear(),0,1)) / 8.64e7) + 1) / 7

quoteIfExists = (str) ->
    if str.length > 0
        return '"' + str + '"'
    else
        return ""

openCommunityPage = (item) ->

    url = ""
    switch item.socialNetwork
        when 'vk'
            url = 'https://vk.com/'

            switch item.communityType
                when 'profile'
                    url += 'id'
                when 'group', 'page'
                    url += 'club'
                when 'event'
                    url += 'event'

            url += Math.abs item.socialNetworkId*1

        when 'fb'
            url = 'https://facebook.com/'

            if item.communityType == 'user'
                url += 'profile.php?id='

            url += Math.abs item.socialNetworkId*1

        when 'ok'
            url = 'http://ok.ru/'

            if item.communityType == 'profile'
                url += 'profile/'
            else
                url += 'group/'

            url += item.socialNetworkId

        when 'yt'
            url = 'http://youtube.com/channel/' + item.socialNetworkId

        when 'mm'
            url = 'http://my.mail.ru/'

            switch item.communityType
                when 'profile'
                    url += 'mail/'
                else
                    url += 'community/'

            url += item.screen_name

    if url.length > 0
        window.open(url,'_blank')

# delete objetct and properties
emptyObject = (obj) ->
    for own key of obj
        delete obj[key]

# get humand-date, format - { getTime: XX:XX, hour: X, min: X }
____datetmp = null
getHumanDate = (unixtime) ->
    if unixtime?
        ____datetmp = new Date unixtime
    else
        ____datetmp = new Date()

    hours = ____datetmp.getHours()
    min = ____datetmp.getMinutes()

    if hours < 10 then hours_s = '0' + hours else hours_s = hours
    if min < 10 then min_s = '0' + min else min_s = min

    time = hours_s + ':' + min_s

    day = ____datetmp.getDay()
    switch day
        when 0
            day = 147
        when 1
            day = 148
        when 2
            day = 149
        when 3
            day = 150
        when 4
            day = 151
        when 5
            day = 152
        when 6
            day = 153

    {
        date: ____datetmp
        time
        hours
        min
        day
    }

makeArray = (object) ->
    for k,v of object
        v

# get random integer value [min,max]
getRandomInt = (min, max) ->
    Math.floor(Math.random() * (max - min + 1)) + min;

fixEvent = (e) ->
    # получить объект событие для IE
    e = e || window.event

    # добавить pageX/pageY для IE
    if e.pageX == null and e.clientX != null
        html = document.documentElement
        body = document.body
        e.pageX = e.clientX + (html and html.scrollLeft or body && body.scrollLeft or 0) - (html.clientLeft or 0)
        e.pageY = e.clientY + (html and html.scrollTop or body && body.scrollTop or 0) - (html.clientTop or 0)

    # добавить which для IE
    if !e.which && e.button
        e.which = e.button & 1 ? 1 : ( e.button & 2 ? 3 : ( e.button & 4 ? 2 : 0 ) )

    return e

blog = (args...) ->
    if window.DEV_MODE
        console.log.apply console, arguments

findObjectByFields = (array, data) ->
    found = null
    for item in array
        matched = false
        for k, v of data
            matched = item[k] == v
            if !matched then break

        if matched
            found = item
            break
            return found
    found

removeElementFromArray = (element, array) ->
    existingIndex = array.indexOf element
    if existingIndex >= 0
        return array.splice existingIndex, 1

removeAll = (from, elements) ->
    for element in elements
        removeElementFromArray(element, from)

pushAll = (target, toPush) ->
    for item in toPush
        if target.indexOf(item) == -1
            target.push item

updateObject = (target) ->
    for source in arguments
        if source == target then continue
        for key, value of source
            target[key] = source[key]
    target

updateObjectFull = (target, sources...) ->
    for source in sources
        for key, value of source

            if Object.prototype.toString.call( value ) == '[object Array]'
                # Array
                target[key] = []

                for item in value
                    target[key].push item

            if typeof value == 'object'
                if !target[key]?
                    target[key] = {}

                updateObjectFull target[key], value
            else
                target[key] = angular.copy value # if target[key]
    target

getBigTimestamp = ->
    farInTheFuture = 13788003380350

# Отсечь секунды и миллисекунды, вернуть TS
toMinutes = (ts) ->
    obj = new Date ts
    new Date(obj.getFullYear(), obj.getMonth(), obj.getDate(), obj.getHours(), obj.getMinutes()).getTime()

# Отсечь и вернуть время в минутах
justMinutes = (ts) ->
    res = toMinutes ts
    res/(60*1000)

timeoutDecorator = (f, time) ->
    setTimeout ->
        f.apply this, arguments
    , time

# If CMD or CTRL key for shortcuts
isCmd = (e) -> e.metaKey or e.ctrlKey

# Обрезаем урл по кол-ву символов
# 2 типа - 1.Обрезаем в конце + '...', 2.Обрезаем в середине + ' ... '
urlCropper = (url, count, type) ->
    url = $.trim(url)
    # Обрезаем http, https и т.п.
    url = url.replace(/(http\:\/\/)|(https\:\/\/)|(www\.)/gi, '')
    # Если последний символ слэш, его тоже удаляем
    if url[url.length-1] == '/'
        url = url.substr(0,url.length-1)

    if url.length > count
        switch type
            # Обрезаем ссылку по середине и вставляем ' ... '
            when 'middle'
                start = Math.floor(url.length / 2) - Math.floor(count / 2) - 2
                end = Math.floor(url.length / 2) + Math.floor(count / 2) - 2
                url = url.substr(0, start) + ' ... ' + url.substr(end, url.length)
            # Обрезаем текст в конце и добавляем '...'
            when 'end'
                url = url.substr(0,count-3) + '...'
    url

humanizeDays = (days) ->
    if days % 7 == 0
        num = days / 7

        div = num % 10

        if div == 1
            cost = num + ' неделя'
        else if div < 5
            cost = num + ' недели'
        else
            cost = num + ' недель'
    else
        div = days % 10

        if div == 1
            cost = days + ' день'
        else if div < 5
            cost = days + ' дня'
        else
            cost = days + ' дней'

# Принимает значения: min и ms в type
convertTimeToHumanTime = (val, type) ->
    hours = 0
    if type == 'min'
        minutes = val % 60
        mod = 0
    if type == 'ms'
        minutes = Math.floor(val / 1000 / 60)
        mod = val % 60
    result = ''

    if minutes > 59
        hours = Math.floor(minutes / 60)
        minutes = Math.floor(minutes % 60)

    if minutes < 10
        minutes = '0' + minutes
    if mod < 10
        mod = '0' + mod

    if hours > 0
        result = hours + ':' + minutes + ':' + mod
    else
        result = '00:' + minutes + ':' + mod

    result
# Убираем элементы из правой панели при перетаскивании
removeElementsFromPanel = (alt) ->
    if !alt
        $('li.droppableItem.selected .removeBox', $('.selectedPanel')).trigger('click')

convertTimeToNix = (hour, min) ->
    min = Math.floor(min) * 1000 * 60
    hour = Math.floor(hour) * 1000 * 60 * 60

    min+hour

convertNixToTime = (timestamp) ->
    convertMinToHumanTime Math.floor((timestamp/1000)/60)

doGetCaretPosition = (oField) ->
    iCaretPos = 0

    if document.selection
        oField.focus()
        oSel = document.selection.createRange()

        oSel.moveStart 'character', -oField.value.length
        iCaretPos = oSel.text.length
    else if oField.selectionStart || oField.selectionStart == '0'
        iCaretPos = oField.selectionStart;

    iCaretPos

getClearDataTimestamp = (timestamp) ->
    timestamp = timestamp | 0
    if timestamp?
        data = new Date(timestamp)
        data.setHours(0,0,0,0)
        data.getTime()
    else
        timestamp

getUrlFormat = (url) ->
    re = /(http:\/\/)|(https:\/\/)/
    url = $.trim(url)
    if !re.test(url)
        url = 'http://'+url

    url

shuffle = (array) ->
    counter = array.length
    while counter > 0
        index = Math.floor(Math.random() * counter)
        counter--
        temp = array[counter]
        array[counter] = array[index]
        array[index] = temp

    return array


#Canvas animation wrapper
requestAnimFrame = requestAnimationFrame ||
    webkitRequestAnimationFrame          ||
    mozRequestAnimationFrame             ||
    ( callback ) ->
        setTimeout(callback, 1000 / 60);


selectElementContents = (el) ->
    range = document.createRange()
    range.selectNodeContents(el)
    sel = window.getSelection()
    sel.removeAllRanges()
    sel.addRange(range)

getOnlyTime = (ts) ->
    newDate = new Date(ts)
    newDate.setHours(0,0,0,0)
    newDateTS = newDate.getTime()
    ts - newDateTS


#Вставляем и центрируем картинку
defaultCommunityIcon = '/resources/images/icons/timeline-empty-avatar@2x.png'

imageInRatio = (img, ratio) ->
    imgRatio = img.height / img.width

    if imgRatio > ratio
        css =
            width: '100%'
            height: 'auto'
            marginTop: - ( (100 * imgRatio - 100 * ratio) / 2 ) + '%'
            marginLeft: 0

    else

        css =
            width: 'auto'
            height: '100%'
            marginLeft: - ( (100 * ratio / imgRatio - 100) / 2 ) + '%'
            marginTop: 0


    $(img).css css
    return css

imageIn = (img, sizeX, sizeY, whole, rel) ->
    imgRation = img.height / img.width
    containerRatio = sizeY / sizeX

    if imgRation > containerRatio
        if whole
            css =
                width: 'auto'
                height: '100%'
                marginTop: 0
                marginLeft: - ( (sizeY / imgRation - sizeX) / 2 )
        else
            css =
                width: '100%'
                height: 'auto'
                marginTop: - ( (sizeX * imgRation - sizeY) / 2 )
                marginLeft: 0

    else
        if whole
            css =
                width: '100%'
                height: 'auto'
                marginLeft: 0
                marginTop: - ( (sizeX * imgRation - sizeY) / 2 )
        else
            css =
                width: 'auto'
                height: '100%'
                marginLeft: - ( (sizeY / imgRation - sizeX) / 2 )
                marginTop: 0


    $(img).css css
    return css

    # kx = sizeX / img.width
    # ky = sizeY / img.height
    # #blog "in", img, sizeX
    # if whole  ##Здесь картинка гарантированно влезет в прямоугольник (целая)
    #     scale = if kx<ky then kx else ky
    # else      ##Здесь картинка гарантированно покроет прямоугольник (превью)
    #     scale = if kx>ky then kx else ky
    # if !scale then scale = 1  #Если вдруг масштаб вычислить не удастся, просто двигаем без масштаба

    # width = img.width * scale
    # height = img.height * scale

    css =
        width: width
        height: height

        marginTop: -(height-sizeY)/2 + 'px'
        marginLeft: -(width-sizeX)/2 + 'px'

    if rel  # переводим в проценты
        css.width = 100*width/sizeX + '%'
        css.height = 100*height/sizeY + '%'

        css.marginTop = 100*parseInt(css.marginTop) / sizeX + '%'
        css.marginLeft = 100*parseInt(css.marginLeft) / sizeY + '%'

    $(img).css css
    return css


# Math
Math.easeInOutQuad = (t, b, c, d) ->
    #t - current time, b - start value, c - change in value, d - duration
    t /= d/2
    if t < 1 then return c/2*t*t + b
    t--
    return -c/2 * (t*(t-2) - 1) + b


#Array
makeArrayByLength = (l) ->
    a=new Array()
    a.length = l
    a

makeArrayByFromTo = (from, to) ->
    for c in [from...to+1]
        c

#color transforms
getColor = (color) ->
    if !color then return false
    if color.indexOf('rgba')+1
        color = color.replace(/[()\sa-z]/g, '').split(",")
        color =
            r: +color[0]
            g: +color[1]
            b: +color[2]
            a: +color[3]

    color

makeRGBA = (color) ->
    'rgba('+color.r+', '+color.g+', '+color.b+', '+color.a+')'

makeHEX = (color) ->
    for i of color
        color[i] = color[i].toString(16)
    '#'+color.r+color.g+color.b

# --- email ---
isEmail = (mail) ->
    /[\w.]+\@[\w.]+\.\w{2,}/g.test(mail)

# --- strings ---
joinStrings = (strings, separator = ' ') ->
    #TODO если сепаратор не пробел, надо следить за пустыми строками и undefined
    res = strings.join(separator).replace(/\s+/g, ' ').replace(/(^\s+)|(\s+$)/g, '') # trim


#dev helper
DEV_MODE = false

switchDevMode = (state) ->
    DEV_MODE = !DEV_MODE
    if state then DEV_MODE = true

    if DEV_MODE
        localStorage['DEV_MODE'] = true
    else
        delete localStorage['DEV_MODE']

loadDevMode = ->
    DEV_MODE = localStorage['DEV_MODE'] || false

loadDevMode()

#---

# --- flow ---
class AsyncFlow
    constructor: () ->
        @actions = []
        @completed = 0
        @succeeded = 0

    add: (action) ->
        @actions.push action

    fire: (cb) ->
        for i in @actions
            do (i) => # next function
                i.action (res) =>
                    @completed++
                    if typeof res == 'undefined' then res = true
                    if res
                        @succeeded++
                        i.completed = true
                        if @completed == @actions.length
                            if @completed == @succeeded then cb? true else cb? false

#
keyCodes =
    backspace: 8
    tab: 9
    enter: 13
    shift: 16
    ctrl: 17
    alt: 18
    caps: 20
    esc: 29
    space: 32

# location parse url
getQuery = (loc) ->
    if !loc then loc = location
    #if typeof url = 'string' # TODO make url object
    query  = {}
    search = decodeURIComponent loc.search.substr(1)
    items  = search.split '&'
    for i in items
        [k,v] = i.split '='
        query[k] = v
    query

# --- spinner ---

makeSpinner = (target, options) ->
    spinnerOptions =
        lines: 13
        length: 20
        width: 2
        radius: 30
        corners: 1
        rotate: 0
        direction: 1
        color: '#fff'
        speed: 1
        trail: 66
        shadow: true
        hwaccel: true
        className: 'spinner'
        zIndex: 2e9
        top: "50%"
        left: "50%"


    if options then updateObject spinnerOptions, options

    spinner = new Spinner(spinnerOptions)
    spinner.spin target if target
    spinner
