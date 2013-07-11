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
