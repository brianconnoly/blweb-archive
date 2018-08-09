*deps: communityService, accountService, account, importContentService, importAlbumService

scope.items = []

seq = new Sequence
    name: 'Fetch album content'

seq.addStep
    name: 'Get album'
    var: 'album'
    action: (next) ->
        importAlbumService.getById scope.wizard.data.albumId, next

seq.addStep
    name: 'Query albums'
    var: 'items'
    action: (next) ->
        importContentService.query
            albumId: seq.album.id
            albumType: seq.album.albumType
            sn: seq.album.socialNetwork
            snOwnerId: seq.album.snOwnerId
            id: seq.album.albumId
            communityId: seq.album.communityId
        , next

seq.addStep
    name: 'Parse result'
    action: (next) ->
        scope.items.length = 0
        for item in seq.items
            scope.items.push item
        next true

seq.fire ->
    true
