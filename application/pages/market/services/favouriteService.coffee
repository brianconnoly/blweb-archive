# buzzlike.service 'favouriteService', (httpWrapped, operationsService, env) ->

#     list = []

#     purge = () ->
#         list.length = 0

#     fetch = () ->
#         httpWrapped.get env.baseurl + '/market/favorites', (data) ->
#             data = data or {}
#             list.length = 0
#             if data.lotIds?
#                 for id in data.lotIds
#                     list.push id
#         true

#     addFavourite = (item) ->
#         list.push item
#         operationsService.requestOperation
#             action: 'create'
#             entities: [{type:'marketFavorites', lotIds:[item]}]

#         true

#     removeFavourite = (item) ->
#         operationsService.requestOperation
#             action: 'delete'
#             entities: [{type:'marketFavorites', lotIds:[item]}]

#     triggerFavourite = (item) ->
#         index = list.indexOf item
#         if index > -1
#             list.splice index, 1
#             removeFavourite item
#         else
#             addFavourite item
#         true

#     isFavourite = (item) ->
#         if list.indexOf(item) > -1
#             return true
#         false

#     operationsService.registerAction 'update', 'marketFavorites', (id, data) ->
#         list.length = 0
#         for id in data.entity.lotIds
#             list.push id

#     {    
#         list

#         fetch

#         addFavourite
#         removeFavourite

#         triggerFavourite
#         isFavourite
#     }
