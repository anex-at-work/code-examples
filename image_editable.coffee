# by anex.work

(($) ->
  'use strict'
  class ImageEditable
    counter = 0

    constructor: (@el)->
      throw 'FileReader not supported!' if !(window.File && window.FileReader && window.FileList && window.Blob)
      @el.addClass 'bs'
      @_create_reader()
      @_create_elements()
      @_create_events()

    _create_reader: ->
      _t = @
      @reader = new FileReader()
      @reader.onload = (e)->
        _t._spin()
        $.ajax
          url: _t.el.data('editableurl')
          type: 'put'
          data:
            content: e.target.result
            show: 'full'
          success: (data, status, xhr)->
            img = document.createElement 'img'
            img.onload = ->
              _t.el.find('img').css({visibility: 'visible'}).attr 'src', img.src
              _t._unspin()
            img.src = data.src
            if input = _t.el.data('editableinput')
              _t.el.find("[name=\"#{input}\"]").val data.value

    _create_elements: ->
      input_element = ''
      input_element = "<input type=\"hidden\" value=\"\" name=\"#{@el.data('editableinput')}\" />" if @el.data('editableinput')
      @toolbox = $ '<div class="_ime_toolbox">
          <div class="btn btn-primary _ime_upload"><i class="fa fa-upload"></i></div>
          <div class="btn btn-danger _ime_trash"><i class="fa fa-trash"></i></div>
          <input type="file" />
          ' + input_element + '
        </div>
        <div class="_ime_dropzone">Drop files here</div>'
      @el.append @toolbox

    _create_events: ->
      _ = @toolbox
      _t = @
      @toolbox.find('._ime_upload').click ->
        _.find('input').trigger 'click'
      @toolbox.find('._ime_trash').click =>
        @_spin()
        $.ajax
          url: _t.el.data('editableurl')
          type: (if _t.el.data('itemableid') then 'delete' else 'put')
          data:
            content: ''
            trash: true
          success: (data, status, xhr)->
            if _t.el.data('itemableid')
              _t.el.remove()
            else
              _t.el.find('img').css
                visibility: 'hidden'
              _t._unspin()
      @toolbox.find('input[type="file"]').change ->
        _t.reader.readAsDataURL @files[0]
      document.ondrop = (e)=>
        if $('._ime_dropzone', @el)[0] == e.target
          @reader.readAsDataURL e.dataTransfer.files[0]
        $('._ime_dropzone').css
          visibility: 'hidden'
        counter = 0
        e.preventDefault()
        return false

      if !document.ondragenter?
        document.ondragover = (e)->
          e.preventDefault()
          return false
        document.ondragenter = (e)->
          if 0 == counter
            $('._ime_dropzone').css
              visibility: 'visible'
          counter++
        document.ondragleave = (e)->
          counter--
          if 0 == counter
            $('._ime_dropzone').css
              visibility: 'hidden'

    _spin: ->
      @toolbox.find('.fa-upload').removeClass('fa-upload').addClass 'fa-refresh fa-spin'
    _unspin: ->
      @toolbox.find('.fa-refresh').removeClass('fa-refresh fa-spin').addClass 'fa-upload'

  class MultipleImageEditable
    default_options =
      sortable: true

    constructor: (@el, @options)->
      @options = $.extend default_options, @options
      @template = @el.find('[data-template]').hide()
      @_spin_counter = 0
      @el.addClass 'bs'
      @_create_elements()
      @_create_events()
      @_create_sortable() if @options?.sortable

    _create_elements: ->
      input_element = ''
      input_element = "<input type=\"hidden\" value=\"\" name=\"#{@el.data('editableinput')}\" />" if @el.data('editableinput')
      @toolbox = $ '<div class="_ime_toolbox" style="z-index:1000000;bottom:0;top:auto;">
          <div class="btn btn-primary _ime_upload"><i class="fa fa-cloud-upload"></i></div>
          <input type="file" multiple />
          ' + input_element + '
        </div>'
      @el.append @toolbox

    _create_events: ->
      _ = @toolbox
      _t = @
      @toolbox.find('._ime_upload').click ->
        _.find('input').trigger 'click'
      @toolbox.find('input[type="file"]').change ->
        for file in @files
          do (file)->
            _t._spin()
            cloned = _t.template.clone().show()
            _t.el.append(cloned)
            _t.options.sortable_obj.sortable('reload') if _t.options.sortable_obj?
            new ImageEditable cloned
            reader = new FileReader()
            reader.onload = (e)->
              $.ajax
                url: _t.el.data('creatableurl')
                type: 'put'
                data:
                  content: e.target.result
                  show: 'full'
                success: (data, status, xhr)->
                  img = document.createElement 'img'
                  img.onload = ->
                    cloned.find('img').css({visibility: 'visible'})[0].src = img.src
                  img.src = data.src
                  cloned.attr 'data-itemableid', data.itemableid
                  cloned.attr 'data-editableurl', data.editableurl
                  _t._unspin()
            reader.readAsDataURL file

    _create_sortable: ->
      if !$.fn.sortable?
        @options.sortable = false
        return
      @el.find('> :not(._ime_toolbox)').append '<div class="_ime_handle btn btn-default btn-sm"><i class="fa fa-arrows"></i></div>'
      placeholder = @template.clone().html('').show()
      @options.sortable_obj = @el.sortable
        handle: '._ime_handle'
        items: ':not(._ime_toolbox)'
        placeholder: placeholder[0].outerHTML
        forcePlaceholderSize: true
      .bind 'sortupdate', (e, ui)=>
        @el.find('.ime_handle').hide()
        $.ajax
          url: ui.item.data('editableurl')
          type: 'put'
          data:
            reorder:
              prev: ui.item.prev('[data-itemableid]').data('itemableid')
              next: ui.item.next('[data-itemableid]').data('itemableid')
          success: (data, status, xhr)=>
            @el.find('.ime_handle').show()

    _spin: ->
      @toolbox.find('.fa-cloud-upload').removeClass('fa-cloud-upload').addClass 'fa-refresh fa-spin' if 0 == @_spin_counter
      @_spin_counter += 1
    _unspin: ->
      @_spin_counter -= 1
      @toolbox.find('.fa-refresh').removeClass('fa-refresh fa-spin').addClass 'fa-cloud-upload' if 0 == @_spin_counter

  $.fn.extend
    imageeditable: ->
      @each ->
        new ImageEditable $(@)
    multipleimageeditable: (options)->
      @each ->
        new MultipleImageEditable $(@), options
) jQuery
