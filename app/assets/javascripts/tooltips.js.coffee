jQuery ->
  $('.loader').on("ajax:before", (element, e) ->
    $('#' + this.id + '_img').attr('src', root_url + 'assets/contour/ajax-loader.gif')
  )

  $("#select_all").on("ajax:complete", (element, e) ->
    $('#' + this.id + '_img').attr('src', root_url + 'assets/icons/gentleface/checkbox_checked_16.png')
  )

  $("#select_none").on("ajax:complete", (element, e) ->
    $('#' + this.id + '_img').attr('src', root_url + 'assets/icons/gentleface/checkbox_unchecked_16.png')
  )

  $("#increase_indent").on("ajax:complete", (element, e) ->
    $('#' + this.id + '_img').attr('src', root_url + 'assets/icons/gentleface/indent_increase_16.png')
  )

  $("#decrease_indent").on("ajax:complete", (element, e) ->
    $('#' + this.id + '_img').attr('src', root_url + 'assets/icons/gentleface/indent_decrease_16.png')
  )

  $("#copy_concepts").on("ajax:complete", (element, e) ->
    $('#' + this.id + '_img').attr('src', root_url + 'assets/icons/gentleface/clipboard_copy_16.png')
  )

  $("#remove_concepts").on("ajax:complete", (element, e) ->
    $('#' + this.id + '_img').attr('src', root_url + 'assets/icons/gentleface/trash_16.png')
  )
