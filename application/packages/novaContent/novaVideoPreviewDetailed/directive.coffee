
elem = $ element

switch scope.item.sourceType
    when 'vkVideo', 'vkontakte'
        src = scope.item.embeddedPlayer.replace('http://', '//')
        videoObj = $('<iframe>')
        videoObj.attr('src', src)
        videoObj.attr('width', '100%')
        videoObj.attr('height', '100%')

        elem.append videoObj

    when 'youtubeVideo', 'youtube'
        id = scope.item.embeddedPlayer.split('?v=')[1]
        src = '//www.youtube.com/embed/' + id

        videoObj = $('<iframe>')
        videoObj.attr('src', src)
        videoObj.attr('width', '100%')
        videoObj.attr('height', '100%')

        elem.append videoObj
