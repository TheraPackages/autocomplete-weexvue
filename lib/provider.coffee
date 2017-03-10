fs = require 'fs'
path = require 'path'

###
辅助函数，查看scope
###
hasScope = (scopesArray, scope) ->
  scopesArray.indexOf(scope) isnt -1

module.exports =
  selector: '.source.we'
  disableForSelector: '.source.we .source.css, .source.we .source.js, .source.we .comment'

  # 启用模糊匹配模式
  filterSuggestions: true

  # 公共属性
  commonProperties: null

  # Tag
  tags: null

  ###
  # 向前和向后看一个字符
  ###
  lookBack: null
  lookAhead: null

  getCharAt: (editor, pos) ->
    editor.getTextInRange([pos, ([pos.row, pos.column + 1])])

  ###
  # 计算lookBack lookAhead 向前向后看一个字符
  ###
  calculateLookBackAndLookAhead: (request) ->
    pos = request.bufferPosition
    posBefore =
      row: pos.row
      column: pos.column - 1
    posAfter = pos

    @lookBack = @getCharAt request.editor, posBefore
    @lookAhead = @getCharAt request.editor, posAfter

  # 重新计算前缀
  recalculatePrefix: (request) ->
    line = request.editor.getTextInRange([[request.bufferPosition.row, 0], request.bufferPosition])
    wsIndex = line.lastIndexOf ' '
    tabIndex = line.lastIndexOf '\t'
    lt = line.lastIndexOf '<'
    gt = line.lastIndexOf '>'

    # 分解符
    sp = Math.max(Math.max(wsIndex, tabIndex), gt)

    if request.bufferPosition.column > 0
      @lookBack = line[request.bufferPosition.column - 1]
    else
      @lookBack = null

    if sp > lt
      return line.substr sp + 1
    else if lt != -1
      return line.substr lt
    line

  ###
  # 处理前缀字符串
  ###
  resolvePrefix: (prefix) ->
    prefix = prefix.substr(1) if prefix[0] == '<'
    prefix

  buildPropertyNameCompletion: (property, prefix, internalPrefix) ->
    type: 'property'
    text: property
    replacementPrefix: prefix
    internalReplacementPrefix: internalPrefix
    displayText: property
    internalSnippet: "#{property}=\"${0}\""
    description: "" # 描述暂时为空
    descriptionMoreURL: "" # 这里估计要链接到 weex site

  buildTagCompletion: (tag, prefix, internalPrefix) ->
    result =
      rightLabel: 'weex-tag-' + tag
      type: 'tag'
      text: tag
      replacementPrefix: prefix
      internalReplacementPrefix: internalPrefix
      displayText: tag
      internalSnippet: "<#{tag}>${0}</#{tag}>"
      description: "Weex Tags for <#{tag}> elements"

  ###
  # 用于处理Weex标签的名称
  ###
  getWeexTagNameCompletions: (request) ->
    internalPrefix = @recalculatePrefix request
    request.prefix = @resolvePrefix internalPrefix
    if request.prefix == '<'
      request.prefix = '' # [''] represents for all weex-tags

    return null unless request.prefix or internalPrefix
    (@buildTagCompletion tag, request.prefix, internalPrefix) for tag in @tags

  ###
  # 用于处理Weex标签内部的属性的名称
  ###
  getWeexTagPropertyNameCompletions: (request) ->
    arr = []
    internalPrefix = @recalculatePrefix request
    request.prefix = @resolvePrefix internalPrefix
    if request.prefix == '<'
      request.prefix = '' # [''] represents for all weex-tags
    for {name, values} in @commonProperties
      arr.push (@buildPropertyNameCompletion name, request.prefix, internalPrefix)
    arr

  ###
  # 用于处理类似 < > 之类符号的相邻位置，临界点需要做【向前】和【向后】看一个字符
  ###
  aroundPunctuation: (request) ->
    completions = null
    if @lookBack == '<'
      completions = @getWeexTagNameCompletions request
    else if @lookBack == '>'
      # NOTE do nothing
    else
      completions = @getWeexTagPropertyNameCompletions request
    completions

  ###
  # 模块主入口函数 getSuggestions
  ###
  getSuggestions: (request) ->
    @calculateLookBackAndLookAhead request
    completions = null
    scopes = request.scopeDescriptor.getScopesArray()
    console.log scopes
    if hasScope scopes, "string.quoted.double.html"
      # 属性值
    else if hasScope scopes, "meta.tag"
      # 标签内部的属性名称字符串
      if hasScope scopes, "entity.name.tag.structure.any.html"
        # 完整标签
        completions = @getWeexTagNameCompletions request
      else if hasScope scopes, "punctuation.definition.tag.html" # 临界点
        completions = @aroundPunctuation request
      else
        completions = @getWeexTagPropertyNameCompletions request
    else
      completions = @getWeexTagNameCompletions request
    completions

  onDidInsertSuggestion: ({editor, suggestion}) ->
    setTimeout(@triggerAutocomplete.bind(this, editor), 1) if suggestion.type is 'property'

  triggerAutocomplete: (editor) ->
    atom.commands.dispatch(atom.views.getView(editor), 'thera-autocomplete-plus-plus:activate', {activatedManually: false})

  loadProperties: ->
    @commonProperties = []
    @tags = []
    fs.readFile path.resolve(__dirname, '..', 'weex-completions.json'), (error, content) =>
      {@commonProperties, @tags} = JSON.parse(content) unless error?
      return
