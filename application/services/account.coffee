buzzlike
    .service('account', (env, rpc, socketService, browserPopup, localization, $injector) ->
        user = {}
        emptyUser =
            loaded: false
            id: -1
            name: ''
            firstName: ''
            lastName: ''
            login: ''
            accounts: []
            timezone: new Date().getTimezoneOffset()/-60

        purge = () ->
            emptyObject user
            updateObject user, emptyUser
        purge()

        desktopService = null


        # --- charge block ---
        class Charge
            @min: 50
            @max: 10000
            @currentAmount: 0

            @checkAmount: (amount) =>
                if @min <= amount <= @max
                    @currentAmount = amount
                    @showOffer()
                else
                    @enterAmount()

            @enterAmount: ->
                if !desktopService? then desktopService = $injector.get 'desktopService'
                desktopService.launchApp 'customPayment'

            @showOffer: ->
                if !desktopService? then desktopService = $injector.get 'desktopService'
                desktopService.launchApp 'paymentOffer',
                    type: 'charge'

            @makeOrder: (order) ->
                amount = (@currentAmount | 0).toFixed 2
                popup = null
                statuses =
                    'OK': ->
                        $(popup.document.body).html templateCache["/static/paymentSuccess"]
                        $(popup.document.body).find("button").click -> popup.close()
                        setTimeout ->
                            popup.close()
                        , 30000

                    'FAIL': ->
                        $(popup.document.body).html templateCache["/static/paymentFail"]
                        $(popup.document.body).find("button").click -> popup.close()
                        setTimeout ->
                            popup.close()
                        , 30000

                order = order or {}
                defaultOrder =
                    amount: amount
                    paymentType: 'direct'
                    source: 'uniteller'

                order = updateObject {}, defaultOrder, order


                rpc.call 'payment.order', order, (item) ->
                    paymentURL = location.origin + "/static/payment.html?hash=" + Date.now()
                    popup = browserPopup.open paymentURL, {width: 924}

                    if popup
                        popup.paymentParams = item.paymentParams
                        popup.paymentUrl = item.paymentUrl

                        browserPopup.waitResponse popup, statuses

                true


        # --- prolong block ---
        class Prolong
            @currentPrice: null
            @checkAmount: (price, cb) ->
                @currentPrice = price
                confirmBox = $injector.get 'confirmBox'

                if user.amount < price.amount
                    #alert 'charge your acc on '+(price.amount-user.amount)
                    message = localization.decrypt 'userOptions_prolong_charge',
                        amount: price.amount - user.amount

                    confirmBox.init
                        realText: message
                    , =>
                        @charge cb

                else #allright
                    confirmBox.init
                        realText: 'Продлить использование?'
                    , =>
                        @prolong cb

            @prolong: (cb) ->
                if !@currentPrice then return false

                rpc.call 'user.prolongByAccount', @currentPrice.value, (res) ->
                    update cb || undefined

            @charge: (cb) ->
                Charge.checkAmount @currentPrice.amount-user.amount




        renew = (updated, cb) ->
            if !updated then return cb? user
            updateObject user, updated,
                currentLogin: updated.login
                loaded: true

            user.name = joinStrings [user.firstName, user.lastName]

            if updated.expiredDate
                user.daysRemain = Math.ceil( (updated.expiredDate - Date.now()) / DAY )
                if user.daysRemain < 0 then user.daysRemain = 0

            cb? user

        update = (data, cb) ->
            if typeof data == 'function'
                cb = data
                data = null

            if data
                renew data, cb
            else
                rpc.call 'user.getUser', (data) -> if !data.err then renew data, cb else blog "ACC_UPD_GET_ERR", data

        set = (data, cb) ->
            rpc.call 'user.set', data, (data) -> if !data.err then renew data, cb else blog "ACC_SET_ERR", data

        cbs = []
        onAuthed = (cb) ->
            if user.loaded == false
                cbs.push cb
            else 
                cb? true

        authed = () ->
            for cb in cbs
                cb? true
            cbs.length = 0

        flushUser = ->
            emptyObject user

        {
        user
        flushUser
        update
        set

        purge

        Charge
        Prolong

        authed
        onAuthed
        }
    )
    .service 'paymentService', (operationsService) ->
        payments = {}

        init = ->
            true

        purge = () ->
            emptyObject payments

        handlePayment = (payment) ->
            cached = payments[payment.id]

            if cached?
                updateObject payments[payment.id], payment
            else
                payments[payment.id] = payment
            payments[payment.id]

        operationsService.registerAction 'create', 'payment', (id, data) ->
            handlePayment data.entity
            true

        operationsService.registerAction 'update', 'payment', (id, data) ->
            handlePayment data.entity
            true

        operationsService.registerAction 'get', 'payment', (id) ->
            payments[id]



