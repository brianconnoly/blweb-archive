buzzlike.factory 'socialContentBrowser', (env, httpWrapped, contentService, buffer) ->
    socialBaseUrl = env.baseurl + '/social'

    status =
        loading: false
        empty: false
    content = []

    # owner is a communityId or accountId
    fetchAlbums = (contentCommunity, type, cb) ->
        owner = contentCommunity.id
        sn = contentCommunity.socialNetwork
        status.loading = true
        status.empty = false
        rpc.call sn + 'Import.getAlbums', 
            type: type
            communityId: owner
        , (albums) ->
            if albums.err == true
                return
                
            content.length = 0

            for album in albums
                album.type = 'album'
                content.push(album)

            status.loading = false

            cb? albums
        , true

    handleIncomingContent = (items)->
        if items.err == true
            return

        content.length = 0

        for contentItem in items
            if content.indexOf(contentItem) < 0 then content.push(contentItem)

        status.loading = false

        if items.length == 0
            status.empty = true

    fetchAlbumContent = (album) ->
        sn = album.socialNetwork

        status.loading = true
        status.empty = false
        rpc.call sn + 'Import.getAlbumContent', album, handleIncomingContent, true

    #!!!!!!!!!!!!!!! INTERFACE !!!!!!!!!!!!!!!!!!!!

    fetchAlbums : fetchAlbums
    fetchAlbumContent : fetchAlbumContent

    importAlbum: (album, cb) ->
        sn = album.socialNetwork

        rpc.call sn + 'Import.importAlbum', album, (folder) ->
            if folder?
                item = contentService.handleItem folder
                buffer.addItems [folder]

    importItem: (item, cb) ->

        rpc.call 'socialImport.importItem', item, (createdItem) ->
            if createdItem?
                item = contentService.handleItem createdItem
                buffer.addItems [createdItem]

    #to be used for binding
    getContent: () ->
        content

    purge: () ->
        content.length = 0

    getAvailableTypes: (contentCommunity, cb) ->
        owner = contentCommunity.id
        sn = contentCommunity.socialNetwork
        types = []
        status.loading = true
        status.empty = false
        rpc.call sn + 'Import.getAvailableTypes', owner, (data) ->

            for item in data
                types.push item

            if types.length == 0
                status.empty = true
                status.loading = false

            cb? types

        types

    status: status
