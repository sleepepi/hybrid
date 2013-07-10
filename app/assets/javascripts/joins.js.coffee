jQuery ->

  $(document)
    .on('change', '#join_from_table, #join_to_table', () ->
      params = {}
      params.table = $(this).val()
      params.attribute = $(this).data('attribute')
      $.get(root_url + "sources/#{$(this).data('source-id')}/table_columns_for_select", params, null, "script")
    )
