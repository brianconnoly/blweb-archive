*deps: userService, userGroupService, account, streamService
*replace: true

scope.userGroups = []
userGroupService.query {}, (items) ->
    scope.userGroups.length = 0
    for item in items
        scope.userGroups.push item

# Search new
scope.filterBox = ""
scope.searchResults = []
scope.doSearch = ->
    userService.call 'search', scope.filterBox, (user) ->
        scope.searchResults.length = 0
        if user != 'noUser'
            scope.searchResults.push user
scope.backToGroups = ->
    scope.searchResults.length = 0

scope.startStream = (user) ->
    streamService.create
        members: [
            userId: account.user.id
            role: 'initiator'
        ,
            userId: user.id
            role: 'member'
        ]
    , (stream) ->
        scope.flow.addFrame
            title: 'stream'
            directive: 'novaStreamFrame'
            data:
                streamId: stream.id
