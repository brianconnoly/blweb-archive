buzzlike.factory "localization", (localStorageService, $http, $rootScope) ->
    list = {}
    lang = 'ru'
    languageslist = []
    count = 0
    undefinedWords = []
    pullTimer = {}
    updateComplete = false
    langversion = 0

    langInited = false
    initCb = []

    state = 
        lang: 'ru'
        ver: 0

    flagInited = ->
        langInited = true
        for cb in initCb
            cb?()
        initCb.length = 0

    getFreshList = (force) ->
        $http({ method: 'GET', url: '//translate.buzzlike.pro/back/getlanguages' })
            .success (data, status, header, config) ->
                languageslist = []
                for item in data.list
                    if item.active
                        languageslist.push
                            value: item.code
                            title: item.title
                    if item.code == lang
                        langversion = item.version

                $rootScope.languageslist = languageslist

                if Math.floor(langversion) != Math.floor(localStorageService.get 'user.langlistversion') || force == true
                    localStorageService.add 'user.langlistversion', langversion
                    requestToTranslateServer()
                else
                    if localStorageService.get 'user.langlist'
                        list = JSON.parse(localStorageService.get 'user.langlist')
                        flagInited()
                        listCount()
                        state.ver = langversion
                    else
                        requestToTranslateServer()

    requestToTranslateServer = ->
        $http({ method: 'GET', url: '//translate.buzzlike.pro/back/getjsonlist/'+lang })
            .success (data, status, header, config) ->
                # Если ошибка или доступ к этому языку отключен, тогда запрашиваем 'en' по умолчанию
                if data.error
                    lang = 'en'
                    requestToTranslateServer()
                else
                    for item in data
                        list[item.code] = item.words
                        translate(item.code)

                    localStorageService.add 'user.langlist', JSON.stringify(list)
                    flagInited()
                    listCount()

                    state.ver = langversion

    listCount = ->
        count = 0
        for key, value of list
            count++

    getLang = ->
        if !localStorageService.get 'user.lang'
            setLang 'ru'
        else
            setLang localStorageService.get 'user.lang'

    setLang = (lang_v) ->
        lang = lang_v
        state.lang = lang_v

    translate = (wordIndex, templateData) ->
        word = ''
        wordIndex += ''

        if wordIndex == '' or !wordIndex?
            return ''
        else
            if !$.isEmptyObject list

                word = list[wordIndex]

                newWords = false
                if typeof word == 'undefined'
                    console.log wordIndex, !!wordIndex
                if typeof word == 'undefined' and !!wordIndex
                    if $.inArray(wordIndex, undefinedWords) == -1
                        re = /\s+/gi
                        if !re.test(wordIndex)
                            newWords = true
                            
                            list[wordIndex] = wordIndex
                            undefinedWords.push wordIndex
                            blog 'undefined word - ', wordIndex

                if newWords
                    clearTimeout(pullTimer)
                    pullTimer = setTimeout ->
                        # Не получилось использовать $http т.к. он зацикливается в setTimeout
                        if undefinedWords? and undefinedWords.length > 0
                            $.ajax
                                url: '//translate.buzzlike.pro/back/addnew'
                                type: 'POST'
                                data: { list: undefinedWords }
                                dataType: 'JSON'
                                success: (data) ->
                                    undefinedWords.length = 0
                                    true
                    , 1500

        if word? and templateData?
            searchString = ''
            lib = {}
            for k,v of templateData
                searchString += '|' if searchString != ''
                searchString += '%' + k + '%'
                lib['%' + k + '%'] = v

            if searchString.length > 0
                search = new RegExp searchString, 'g'
                word = word.replace search, (mem) -> lib[mem]

        word or wordIndex

    declension = (number, one, two, five) ->
        number = Math.abs number

        if !two and !five and typeof one == 'string'
            s = one
            o = translate(s)
            [one, two, five] = o

        if !two and !five
            two = one[1]
            five = one[2] or one[1]

        number %= 100
        if (number >= 5 and number <= 20)
            return five;

        number %= 10;
        if (number == 1)
            return one;

        if (number >= 2 and number <= 4)
            return two;

        return five;

    declensionPhrase = (number, phrase) ->
        word = translate phrase
        declension number, word[0], word[1], word[2]

    decrypt = (wordIndex, data) ->
        str = translate wordIndex
        for k, v of data
            reg = new RegExp('#{'+k+'}', 'g')
            str = str.replace reg, v
        str

    getLangList = ->
        languageslist

    onLangLoaded = (cb) ->
        if langInited == true
            cb? true
        else
            initCb.push cb

    #return
    {
    getList: -> list
    state

    setLang

    getLang
    getFreshList
    getLangList

    translate
    declension
    declensionPhrase
    decrypt

    onLangLoaded
    }