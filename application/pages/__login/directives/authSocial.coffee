buzzlike
    .directive "authSocial", (user, env, socketAuth, $location, $state, $rootScope, popupService, localization, localStorageService) ->
        ($scope, element, attrs) ->

            element.bind 'click', () ->
                element[0].disabled = true
                url = env.baseurl + 'auth/snauth/' + attrs.authSocial +
                    '?sid=' + localStorageService.get('sid')
                window.www = url

                $rootScope.regData = {username: $scope.$parent.username} #сохраняем почту, чтобы отобразить во время регистрации

                # ------- auth popup
                popup = popupService.open location.origin+'/static/login.html?hash='+Date.now(),
                    caption: localization.translate('userOptions_updateAccount')
                    width: 671
                popup.color = $rootScope.networksData[attrs['authSocial']].background

                popup.onload = -> 
                    popup.location.href = url
                # -------

                setTimeout ->
                    element[0].disabled = false
                , 1111

                statuses =
                    'AUTH_OK': ->
                        popup.close()
                        socketAuth.fetchSession()
                        $scope.$apply()
                    'REGISTER': ->
                        popup.close()
                        $scope.$parent.screen = 'new-social'
                        $scope.$apply()
                    'FAIL': ->
                        body = $(popup.document.body)
                        body.html templateCache["/static/updateFail"]
                        query = location.getQuery popup.document?.location
                        body.find(".error").html query.error
                        body.find("button").click -> popup.close()
                        setTimeout ->
                            popup.close()
                            element[0].disabled = false
                        , 300000

                    # ?_?
                    'CLOSE': ->
                        $(popup.document.body).find("img").click -> popup.close()
                        setTimeout ->
                            popup.close()
                            element[0].disabled = false
                        , 30000

                popupService.waitResponse popup, statuses