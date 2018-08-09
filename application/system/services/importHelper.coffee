buzzlike.factory('importHelper', ['env','httpWrapped',(env, httpWrapped) ->
    prepareUrlImport : (url, cb)->
        httpWrapped.post env.baseurl + "/import/url", url, cb
    prepareVideoImport : (url, cb)->
        httpWrapped.post env.baseurl + "/import/video", url, cb
])