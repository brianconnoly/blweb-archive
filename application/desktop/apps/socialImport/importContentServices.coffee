buzzlike
    .service 'importAlbumService', (rpc, itemService, contentService) ->

        class classEntity extends itemService

            itemType: 'importAlbum'

            fetchById: (id, cb) ->
                idData = id.split '_'
                # SN _ communityId _ type _ albumId

                cb? {
                    id: id
                    type: idData[2]
                    communityId: idData[1]
                    albumId: idData[3]
                }

            query: (data, cb) ->
                rpc.call data.sn + 'Import.getAlbums',
                    type: data.type
                    communityId: data.communityId
                , (items) =>
                    result = []
                    if items?.length > 0
                        for item in items
                            item.albumId = item.id
                            item.id = data.sn + '_' + data.communityId + '_' + data.type + item.id
                            item.type = @itemType
                            result.push @handleItem item
                    cb? result

            import: (album, cb) ->
                rpc.call album.socialNetwork + 'Import.importAlbum',
                    albumType: album.albumType
                    snOwnerId: album.snOwnerId
                    id: album.albumId
                    communityId: album.communityId
                    title: album.title
                , (folder) ->
                    if folder?.id
                        item = contentService.handleItem folder
                        cb? item

        new classEntity()

    .service 'importContentService', (rpc, itemService, contentService) ->

        counter = 0
        class classEntity extends itemService

            itemType: 'importContent'

            purge: () ->
                counter = 0
                super()

            handleItem: (item) ->
                if !item.id?
                    item.id = counter++
                if !item.contentType?
                    item.contentType = item.type
                    item.type = @itemType
                super item

            fetchById: (id, cb) ->
                cb? {
                    id: id
                }

            query: (data, cb) ->
                rpc.call data.sn + 'Import.getAlbumContent',
                    albumType: data.albumType
                    snOwnerId: data.snOwnerId
                    id: data.id
                    communityId: data.communityId
                , (items) =>
                    result = []
                    for item in items
                        item.id = item.externalId
                        item.contentType = item.type
                        item.type = @itemType
                        result.push @handleItem item
                        @storage[item.id] = item
                    cb? result

            import: (itemData, params, cb) ->
                data = angular.copy itemData
                data.type = data.contentType
                for k,v of params
                    data[k] = v if v?
                rpc.call 'socialImport.importItem', data, (createdItem) ->
                    if createdItem?
                        item = contentService.handleItem createdItem
                        cb? item

        new classEntity()
