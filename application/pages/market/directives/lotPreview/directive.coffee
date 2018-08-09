# BuzzLike.Market
# Директива для того чтобы по-разному отображать разные типы лотов

# Генерируется блок с директивой нужного отображения, компилируется
# и вставляется внутрь родительского блока.

buzzlike.directive 'lotPreview', ($compile, lotService, operationsService) ->
    restrict: 'C'
    link: (scope, element, attrs) ->
        elem = $ element
        lot = scope.item

        if !lot?
            return

        previewDirective = null

        # Выбор нужной директивы 
        # для отображения по типу лота
        switch lot.lotType
            when 'post', 'repost'
                previewDirective = 'lotPostPreview'
            when 'content'
                previewDirective = 'lotContentPreview'

        scope.showPreview = (e) ->
            e.preventDefault()
            e.stopPropagation()

            true

        # Если нашли подходящее отображение - собираем
        # превью и вставляем в родительский элемент
        if previewDirective?
            preview = $compile('<div class="'+previewDirective+' innerPreview" ng-dblclick="showPreview($event)"></div>')(scope)

            elem.append preview