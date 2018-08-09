*deps: $sce, localization, $parse, uploadService
*require: '?ngModel'

    if !ngModel then return

    # Init
    elem = element[0]
    jElem = $ elem
    elem.contentEditable = true

    ceId = 'ce' + getRandomInt(10000,99999) + '_' + Date.now()
    element.attr 'id', ceId
    $('body').on 'mousedown.'+ceId, (e) ->
        elem.blur()
        window.getSelection().removeAllRanges()

    # Placeholder
    placeholder = ""
    # Create ph style
    styles = $ '<style>'
    $('head').append styles

    scope.$on '$destroy', ->
        styles.remove()
        $('body').off 'mousedown.'+ceId

    # Placeholder
    if attrs.placeholderText?
        placeholder = localization.translate $parse(attrs.placeholderText)(scope)

        if $sce.getTrustedHtml(ngModel.$viewValue || '') == ''
            styles.html "##{ceId}.placeholder:after {content:'#{placeholder}'}"

        scope.$watch ->
            localization.state
        , (nVal) ->
            placeholder = localization.translate $parse(attrs.placeholderText)(scope)

            if element.hasClass 'placeholder'
                styles.html "##{ceId}.placeholder:after {content:'#{placeholder}'}"
        , true

    # Ng-model settings
    ngModel.$render = () ->
        value = $sce.getTrustedHtml(ngModel.$viewValue || '')

        element.removeClass 'placeholder'
        if value == '' # and placeholder?.length > 0 # document.activeElement != elem and
            element.addClass 'placeholder'

        element.html value

    element.on 'blur keyup change', (e) ->
        scope.$evalAsync ->
            html = read()

    element.on 'keydown', (e) ->
        element.removeClass 'placeholder'
        if attrs.onCmdEnter?
            if e.which == 13 and isCmd e
                e.stopPropagation()
                e.preventDefault()
                $parse(attrs.onCmdEnter)(scope)()
        if attrs.onEnter?
            if e.which == 13
                e.stopPropagation()
                e.preventDefault()
                $parse(attrs.onEnter)(scope)()

    element.on 'paste', (e) ->
        if e.clipboardData?.items.length > 0
            seq = new Sequence
                name: 'Parse pasted items'

            seq.addStep
                name: 'Prepare items'
                var: 'items'
                iterator: (step) ->
                    for item in e.clipboardData.items
                        step item if item.kind == 'file'
                action: (next, retry, item) ->
                    reader = new FileReader()
                    file = item.getAsFile()
                    reader.onload = (e) ->
                        next
                            item: file
                            blob: event.target.result

                    reader.readAsBinaryString file

            seq.addStep
                name: 'Do upload'
                var: 'uploadResult'
                action: (next) ->
                    uploadService.upload
                        buffer: seq.items
                    , next
                    # next true

            seq.fire (result) ->
                if attrs.pastedItems?
                    $parse(attrs.pastedItems)(scope)?(seq.uploadResult)
                true

        setTimeout ->
            html = elem.innerText || elem.textContent
            element.html html
            ngModel.$setViewValue html
        , 0

    element.on 'mousedown', (e) ->
        e.stopPropagation()

    element.on 'focus', (e) ->
        html = read()

    element.on 'blur', (e) ->
        html = elem.innerText || elem.textContent
        if html == ''
            element.addClass 'placeholder'

    read = ->
        html = elem.innerText || elem.textContent
        if html == ''
            element.addClass 'placeholder'
        else
            element.removeClass 'placeholder'
        #     html = ''
        ngModel.$setViewValue html
        html

    # Disabled
    if attrs.disabled?
        scope.$watch attrs.disabled, (nVal) ->
            if nVal == true
                elem.contentEditable = false
            else
                elem.contentEditable = true

    # Run
    read()

    if attrs.autoFocus?
        $(element).focus()

    true
