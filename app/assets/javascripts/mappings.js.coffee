jQuery ->

  $(document)
    .on('click', '[data-object~="mapping-automap"]', () ->
      params = {}
      params.source_id = $(this).data('source-id')
      params.table = $(this).data('table')
      params.column = $(this).data('column')
      $.get(root_url + 'mappings/automap_popup', params, null, "script")
      false
    )
    .on('click', '[data-object~="mapping-select"]', () ->
      $('#selected_mapping_id').val($(this).data('value'))
      $('#mappings_form').submit()
      false
    )

