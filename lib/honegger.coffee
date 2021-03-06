(($, document, window) ->
  Honegger = (element, options) ->
    self = this
    disabled = false
    composer = $(element).data('honegger', this).addClass('honegger-composer')
    components = $.fn.honegger.components(composer, options)

    toolbar = if typeof options.toolbar == 'string' then $(options.toolbar) else options.toolbar

    insideComposer = (range) ->
      $.inArray(element, $(range.startContainer).parents()) != -1

    notInsideComponent = (range) ->
      $(range.startContainer).parents(options.componentSelector).length == 0

    currentRange = ->
      selection = window.getSelection()
      if selection.rangeCount
        range = selection.getRangeAt(0)
        return range if insideComposer(range) && notInsideComponent(range)

    execCommand = (command, args)->
      if args? then document.execCommand(command, false, args) else document.execCommand(command)

    bindHotkey = (target, key, command) ->
      target.keydown(key,(e)->
        if target.attr('contenteditable') && target.is(':visible')
          e.preventDefault()
          e.stopPropagation()
          execCommand(command) if !disabled && currentRange()?
      ).keyup(key, (e) ->
        if target.attr('contenteditable') && target.is(':visible')
          e.preventDefault()
          e.stopPropagation()
      )

    makeComposer = (element)->
      element.attr('contenteditable', 'true').on 'mouseup keyup mouseout focus', ->
        $.fn.honegger.updateToolbar(toolbar, options)
      for key, command of options.hotkeys
        bindHotkey(element, key, command)

    makeComposers = (element) ->
      element.find(options.editableSelector).andSelf().filter(options.editableSelector).each ->
        makeComposer($(this))
      element

    enable = (enabled) ->
      (if options.multipleSections then composer.find(options.editableSelector) else composer).attr('contenteditable',
        !(disabled = !enabled))

    initComposer = ->
      if options.multipleSections then makeComposers(composer) else makeComposer(composer)

    this.execCommand = (command, args) ->
      execCommand(command, args) if !disabled && currentRange()?

    this.insertComponent = (name, config = {}) ->
      return unless !disabled && components.get(name)? && (range = currentRange())
      range.insertNode(components.newComponent(name, config)[0])

    this.installComponent = components.install

    this.changeMode = (mode, config) ->
      enable(mode == 'edit')
      composer.find(options.componentSelector).each ->
        components.modes[mode]($(this), config)

    this.getTemplate = (handler) ->
      components.getTemplate composer, (html, dataTemplate, configurations) ->
        handler(html, dataTemplate, configurations)

    this.loadContent = (content, mode, configuration) ->
      composer.html(content)
      components.setConfiguration(configuration)
      initComposer()
      self.changeMode(mode)

    this.disable = ->
      enable(false)

    this.enable = ->
      enable(true)

    if (options.multipleSections)
      this.insertSection = (template) ->
        composer.append(makeComposers($(template))) unless disabled

    initComposer()
    $.fn.honegger.initToolbar composer, toolbar, options

  $.fn.honegger = (options)->
    parameters = $.makeArray(arguments).slice(1)
    this.each ->
      instance = $.data(this, 'honegger')
      return new Honegger(this, $.extend({}, $.fn.honegger.defaults, options)) unless instance
      instance[options].apply(instance, parameters) if typeof(options) == 'string' && instance[options]?

  $.fn.honegger.initToolbar = (composer, toolbar, options) ->
    $(options.buttons, toolbar).each ->
      button = $(this)
      button.click ->
        composer.honegger('execCommand', button.attr(options.buttonCommand))

  $.fn.honegger.updateToolbar = (toolbar, options)->
    $(options.buttons, toolbar).each ->
      button = $(this)
      command = button.attr(options.buttonCommand)
      if document.queryCommandState(command)
        button.addClass(options.buttonHighlight)
      else
        button.removeClass(options.buttonHighlight)

  $.fn.honegger.defaults =
    multipleSections: true
    editableSelector: '*[data-role="composer"]'
    componentSelector: '*[data-role="component"]'
    configurationSelector: '*[data-component-config-key]'
    configuration: 'data-component-config-key'
    toolbar: '*[data-role="toolbar"]'
    buttons: '*[data-command]'
    buttonCommand: 'data-command'
    buttonHighlight: 'honegger-button-active'
    hotkeys:
      'ctrl+b meta+b': 'bold',
      'ctrl+i meta+i': 'italic',
      'ctrl+u meta+u': 'underline',
      'ctrl+z meta+z': 'undo',
      'ctrl+y meta+y meta+shift+z': 'redo',
      'shift+tab': 'outdent',
      'tab': 'indent'
    componentEditorTemplate: '<table contenteditable="false">' +
    '<thead><tr><td class="component-header"></td></tr></thead>' +
    '<tbody><tr><td class="component-content"></td></tr></tbody>' + '</table>'
    componentPlaceholder: '<div></div>')(jQuery, document, window)


