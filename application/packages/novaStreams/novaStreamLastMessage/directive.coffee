
now = new Date()
msg = new Date scope.streamItem.created
scope.today = now.getDate() == msg.getDate() and now.getMonth() == msg.getMonth()

unreg = scope.$watch 'user', ->
    setTimeout ->
        scope.onLoad?()
    , 0
    unreg()
