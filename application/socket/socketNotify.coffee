buzzlike.service 'socketNotify', (notificationCenter, socketService, $rootScope, account, localization) ->

    class socketNotify

        constructor: ->
            return
            socketService.on 'push', (data) ->

                message = 
                    time: 30 * SEC
                    solid: true

                switch data.type
                    when 'repostRequest'
                        message.item =
                            type: 'community'
                            id: data.data.communityId
                        
                        message.realText = 'Новая заявка на размещение рекламы.'
                        if data.data.cost > 0
                            message.realText += ' Стоимость размещения: ' + data.data.cost + 'р.'

                    when 'returnRequest'
                        message.item =
                            type: 'lot'
                            id: data.data.lotId
                        
                        message.realText = 'Встречное предложение по вашей заявке.'
                        if data.data.cost > 0
                            message.realText += ' Стоимость размещения: ' + data.data.cost + 'р.'

                    when 'acceptRequest'
                        message.item =
                            type: 'lot'
                            id: data.data.lotId
                        
                        message.realText = 'Размещение рекламы в сообщество "' + data.data.communityTitle + '" одобрено!'
                        if data.data.cost > 0
                            message.realText += ' Стоимость размещения: ' + data.data.cost + 'р.'

                    when 'rejectRequest'
                        message.item =
                            type: 'lot'
                            id: data.data.lotId
                        
                        message.realText = 'Размещение рекламы в сообщество "' + data.data.communityTitle + '" отклонено.'
                    
                    # Moderation
                    when 'acceptLot'
                        message.item =
                            type: 'lot'
                            id: data.data.lotId
                        
                        message.realText = 'Размещение рекламы в маркет одобрено.'

                    when 'rejectLot'
                        message.item =
                            type: 'lot'
                            id: data.data.lotId
                        
                        message.realText = 'Размещение рекламы в маркет отклонено.'
                        message.realText += ' Причина: ' + data.data.status + '.'
                    
                    # Posting error
                    when 'postingError'
                        message.item =
                            type: 'post'
                            id: data.data.postId
                        
                        message.realText = 'Пост на ' + data.data.timestamp + ' не вышел (.'
                        message.realText += ' Причина: ' + localization.translate('posting_error_' + data.data.error.error)['caption'] + '.'
                    

                notificationCenter.addMessage message
                $rootScope.$apply()


    new socketNotify()