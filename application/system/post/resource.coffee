# buzzlike.factory 'postResource', (queryService, notificationService, localization, communityService, operationsService, env, contentService, httpWrapped, $rootScope, $injector) ->

#     #notificationCenter = null

#     postBaseUrl = env.baseurl + '/posts'

#     posts = {}
#     internalPostsCounter = 1

#     purge = () ->
#         emptyObject posts

#     fetchPostsByQuery = (query, cb) ->
#         httpWrapped.get postBaseUrl, (posts) ->
#             for post in posts
#                 post.type = 'post'
#                 existing = posts["id_"+post.id]
#                 if existing?
#                     updateObject existing, post
#                 else
#                     putPost post
#             cb? posts

#     putPost = (post) ->
#         if posts['id_'+post.id]?
#             updateObject posts['id_'+post.id], post
#         else
#             posts['id_'+post.id] = post

#         if !post.blank?
#             delete posts['id_'+post.id].blank if posts['id_'+post.id].blank?

#         posts['id_'+ post.id]

#     stackToLoad =
#         ids: []
#         handler: false
#         cbs: []

#     fetchServerPost = (id, cb) ->
#         fetchServerPosts [id], cb

#     fired = false
#     fetchServerPosts = (ids, cb) ->
#         if fired then return
#         fired = true
#         queryService.query
#             entityType: 'post'
#             ids: ids
#         , (items) ->
#             console.log 'recieved', items
#             list = []
#             for post in items
#                 delete post.blank if post.blank?
#                 list.push putPost post

#             cb? list

#         # for id in ids
#         #     if id not in stackToLoad
#         #         stackToLoad.ids.push id

#         # stackToLoad.cbs.push cb

#         # if !stackToLoad.handler then stackToLoad.handler = setTimeout () ->
#         #     if stackToLoad.ids.length > 0 then doFetchPostsByIds stackToLoad.ids, stackToLoad.cbs

#         #     stackToLoad =
#         #         ids: []
#         #         handler: false
#         #         cbs: []
#         # , 500
#         true

#     doFetchPostsByIds = (ids, cbs) ->
#         httpWrapped.post postBaseUrl + '/idList', ids, (items) ->
#             for post in items
#                 post.blank = false
#                 putPost post

#             if cbs?
#                 for cb in cbs
#                     cb? items

#     getPostById = (id, cb) ->
#         console.log 'fired', id
#         # if !id
#         #     return null
#         post = posts['id_'+ id]
#         requested = false
#         if post
#             requested = true
#             if post.blank != true
#                 cb? post
#                 return post

#         fetchServerPost id, (post) ->
#             cb? posts['id_'+ id]

#         if post?
#             return post

#         newPost =
#             blank: true
#             id: id
#             type: 'post'

#         clearPostContent(newPost)
#         stored = putPost newPost

#         return stored

#     # or itemIds
#     storeContentItemsToPost = (post, items) ->
#         for item in items
#             if ('string' == typeof item)
#                 item = contentService.getContentById item
#             if ! (item.id in post.contentIds[item.type])
#                 post.contentIds[item.type].push item.id
#         checkPostReadyToSchedule(post)

#     clearPostContent = (post) ->
#         post.contentIds = {}
#         for type in contentService.types
#             post.contentIds[type] = []

#     doAddNewPost = (post, combId , cb) ->
#         post.combId = combId
#         putPost post
#         # We can postpone saving of posts later
#         httpWrapped.post env.comb.base + '/' + combId + "/post", post,  (savedPost) ->
#             for key of savedPost
#                 post[key] = savedPost[key]

#             putPost(post)
#             checkPostReadyToSchedule(post)
#             cb? post

#     saveNewPost = (post, cb) ->
#         checkPostReadyToSchedule post
#         httpWrapped.post env.comb.base + '/' + post.combId + "/post", post, (savedPost) ->
#             updateObject post, savedPost

#             putPost post
#             cb? post

#     addPost = (post) ->
#         putPost post

#     savePost = (post, cb) ->
#         checkPostReadyToSchedule post
#         # httpWrapped.put postBaseUrl, post, (data) ->
#         #     cb? data
#         operationsService.requestOperation
#             action: 'update'
#             entities: [post]
#         , () ->
#             cb? post

#     deletePostCacheById = (postId) ->
#         delete posts['id_'+ postId]

#     deletePostCache = (post) ->
#         deletePostCacheById post.id

#     # Social Network limits Stuff...
#     getLimits = (network) ->
#         for net in $rootScope.networks
#             return net.limits if network == net.type
#         return false

#     checkPostReadyToSchedule = (post) ->
#         post.readyToSchedule = true
#         if !post.socialNetwork then return true #ready

#         limits = getLimits(post.socialNetwork)

#         if !limits then return true #error, but ready

#         #blog "lim:", limits, post

