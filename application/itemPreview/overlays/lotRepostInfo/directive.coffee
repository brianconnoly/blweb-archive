buzzlike.directive "lotRepostInfo", (contentService, communityService, scheduleService, $filter, localization, requestService, $rootScope) ->
    restrict: "C"
    scope:
        post: "="
        lot: "="
        status: "="
    template: tC['/itemPreview/overlays/lotRepostInfo']
    link: (scope, element, attrs) ->
        elem = $ element
        id = scope.post.id #post id
        sched = scope.$parent.$parent.$parent.sched or {}
        #blog "INIT INFO", id, scope.post, scope.lot, scope

        scheduleService.getOriginalByPostId id, (originalSched) ->
            #blog "GOT SCHED", originalSched
            if !originalSched then return true

            communityService.getById originalSched.communityId, (community) ->
                #blog "GOT COMM", community
                img = elem.find('img.communityIcon')[0]
                if community.id == sched.communityId            # если это оригинальный пост
                    img.src = '/resources/images/timeline/market-logo@2x.png'    # ставим аватарку маркета
                else
                    img.src = community.photo #|| '/resources/images/icons/timeline-empty-avatar.png'
                #выравнивание аватарки в блоке
                img.onload = ->
                    size = elem.height()
                    imageIn @, size, size

                scheduleId = sched.id or originalSched.id
                requestService.query {scheduleId}, (data) ->
                    #blog "GOT REQS", data, sched.id
                    request = data[0]

                    if scope.lot.buzzLot == true
                        cost = humanizeDays scope.lot.price
                    else
                        cost = request?.cost or scope.lot.price
                        cost = $filter('formatNumber')(cost) + ' ' + localization.translate('currency_rub')
                    
                    elem.find('.info').html cost 

                    # status
                    statusView = elem.find '.status'
                    statusView.addClass scope.status if scope.status

                    if scope.status == 'socialNetwork'
                        statusView.find('.bgColor').css background: $rootScope.networksData[community.socialNetwork].background
                        statusView.find('.icon').html community.socialNetwork

                    else if scope.status == 'requestStatus' and request
                        statusView.find('.bgColor').addClass 'active'
                        statusView.find('.icon').addClass request.requestStatus




        true
