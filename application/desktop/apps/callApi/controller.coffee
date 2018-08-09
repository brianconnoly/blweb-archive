buzzlike.controller 'callApiCtrl', ($scope, account, rpc) ->

    $scope.session.expandedHeader = false

    $scope.api = [
        # user controller
        title: 'user'
        methods: [
            title: 'fillBalance'
            type: 'rpc' #?
            dataValue: 'amount' # передаётся только значение указанного поля
            fields: [
                key: 'amount'
                value: 0
                type: 'number' # input type
            ]
        ,
            title: 'getAccounts'
            type: 'rpc' #?
        ,
            title: 'getByLogin'
            type: 'rpc' #?
            fields: [
                key: 'login'
                value: ''
            ]

        ]

    ,
        # ... controller
        title: '...'
        methods: []

    ]

    $scope.request =
        userId: account.user.id
        apiKey: ""

    # current
    $scope.current =
        controller: 
            title: 'simpleApi'
            methods: [
                title: 'create'
                fields: [
                    key: 'text'
                    value: ""
                    type: 'text' # input type
                ,
                    key: 'attachments'
                    value: ""
                    type: 'text'
                ,
                    key: 'timestamp'
                    value: Date.now() + 1 * MIN
                    type: 'number'

                ,
                    key: 'communityId'
                    value: ""
                    type: 'text'
                ,
                    key: 'communityType'
                    value: "group"
                    type: 'text'
                ,
                    key: 'socialNetwork'
                    value: "ok"
                    type: 'text'

                ,
                    key: 'accessToken'
                    value: ""
                    type: 'text'
                ,
                    key: 'refreshToken'
                    value: ""
                    type: 'text'

                ,
                    key: 'appId'
                    value: ""
                    type: 'text'
                ,
                    key: 'appKey'
                    value: ""
                    type: 'text'
                ,
                    key: 'appSecret'
                    value: ""
                    type: 'text'
                ]
            ,
                title: 'update'
                fields: [
                        key: 'id'
                        value: ""
                        type: 'text' # input type
                    ,

                        key: 'text'
                        value: ""
                        type: 'text' # input type
                    ,
                        key: 'attachments'
                        value: ""
                        type: 'text'
                    ,
                        key: 'timestamp'
                        value: Date.now()*1 + 1 * MIN
                        type: 'number'

                    ,
                        key: 'communityId'
                        value: ""
                        type: 'text'
                    ,
                        key: 'communityType'
                        value: "group"
                        type: 'text'
                    ,
                        key: 'socialNetwork'
                        value: "ok"
                        type: 'text'

                    ,
                        key: 'accessToken'
                        value: ""
                        type: 'text'
                    ,
                        key: 'refreshToken'
                        value: ""
                        type: 'text'

                    ,
                        key: 'appId'
                        value: ""
                        type: 'text'
                    ,
                        key: 'appKey'
                        value: ""
                        type: 'text'
                    ,
                        key: 'appSecret'
                        value: ""
                        type: 'text'
                ]
            ,
                title: 'delete'
                fields: [
                    key: 'id'
                    value: ""
                    type: 'text' # input type
                ]
            ,
                title: 'get'
                fields: [
                    key: 'id'
                    value: ""
                    type: 'text' # input type
                ]
            ,
                title: 'list'
                fields: [
                    key: 'status'
                    value: 'planned'
                    type: 'text'
                ,
                    key: 'page'
                    value: 0
                    type: 'number'
                ]
            ]
        method: null
    $scope.fields = null
    $scope.result = 'Result will be here.'

    $scope.setMethod = ->
        $scope.current.method = null
        $scope.current.method = $scope.current.controller.methods[0] if $scope.current.controller.methods?[0]
        $scope.setFields()
        true

    $scope.setFields = ->
        if !$scope.current.method then return false
        if !$scope.current.method.fields then $scope.current.method.fields = []
        $scope.fields = $scope.current.method.fields
        true

    $scope.addField = ->
        $scope.fields.push
            key: 'key'
            value: 'value'
            editable: true
        true

    $scope.deleteField = (field) ->
        removeElementFromArray field, $scope.fields
        true

    $scope.call = ->
        data = {}
        for field in $scope.fields
            k = field.key
            v = field.value
            data[k] = v

        data.userId = $scope.request.userId
        data.apiKey = $scope.request.apiKey

        data.showErrors = true

        if $scope.current.method.dataValue? then data = data[$scope.current.method.dataValue]

        process = $scope.progress.add()
        rpc.call $scope.current.controller.title + "." + $scope.current.method.title, data, (res) ->
            if !res 
                $scope.result = 'No result'
                return

            try 
                $scope.result = JSON.stringify res, null, 4
            catch e
                $scope.result = res

            $scope.progress.finish process

        true

    # $scope.parseCallResult = ->
    #     res = $scope.result
    #     if !res then return 'No result'

    #     if typeof res == 'object'
    #         res = JSON.stringify res, null, 4

    #     res

    $scope.selectAll = ->
        resNode = $('#result')[0]
        if document.body.createTextRange # ms
            range = document.body.createTextRange()
            range.moveToElementText resNode
            range.select()
        else if window.getSelection # moz, opera, webkit
            selection = window.getSelection()
            range = document.createRange()
            range.selectNodeContents resNode
            selection.removeAllRanges()
            selection.addRange range
        true

    true