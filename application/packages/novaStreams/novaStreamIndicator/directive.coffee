*deps: account, $parse

scope.streamUpdates = 0
recountUpdates = ->
    console.log 'recount?', scope
    if !scope.streamParentItem?.userUpdated?['uid' + account.user.id]?
        return
    scope.streamUpdates = scope.streamParentItem.totalUpdates - scope.streamParentItem.userUpdated['uid' + account.user.id].updates

unreg = scope.$watch attrs.novaStreamItem, (nVal) ->
    if nVal?.type?
        unreg()
        scope.streamParentItem = nVal

        console.log 'watch', 'streamParentItem.userUpdated.uid' + account.user.id + '.updates'

        scope.$watch 'streamParentItem.userUpdated.uid' + account.user.id + '.updates', recountUpdates
        scope.$watch 'streamParentItem.totalUpdates', recountUpdates
, true
