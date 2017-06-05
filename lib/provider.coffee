{BufferedProcess, Point} = require 'atom'
{CompositeDisposable} = require 'atom'
fs = require 'fs'
path = require 'path'
parse = require './x-bridge'

###
辅助函数，查看scope
###
hasScope = (scopesArray, scope) ->
  scopesArray.indexOf(scope) isnt -1

makePrefix = (str, c) ->
  i = str.lastIndexOf c
  str = str.substr (i + 1) if i != -1
  return str

attrReg = (prefix) ->
  i = prefix.indexOf ':'
  if i is -1
    return [prefix, null, null]

  attr = prefix.substring 0, i
  r = prefix.substring i + 1

  i = r.indexOf '.'
  arg = null
  modifier = null

  if i is -1
    arg = r
  else
    arg = r.substring 0, i
    modifier = r.substring i + 1

  return [attr, arg, modifier]

isEmpty = (s) ->
  return s == "" or s == null or s == undefined

module.exports =
  selector: '.source.weexvue'
  disableForSelector: '.source.weexvue .source.css, .source.weexvue .source.js, .source.weexvue .comment'

  # 启用模糊匹配模式
  filterSuggestions: true

  # 公共属性
  commonProperties: null
  vue: null
  triggerStat: false
  subscriptions: new CompositeDisposable()

  # Tag
  tags: null

  buildWeexVuePropertyNameCompletion: (property, prefix, internalPrefix) ->
    inSnippet = "#{property.name}=\"${0}\""
    if property.snippet
      inSnippet = property.snippet

    ret =
      iconHTML: "<span class=\"icon weexvue-icon-container\"><img class=\"weexvue-icon\" src=\"atom://autocomplete-weexvue/styles/weexvue-new.png\"></span>"
      type: 'vue'
      text: property.name
      replacementPrefix: prefix
      internalReplacementPrefix: internalPrefix
      displayText: property.name
      internalSnippet: inSnippet
      description: "" # 描述暂时为空
      descriptionMoreURL: "" # 这里估计要链接到 weex site

  buildWeexVuePropertyModifierNameCompletion: (modifier, prefix, internalPrefix, snippet) ->
    iconHTML: "<span class=\"icon weexvue-icon-container\"><img class=\"weexvue-icon\" src=\"atom://autocomplete-weexvue/styles/weexvue-new-modifier.png\"></span>"
    type: 'vue'
    text: modifier
    replacementPrefix: prefix
    internalReplacementPrefix: internalPrefix
    displayText: modifier
    internalSnippet: snippet # "#{arg}=\"${0}\""
    description: "" # 描述暂时为空
    descriptionMoreURL: "" # 这里估计要链接到 weex site

  buildWeexVuePropertyArgNameCompletion: (arg, prefix, internalPrefix, snippet) ->
    iconHTML: "<span class=\"icon weexvue-icon-container\"><img class=\"weexvue-icon\" src=\"atom://autocomplete-weexvue/styles/weexvue-new-arg.png\"></span>"
    type: 'vue'
    text: arg
    replacementPrefix: prefix
    internalReplacementPrefix: internalPrefix
    displayText: arg
    internalSnippet: snippet # "#{arg}=\"${0}\""
    description: "" # 描述暂时为空
    descriptionMoreURL: "" # 这里估计要链接到 weex site

  buildPropertyEventNameCompletion: (event, prefix, internalPrefix) ->
    iconHTML: "<span class=\"icon weexvue-icon-container\"><img class=\"weexvue-icon-event\" src=\"atom://autocomplete-weexvue/styles/weexvue-new-event.png\"></span>"
    type: 'event'
    text: event
    replacementPrefix: prefix
    internalReplacementPrefix: internalPrefix
    displayText: event
    internalSnippet: "#{event}=\"${0}\""
    description: "" # 描述暂时为空
    descriptionMoreURL: "" # 这里估计要链接到 weex site

  buildPropertyNameCompletion: (property, prefix, internalPrefix) ->
    type: 'property'
    text: property
    replacementPrefix: prefix
    internalReplacementPrefix: internalPrefix
    displayText: property
    internalSnippet: "#{property}=\"${0}\""
    description: "" # 描述暂时为空
    descriptionMoreURL: "" # 这里估计要链接到 weex site

  ###
  # tag, attr, value
  # iconHTML: "<span class=\"icon-letter\">g</span>"
  ###
  buildPropertyValueCompletion: (tag, attr, value, prefix, internalPrefix, needQuoted, activeDoc = null) ->
    # 用于补全的地方
    if needQuoted
      internalSnippet = "\"" + value + "\" ${0}"
    else
      internalSnippet = value

    result =
      rightLabel: "weexvue-#{tag}-#{attr}-" + value
      type: 'value'
      text: value
      replacementPrefix: prefix
      internalReplacementPrefix: internalPrefix
      displayText: value
      internalSnippet: internalSnippet
      activeDoc: activeDoc
      description: "Attribute value \'#{value}\' for attribute \'#{attr}\' in \'#{tag}\' tag.(weexvue2.0)"
      # activeDoc: """
      # <br/>
      # <pre>
      # <code class='lang-css'>.dwdw {
      #   background-color: red;
      # }</code>
      # </pre>
      # """

    result

  attributePrefix: (request) ->
    line = request.editor.getTextInRange([[request.bufferPosition.row, 0], request.bufferPosition])

  vue2_0: ->
    ret= [
      {
        name: "v-text",
        snippet: null
      },
      {
        name: "v-html",
        snippet: null
      },
      {
        name: "v-once",
        snippet: null
      },
      {
        name: "v-if",
        snippet: null
      },
      {
        name: "v-show",
        snippet: null
      },
      {
        name: "v-else",
        snippet: null
      },
      {
        name: "v-for",
        snippet: null
      },
      {
        name: "v-on",
        snippet: "v-on:${0}"
      },
      {
        name: "v-bind",
        snippet: "v-bind:${0}"
      },
      {
        name: "v-model",
        snippet: null
      },
      {
        name: "v-ref",
        snippet: null
      },
      {
        name: "v-el",
        snippet: null
      },
      {
        name: "v-pre",
        snippet: null
      },
      {
        name: "v-cloak",
        snippet: null
      }
    ]

  buildTagCompletionVue: (tag, prefix, internalPrefix) ->
    result =
      rightLabel: 'weex-tag-' + tag
      type: 'tag'
      text: tag
      replacementPrefix: prefix
      internalReplacementPrefix: internalPrefix
      displayText: tag
      internalSnippet: "<#{tag}>${0}</#{tag}>"
      description: "Weex Vue2.0 Tags for <#{tag}> elements"
    result

  buildTagAutoCloseTag: (editor, tag, point) ->
    if tag != "root"
      editor.insertText('</' + tag + '>')
      editor.setCursorBufferPosition point

  getWeexTagNameCompletionsVue: (prefix, internalPrefix) ->
    (@buildTagCompletionVue tag, prefix, internalPrefix) for tag in @vue.tags

  ###
  # 模块主入口函数 getSuggestions
  # 提示：
  #  1.标签提示 -> 提示坐标 (语言  =Vue2，sope=tag，前缀='匹配的前缀')
  #  2.属性提示 -> 提示坐标 (语言  =Vue2，sope={attr, [tag name]}，前缀='匹配的前缀')
  #  3.属性值提示 -> 提示坐标 (语言 =Vue2，sope={attr-value, [tag name, attribute name]}，前缀='匹配的前缀')
  #  4.Vue2.0提示 -> 提示坐标 (语言=Vue2，sope={vue2.0 指令，参数，修饰符}，前缀='匹配的前缀')
  #  5.标签智能闭合
  ###
  getSuggestions: (request) ->
    return @getSuggestionsVue(request)

  getPropteriesFromTagName: (tagName) ->
    properties = @vue.properties
    properties = properties.filter (x) ->
      return x.name == tagName
    return [] unless properties
    return [] if properties.length < 1
    values = properties[0].values
    events = properties[0].events
    ret =
      properties: values
      events: events
    return ret

  ###
  # 属性提示
  ###
  getWeexTagPropertyNameCompletions: (prefix, tagName) ->
    {properties, events} = @getPropteriesFromTagName tagName
    arr = []

    internalPrefix = prefix

    # vue2_0 缩写： ':' '@' 可能要做特殊处理
    if internalPrefix == ":"
      prefix = ""

    if properties
      for propertyName in properties
        arr.push @buildPropertyNameCompletion propertyName, prefix, internalPrefix

    if events
      for event in events
        arr.push @buildPropertyEventNameCompletion event, prefix, internalPrefix

    for prop in @vue2_0()
      arr.push @buildWeexVuePropertyNameCompletion prop, prefix, internalPrefix

    arr.sort( (a, b) ->
      if a.text > b.text
        return 1;
      else if a.text < b.text
        return -1;
      else
        return 0;
    )
    return arr

  getWeexTagPropertyValueCompletions: (irSymbol, prefix, tagname, attrname, needQuoted)->
    if irSymbol.attr_name == "class"
      arr = []
      for cls in irSymbol.css_classes
        if isEmpty cls.active_document
          act_doc = null
        else
          act_doc = "<br/><pre><code class=\"lang-css\">.#{cls.name} {\n#{cls.active_document}}</code></pre>";
        arr.push (@buildPropertyValueCompletion tagname, attrname, cls.name, prefix, prefix, needQuoted, act_doc)
      return arr
    else
      propertyValues = @vue.propertyValues
      console.log propertyValues
      arr = []
      vs = propertyValues[irSymbol.attr_name]
      console.log vs
      if vs
        for v in vs
          arr.push (@buildPropertyValueCompletion tagname, attrname, v, prefix, prefix, needQuoted)

      arr.sort ((a, b) ->
        if a.text > b.text
          return 1;
        else if a.text < b.text
          return -1;
        else
          return 0;
      )
      return arr

  onWillInsertText: ->
    @triggerStat = false

  getWeexVueModifierNameCompletions: (modifierPrefix, arg, attr, tagName) ->
    arr = []
    if attr == "v-on"
      mds = ['stop', 'prevent', 'capture', 'self']
      for md in mds
        arr.push @buildWeexVuePropertyModifierNameCompletion md, modifierPrefix, modifierPrefix, "#{md}=\"${0}\""

    return arr

  getWeexVueArgNameCompletions: (argPrefix, attr, tagName) ->
    arr = []
    {properties, events} = @getPropteriesFromTagName tagName
    if attr == "v-bind"
      if properties
        for prop in properties
          arr.push @buildWeexVuePropertyArgNameCompletion prop, argPrefix, argPrefix, "#{prop}=\"${0}\""
    else if attr == "v-on"
      if events
        for event in events
          arr.push @buildWeexVuePropertyArgNameCompletion event, argPrefix, argPrefix, "#{event}.${0}"

    return arr;

  getSuggestionsVue: (request) ->
    pos = request.bufferPosition
    text = request.editor.getText()
    irSymbol = parse text, pos.row, pos.column

    @subscriptions.add (request.editor.onWillInsertText () => @onWillInsertText())

    console.log irSymbol
    return unless irSymbol

    if irSymbol.symbol_type is "XML_PAIN_TEXT" # && irSymbol.prefix is "<"
      # 标签提示
      pre = irSymbol.prefix
      if pre and pre == '<'
        return @getWeexTagNameCompletionsVue "", irSymbol.prefix

      pre = makePrefix pre, ' '
      return @getWeexTagNameCompletionsVue pre, pre
    else if irSymbol.symbol_type is "XML_TAG_NAME"
      # 标签名
      return @getWeexTagNameCompletionsVue irSymbol.prefix, '<' + irSymbol.prefix
    else if irSymbol.symbol_type is "XML_TAG_LB"
      # 标签名
      return @getWeexTagNameCompletionsVue "", '<'
    else if irSymbol.symbol_type is "XML_TAG_RB" and irSymbol.need_close
      # 补全结束标签
      @buildTagAutoCloseTag(request.editor, irSymbol.tag_name, pos)
    else if irSymbol.symbol_type is "XML_TAG_BODY"
      # 补全属性
      prefix = makePrefix irSymbol.prefix, ' '
      return @getWeexTagPropertyNameCompletions prefix, irSymbol.tag_name
    else if irSymbol.symbol_type == "XML_ATTRIBUTE_STRING" and irSymbol.scope_name == "XN_ATTRIBUTE"
      # 补全属性

      if irSymbol.prefix[0] == '@'
        irSymbol.prefix = irSymbol.prefix.replace "@", "v-on:"
      else if irSymbol.prefix[0] == ':'
        irSymbol.prefix = irSymbol.prefix.replace ":", "v-bind:"

      [attr, args, modifier] = attrReg irSymbol.prefix
      console.log attr
      console.log args
      console.log modifier

      if attr != null and args != null and modifier != null
        return @getWeexVueModifierNameCompletions modifier, args, attr, irSymbol.tag_name
      else if attr != null and args != null
        return @getWeexVueArgNameCompletions args, attr, irSymbol.tag_name
      else if attr != null
        prefix = makePrefix irSymbol.prefix, ' '
        return @getWeexTagPropertyNameCompletions prefix, irSymbol.tag_name

    else if irSymbol.symbol_type == "XML_ATTRIBUTE_OP" and irSymbol.scope_name == "XN_ATTRIBUTE"
      return @getWeexTagPropertyValueCompletions irSymbol, "", irSymbol.tag_name, irSymbol.attr_name, true
    else if irSymbol.symbol_type == "XML_ATTRIBUTE_STRING" and irSymbol.scope_name == "XN_ATTRIBUTE_VALUE"
      return @getWeexTagPropertyValueCompletions irSymbol, prefix, irSymbol.tag_name, irSymbol.attr_name, true
    else if irSymbol.symbol_type == "XML_STRING_DOUBLE_QUOTE_START" and irSymbol.scope_name == "XN_ATTRIBUTE"
      prefix = makePrefix irSymbol.prefix, ' '
      prefix = makePrefix prefix, '"'
      callback = () =>
        if @triggerStat == false
          @triggerAutocomplete request.editor
          @triggerStat = true
      setTimeout callback, 1
      return @getWeexTagPropertyValueCompletions irSymbol, prefix, irSymbol.tag_name, irSymbol.attr_name, false
    else if irSymbol.scope_name == "XN_ATTRIBUTE_VALUE"
      prefix = makePrefix irSymbol.prefix, ' '
      prefix = makePrefix prefix, '"'
      callback = () =>
        if @triggerStat == false
          @triggerAutocomplete request.editor
          @triggerStat = true
      setTimeout callback, 1
      return @getWeexTagPropertyValueCompletions irSymbol, prefix, irSymbol.tag_name, irSymbol.attr_name, false

  ###
  # plus 回调接口
  ###
  onDidInsertSuggestion: ({editor, suggestion}) ->
    # 联动
    @triggerStat = false
    setTimeout(@triggerAutocomplete.bind(this, editor), 1) if (suggestion.type is 'property' or suggestion.type is 'vue' or suggestion.type is 'event')

  triggerAutocomplete: (editor) ->
    atom.commands.dispatch(atom.views.getView(editor), 'thera-autocomplete-plus-plus:activate', {activatedManually: false})

  loadProperties: ->
    @commonProperties = []
    @tags = []
    fs.readFile path.resolve(__dirname, '..', 'weex-completions.json'), (error, content) =>
      {@commonProperties, @tags} = JSON.parse(content) unless error?
      return

  loadPropertiesVue: ->
    @commonProperties = []
    @tags = []
    fs.readFile path.resolve(__dirname, '..', 'weex-vue-completions.json'), (error, content) =>
      @vue = JSON.parse(content) unless error?
      return
