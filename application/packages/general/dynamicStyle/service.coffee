uniqCnt = 0

class dynamicStyle
    constructor: (@styleName, styleData = "") ->
        @className = 'dynamicStyle_' + uniqCnt++
        @styleName = @styleName.replace '$', @className
        @style = $ '<style>'
        @style.appendTo 'head'
        @update styleData

    update: (data) ->
        @style.html @styleName + " {\n" + data + "\n}\n"

    destroy: ->
        @style.remove()

dynamicStyle