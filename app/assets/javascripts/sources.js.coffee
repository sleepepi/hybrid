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
    .on('click', '[data-object~="save-table-name"]', () ->
        params = { '_method': 'patch' }
        params.human_name = $('#human_name').val()
        params.table = $(this).data('table')
        $.post( root_url + "sources/#{$(this).data('source-id')}/update_table_name", params, null, "script" )
        false
    )
