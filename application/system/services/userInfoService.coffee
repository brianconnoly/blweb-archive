buzzlike.service 'userInfo', (env, httpWrapped) ->

    # Кэш сервиса
    allUsers = {}

    # Кладет новые объекты в кэш
    # Обновляет существующие
    handleUserInfo = (item) ->
        if allUsers[item.id]?
            updateObject allUsers[item.id], item
        else
            allUsers[item.id] = item
        allUsers[item.id]

    # Возвращает объект информации если он уже загружен
    # Если в кэше нет - возвращает false
    # Если нужно - запрашивает с back-end'а
    # В cb всегда передаёт объект
    getUserInfoById = (id, cb) ->
        if allUsers[id]?
            cb? allUsers[id]
            return allUsers[id]
        else
            httpWrapped.get env.baseurl + '/user/' + id, (result) ->
                newUserInfo = handleUserInfo result
                cb? newUserInfo
                true
            false

    {   
        allUsers
        getUserInfoById
    }