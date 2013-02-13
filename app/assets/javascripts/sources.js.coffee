jQuery ->
  $(document)
    .on('click', '[data-object~="mapping-select"]', () ->
      $('#selected_mapping_id').val($(this).data('value'))
      $('#mappings_form').submit()
      false
    )
    .on('click', '[data-object~="mapping-new"]', (event) ->
      $('#database_concepts_' + $(this).data('value') + '_search').val( $(this).data('value') )
      $('#database_concepts_' + $(this).data('value') + '_search').focus()
      $('#database_concepts_' + $(this).data('value') + '_search').change()
      false
    )
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
