*deps: account, streamService

elem = $ element

scope.session.noItem = true
scope.session.size =
    width: 600
    height: 500

scope.streams = streamService.storage
streamService.query
    member: account.user.id
, (items) ->
    # scope.streams.length = 0
    # for item in items
    #     scope.streams.push item
scope.streamFilter = (stream) ->
    if stream.deleted == true
        return false
    true

scope.activeModule = null

scope.launchPeople = ->
    scope.flow.addFrame
        # title: 'people'
        # directive: 'novaPeopleFrame'
        # data:
        #     userId: account.user.id
        title: 'people'
        directive: 'novaUsersGroups'
        data:
            userId: account.user.id

scope.launchStream = (stream) ->
    scope.flow.addFrame
        title: 'stream'
        directive: 'novaStreamFrame'
        item:
            id: stream.id
            type: 'stream'
        data:
            streamId: stream.id

scope.init = ->
    if scope.session.stream?
        scope.launchStream scope.session.stream
    else
        scope.launchPeople()

scope.reInit = (data) ->
    if data.stream?.id?
        scope.flow.addFrame
            title: 'stream'
            directive: 'novaStreamFrame'
            item:
                id: data.stream.id
                type: 'stream'
            data:
                streamId: data.stream.id
