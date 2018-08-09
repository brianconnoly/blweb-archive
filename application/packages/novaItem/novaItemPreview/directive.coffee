*deps: $compile, contentService

elem = $ element
previewElem = null
if attrs.novaItemPreviewBackFace
    elem.append $ '<div>',
        class: 'backFace'

# novaInfo activator
infoActivator = $ '<div>',
    class: 'novaInfoActivator'
    html: 'i'
infoActivator.on 'mousedown', (e) ->
    e.stopPropagation()
    e.preventDefault()
    if scope.flowBox?
        scope.flowBox.addFlowFrame
            title: 'info'
            directive: 'novaInfoFrame'
            item:
                id: scope.previewItem.id
                type: scope.previewItem.type
        , scope.flowFrame
elem.append infoActivator

scope.buildPreview = buildPreview = ->
    scope.previewItem = scope.item
    itemType = scope.item.type
    if !itemType?
        console.log 'WTF?', scope.item
        return
    previewClass = 'nova' + itemType.capitalizeFirstLetter() + 'Preview'
    if attrs.novaItemPreviewType?
        previewClass += attrs.novaItemPreviewType.capitalizeFirstLetter()

    previewElem = $ '<div>',
        class: previewClass
    tmpl = tC['/' + previewClass + '/template.jade']

    if tmpl?
        previewElem.append tmpl
    else if tC['/' + 'nova' + itemType.capitalizeFirstLetter() + 'Preview' + '/template.jade']?
        previewElem.append tC['/' + 'nova' + itemType.capitalizeFirstLetter() + 'Preview' + '/template.jade']
        previewElem.addClass('nova' + itemType.capitalizeFirstLetter() + 'Preview')
    else
        previewElem.append 'not implemented preview: ' + scope.item.type

    if itemType in contentService.getContentTypes()
        previewElem.addClass 'novaContentPreview'

    previewElem.appendTo elem
    $compile(previewElem)(scope)

scope.rebuildPreview = ->
    previewElem?.remove?()
    scope.buildPreview()

# Wait till local item is inited
unregInit = scope.$watch 'novaItemInited', (nVal) ->
    if nVal == true
        unregInit()

        # Wait till item is loaded
        unreg = scope.$watch 'item.type', (nVal) ->
            if nVal?
                unreg()
                buildPreview()

                if attrs.novaItemWatch
                    scope.$watch 'item.id', (nVal) ->
                        scope.rebuildPreview()
