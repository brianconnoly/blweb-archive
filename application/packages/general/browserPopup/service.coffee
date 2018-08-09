#inteface
open = (url, options) ->
    options = options or {}
    width   = options.width   || 607
    height  = options.height  || 629
    caption = options.caption || '_blank'

    screenX = if typeof window.screenX != 'undefined' then window.screenX else window.screenLeft
    screenY = if typeof window.screenY != 'undefined' then window.screenY else window.screenTop
    outerWidth = if typeof window.outerWidth != 'undefined' then window.outerWidth else document.body.clientWidth
    outerHeight = if typeof window.outerHeight != 'undefined' then window.outerHeight else (document.body.clientHeight - 22)
    left = Math.floor(screenX + ((outerWidth - width) / 2), 10)
    top = Math.floor(screenY + ((outerHeight - height) / 2.5), 10)

    features = (
        'width=' + width +
        ',height=' + height +
        ',left=' + left +
        ',top=' + top
    )

    wnd = window.open(url, caption, features)
    #blog wnd, url, caption, features
    if !wnd
        if navigator?.vendor?.indexOf("Apple")+1
            alert("К сожалению, у Safari возникли трудности с открытием всплывающего окна. Пока мы ищем способ решить проблему, попробуйте использовать другой браузер.")
        else
            alert("Неизвестная ошибка, связанная с открытием всплывающего окна. Попробуйте обновить браузер до последней версии или обратитесь в тех. поддержку.")

    wnd

parseHref = (url) ->
    data = url?.split(/\?|&|#/);
    GET = {}

    if data
        for pair in data
            if pair.indexOf("=")+1
                key = pair.split("=")[0]
                val = pair.split("=")[1]
                GET[key] = val
    GET

waitResponse = (popup, statuses, cb) ->
    if popup then I = setInterval ->
        try
            href = popup.document?.location?.href
        catch e
            true
            #timeout_id = setTimeout check_auth, 300

        #blog popup, statuses, href
        href = popup.document?.location?.href
        GET = getQuery popup.document?.location
        if GET.status and popup.document.body
            statuses[GET.status]?()
            clearInterval I
            cb? GET.status
        #else
        #    for i of GET
        #        popup.document.innerHTML += "GET."+i+": "+GET[i]+"<br>"

        if !href
            clearInterval I
    , 50
#return

window.popen = open
{
    open
    waitResponse
}