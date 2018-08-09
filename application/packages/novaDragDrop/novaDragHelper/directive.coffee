*deps: novaDragHelper
*scope: true

novaDragHelper.bindElement $(element), scope

scope.fireAction = (action, e) ->
    if novaDragHelper.preAction?
        novaDragHelper.preAction action.action, e
    else
        action.action e
    scope.novaDragHelper.hide true
    true

# scope.$watch 'actions', (nVal) ->
#     # console.log nVal, element, scope
# , true
