@loadSensitiveVariablePopover = () ->
  $("[data-object='sensitive-tooltip']").popover(
    html: true
    placement: 'right'
    trigger: 'hover'
    title: ''
    content: '<p class="quiet small">This variable can ONLY be viewed or downloaded if you only have <span class="source_rule_text">view data distribution</span> or <span class="source_rule_text">download dataset</span> respectively.</p>'
  )


jQuery ->
  $(document)
    .on('click', '[data-object~="toggle-folder"]', () ->
      folder_id = $(this).data('folder-id')
      $("##{folder_id}_content").toggle()
      if $("##{folder_id}_content").is(':visible')
        $("##{folder_id}_link_img").attr('class', 'icon-folder-open')
      else
        $("##{folder_id}_link_img").attr('class', 'icon-folder-close')
    )
