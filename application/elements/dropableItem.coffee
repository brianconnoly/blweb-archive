buzzlike.directive 'droppableItem', ($parse, stateManager, actionsService, operationsService, taskService, dropHelper, contentService, ruleService, scheduleService, communityService, account, dragMaster, combService, postService, $rootScope) ->
    restrict: 'C'
    link: (scope, element, attrs) ->
        canaccept = null

        jelem = $ element
        rightPanel = false
        rightPanelFolder = false
        if jelem.parents('.selectedPanel').length > 0
            rightPanel = true

        dropElem = null
        lineId = null
        groupId = null
        groupItem = null

        context = null

        if attrs.dropableItem?
            dropableItem = $parse(attrs.dropableItem)(scope)
        else
        # if !attrs.dropableItem? !scope.dropableItem?
            if attrs.type? and attrs.id?
                type = 'content'
                if attrs.type?
                    type = attrs.type

                operationsService.get type, attrs.id, (item) ->
                    dropableItem = item

            else if attrs.type? and scope.id?
                type = 'content'
                if attrs.type?
                    type = attrs.type

                operationsService.get type, scope.id, (item) ->
                    dropableItem = item
            else if attrs.item?
                    dropableItem = $parse(attrs.item)(scope)
            else if scope.item?
                dropableItem = scope.item

        if attrs.context?
            context = $parse(attrs.context)(scope)
        else
            context = stateManager.getContext()

        phIndex = -1

        currentActions = null
        new dragMaster.dropTarget element[0],
            enter: (elem, e) ->
                if !attrs.noEffects?
                    element.addClass('content-drop')
                dropHelper.show currentActions if currentActions?
                # scope.$apply()
            leave: (elem) ->
                if jelem.hasClass('sorting-post-content')
                    __pholderHelper.detach()
                    $('.sorting-hidden').removeClass('sorting-hidden')

                $('sorting-hidden').removeClass 'sorting-hidden'
                if !attrs.noEffects?
                    $(element).removeClass('content-drop')
            canAccept: (elem, e) ->
                # if $(e.target).attr('id') == '__pHolderHelper'
                #     return true

                if jelem.hasClass 'sorting-post-content'
                    return true

                if attrs.dropableItem?
                    dropableItem = $parse(attrs.dropableItem)(scope)

                sameType = true
                for item in elem.dragObject.items
                    if item.type != elem.dragObject.items[0].type
                        sameType = false
                        break

                # Post sorting hack
                if sameType and elem.sourceContext?.type == 'post' and jelem.parent()[0] == $(elem).parent()[0] # elem.sourceContext == context and 
                    window.__pholderIndex = -1
                    # $(elem).addClass('sorting-hidden')
                    jelem.parents('.postEditor').addClass 'sorting-post-content'
                    jelem.parent().find('.selected').addClass('sorting-hidden')

                    index = jelem.parent().children().index __pholderHelper
                    elemIndex = jelem.parent().children().index jelem

                    if index == -1
                        __pholderHelper.insertBefore jelem
                        window.__pholderIndex = elemIndex
                    else
                        if elemIndex > index
                            __pholderHelper.insertAfter jelem
                            window.__pholderIndex = elemIndex + 1
                        else
                            __pholderHelper.insertBefore jelem
                            window.__pholderIndex = elemIndex

                    return false

                if attrs.context?
                    context = $parse(attrs.context)(scope)
                else
                    context = stateManager.getContext()

                currentActions = actionsService.getActions 
                    source: elem.dragObject.items
                    sourceContext: elem.sourceContext
                    target: dropableItem
                    context: context
                    targetOnly: true
                    actionsType: 'dragndrop'

                currentActions.length > 0
            drop: (elem, e) ->

                if jelem.hasClass 'sorting-post-content'

                    if attrs.dropableItem?
                        dropableItem = $parse(attrs.dropableItem)(scope)

                    # Get drop index
                    console.log window.__pholderIndex, dropableItem

                    # Get ids
                    ids = []
                    for item in elem.dragObject.items
                        ids.push item.id
                        removeElementFromArray item.id, dropableItem.contentIds[item.type]

                    newList = []
                    for id,i in dropableItem.contentIds[item.type]
                        if i == window.__pholderIndex
                            for insertId in ids
                                newList.push insertId
                        newList.push id

                    dropableItem.contentIds[item.type] = newList

                    process = scope.progress.add()
                    postService.save
                        id: dropableItem.id
                        contentIds: dropableItem.contentIds
                    , ->
                        scope.progress.finish process


                dropHelper.activate e, elem.sourceContext?.type == 'rightPanel'
                scope.$apply()



                