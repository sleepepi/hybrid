jQuery ->
  $(document)
    .on('click', '[data-object~="table-automap"]', () ->
      $('#auto_map_form').submit()
      showWaiting('#table_content', '', true)
      false
    )
    .on('click', '[data-object~="all-tables-automap"]', () ->
      $('#auto_map_form_all').submit()
      showWaiting('#table_content', '', true)
      false
    )
