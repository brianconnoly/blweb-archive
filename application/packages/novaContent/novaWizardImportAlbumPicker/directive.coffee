*deps: communityService, accountService, account, importAlbumService

scope.items = []
scope.types = ['image','audio','video']
scope.currentType = scope.wizard.data.albumType or 'image'

scope.pickAlbumType = (type) ->
    scope.currentType = type
    scope.wizard.data.albumType = type
    scope.items.length = 0
    fetchContent()

fetchContent = (cb) ->
    importAlbumService.query
        type: scope.currentType
        communityId: seq.community.id
        sn: seq.community.socialNetwork
    , (items) ->
        scope.items.length = 0
        for item in items
            scope.items.push item
        cb? true

seq = new Sequence
    name: 'Fetch albums'

seq.addStep
    name: 'Get community'
    var: 'community'
    action: (next) ->
        communityService.getById scope.wizard.data.communityId, next

seq.addStep
    name: 'Query albums'
    var: 'albums'
    action: (next) ->
        fetchContent next

seq.fire ->
    true
