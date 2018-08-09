buzzlike
    .directive 'scrollBindTo', () ->
        link: (scope, element, attrs) ->
            attr = attrs['scrollBindTo']
            if attr[0] == '@'
                here = true
                attr = attr.replace("@", "")
                elem = $(element).find attr
            else
                here = false
                elem = $(attr)

            setEvent = ->
                $(element).on "mousewheel", (e, d, dx, dy) ->
                    elem = if here then $(element).find(attr) else $(attr)
                    box = elem.find(".scroll-box")
                    if !box.length then box = elem
                    x = box.scrollLeft()
                    y = box.scrollTop()

                    box.scrollLeft x-dx
                    box.scrollTop y-dy

            elem
                .on 'mouseenter', ->
                    $(element).off 'mousewheel'
                .on 'mouseleave', setEvent

            setEvent()


#.directive 'scrollBindWith', () ->
