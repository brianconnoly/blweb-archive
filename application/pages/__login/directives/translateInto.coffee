buzzlike.directive "translateIntoEnglish", ->
    link: (scope, element, attrs) ->
        elem = $ element
        attr = attrs.translateIntoEnglish
        type = element[0].type

        switch attr
            when 'email'
                regexp = /([^a-zA-Z@\.\d])/g
                specials = [
                    "@\"", ".ю", "-", "_", "^", "*", "&", "$", "!", "?", "=", "%", "+"
                ]
            when 'password'
                regexp = /([^a-zA-Z\d])/g
                specials = [
                    "<Б", ">Ю", ",б", "!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "-", "=",
                    "_", "+", "№", ":", ";"
                ]

            else
                regexp = /([^a-zA-Z\d])/g
                specials = []

        equals = [
            "qй", "wц", "eу", "rк", "tе", "yн", "uг", "iш", "oщ", "pз",
            "aф", "sы", "dв", "fа", "gп", "hр", "jо", "kл", "lд",
            "zя", "xч", "cс", "vм", "bи", "nт", "mь"
        ]

        isUpperCased = (char) ->
            if char == char.toUpperCase() then true else false

        element[0].type = 'text' if type == 'email'  #troubles with email encoding international domains

        elem.on 'input propertychange', (e) ->
            selectionStart = this.selectionStart
            startLength = this.value.length

            this.value = this.value.replace /\s/g, "" #delete spaces
            this.value = this.value.replace regexp, (char) ->  #include any symbol except english letters, point and digits
                newChar = ''
                if specials.length
                    for i in specials
                        if i.indexOf(char)+1
                            newChar = i[0]
                            break
                else
                    newChar = char

                for i in equals
                    if i.indexOf(char.toLowerCase())+1
                        newChar = i[0]
                        break

                if newChar and isUpperCased(char)
                    newChar = newChar.toUpperCase()

                return newChar

            pos = selectionStart + this.value.length - startLength
            if pos < 1 then pos = this.value.length
            this.selectionStart = this.selectionEnd = pos #return cursor back to previous position


buzzlike.directive 'allowSymbols', () ->
    restrict: "AC"
    require: "ngModel"
    link: (scope, element, attrs, ctrl) ->
        elem = $ element
        attr = attrs.allowSymbols
        regexp = new RegExp "[^"+attr+"]", 'g'

        elem.on 'input propertychange', (e) ->
            selectionStart = this.selectionStart
            startLength = this.value.length

            this.value = this.value.replace regexp, "" #delete symbols

            pos = selectionStart + this.value.length - startLength
            if pos < 1 then pos = this.value.length
            this.selectionStart = this.selectionEnd = pos #return cursor back to previous position

            ctrl.$setViewValue this.value

        ctrl.$render = () ->
            elem.val ctrl.$viewValue