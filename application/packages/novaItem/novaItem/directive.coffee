*deps: operationsService, $parse
*restrict: 'AC'

scope.novaItemInited = false

# Init item context
if attrs.novaItemContext?
    unregCtx = scope.$watch attrs.novaItemContext, (nVal) ->
        if nVal?.type?
            unregCtx()
            scope.itemContext = nVal
    , true

# Init item
if attrs.novaItemObject?
    unreg = scope.$watch attrs.novaItemObject, (nVal) ->
        if nVal?.type?
            unreg()
            scope.novaItemInited = true
            scope.item = nVal #$parse(attrs.novaItemObject)(scope)

            if attrs.novaItemWatch?
                scope.$watch attrs.novaItemObject, (nVal) ->
                    if nVal?
                        scope.novaItemInited = true
                        scope.item = nVal
                        # scope.rebuildPreview?()
    , true
    return

if attrs.novaItemType? and attrs.novaItemId?
    itemId = $parse(attrs.novaItemId)(scope)
    scope.novaItemInited = true
    scope.item = operationsService.get attrs.novaItemType, itemId
    if attrs.novaItemWatch?
        scope.$watch attrs.novaItemId, (nVal) ->
            if nVal?
                scope.item = operationsService.get attrs.novaItemType, nVal
                # scope.rebuildPreview?()
                # scope.buildPreview?() # Little kostyl'

    # unreg = scope.$watch attrs.novaItemId, (nVal) ->
    #     console.log 'EID', nVal, attrs
    #     if nVal?
    #         unreg()
    #         scope.novaItemInited = true
    #         scope.item = operationsService.get attrs.novaItemType, nVal
    return

if scope.item?
    scope.novaItemInited = true
    return
