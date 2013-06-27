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
    .on('click', '[data-object~="mapping-save"]', () ->
      mapping_id = $(this).data('mapping-id')

      params = $("#mapping-#{mapping_id}-form").serialize()
      params = params + "&source_id=" + $(this).data('source-id')
      params = params + "&_method=patch"

      $.post(root_url + "mappings/#{mapping_id}", params, null, "script")
      false
    )