#         errorMessages = []
#         postData = {} #all information about post and content

#         postData.contentLength = post.contentIds.audio.length + post.contentIds.video.length + post.contentIds.image.length
#         if !postData.contentLength then return true #Если нет контента, дальше не проверяем
#         postData.types = []
#         postData.types.push "audio" if post.contentIds.audio.length
#         postData.types.push "video" if post.contentIds.video.length
#         postData.types.push "image" if post.contentIds.image.length

#         if post.contentIds.url.length > limits.urlsLimit.number
#             errorMessages.push( localization.translate('readyToSchedule_manyLinks')
#                 .replace('%n', limits.urlsLimit.number)
#             )#"Too many links."
#             post.readyToSchedule = false

#         #Как ни странно, комментирует не Фил :D
#         #Если типов контента несколько, проверяем допустимую сумму контента
#         if postData.types.length > 1
#             #Если сумма превышает допустимую, пост уже в любом случае не готов
#             if postData.contentLength > limits.contentTotal
#                 errorMessages.push( localization.translate('readyToSchedule_manyContents')
#                     .replace('%n', limits.contentTotal)
#                 )#"Too many summary contents."
#                 post.readyToSchedule = false

#             #Пробегаем по контенту и смотрим ограничения для каждой еденицы
#             postData.contents = [].concat(post.contentIds.audio, post.contentIds.video, post.contentIds.image, post.contentIds.text, post.contentIds.url)
#             data = contentService.getContentByIdList postData.contents


#         #Если только один какой-то тип, смотрим его ограничения и исключения
#         else
#             limitType = postData.types[0]+"sLimit"
#             postData.contents = [].concat(post.contentIds[postData.types[0]], post.contentIds.text, post.contentIds.url)
#             data = contentService.getContentByIdList postData.contents

#             if post.contentIds[postData.types[0]].length > limits[limitType].number
#                 errorMessages.push(localization.translate('readyToSchedule_manyOneTypeContents')
#                     .replace('%s', localization.translate('readyToSchedule_contentTypes')[postData.types[0]])
#                     .replace('%n', limits[limitType].number) #"Too many "+limitType+" contents: "+data.length+" of "+limits[limitType].number+"."
#                 )

#             if post.scheduled #, то смотрим исключения
#                 community = communityService.getCommunityById post.communityId
#                 exception = limits[limitType].exceptions?[community.type]
#                 if exception
#                     if data.length > exception.number then errorMessages.push( localization.translate('readyToSchedule_typeException')
#                         .replace('%s', localization.translate('readyToSchedule_contentTypes')[postData.types[0]])
#                         .replace('%t', localization.translate('readyToSchedule_communityTypes')[community.type])
#                         .replace('%n', exception.number)
#                     )
#                     #"Too many contents of "+limitType+" exception."

#         #В любом случае пробегаем по контенту на наличие лимитов, чтобы потом выдать ошибки одним списком
#         textLength = 0
#         for item in data
#             switch item.type
#                 when "image"
#                     if !limits.imagesLimit.supportsAnimated
#                         if item.animated
#                             errorMessages.push( localization.translate("readyToSchedule_animations") ) #"This social network is not supports animated pictures."
#                 when "audio"
#                     if !(limits.audiosLimit.supportedSources?.indexOf(item.sourceType)+1)
#                         errorMessages.push( localization.translate("readyToSchedule_audioSource")
#                             .replace('%a', item.artist)
#                             .replace('%t', item.title)
#                         ) #"unsupported audio source of "+item.artist+" – "+item.title
#                 when "video"
#                     if !(limits.videosLimit.supportedSources?.indexOf(item.sourceType)+1)
#                         errorMessages.push( localization.translate("readyToSchedule_videoSource")
#                             .replace('%t', item.title)
#                         ) #"unsupported video source of "+item.title
#                 when "text"
#                     textLength += item.value.length

#         if textLength > limits.textLength
#             errorMessages.push( localization.translate("readyToSchedule_longText")
#                 .replace('%n', limits.textLength)
#             )

#         if errorMessages.length
#             blog "Post is not ready:", errorMessages
#             errorText = localization.translate("readyToSchedule_main")
#             for i in errorMessages
#                 errorText += "<br>◕"+i
#             errorText += "<br>" + localization.translate("readyToSchedule_footer")

#             #if !notificationCenter then notificationCenter = $injector.get 'notificationCenter'
#             notificationService.addMessage
#                 realText: errorText
#                 error: true

#             post.readyToSchedule = false
#             errorMessages.length = 0


#     {
#         purge
#         getPostById

#         saveNewPost
#         savePost

#         addPost

#         deletePostCache
#         deletePostCacheById

#         fetchPostsByQuery
#         fetchServerPosts

#         checkPostReadyToSchedule
#         doFetchPostsByIds
#     }