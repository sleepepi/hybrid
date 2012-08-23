# JavaScript Specific to Queries
jQuery ->
  $( "#query_form" ).submit()
  # TODO Remove the following line
  $( "#total_records_found_display" ).dblclick( () -> $('#information').toggle() )

  $("#source")
    .on( "keydown", ( event ) ->
      if event.keyCode == $.ui.keyCode.TAB and $(this).data( "catcomplete" ).menu.active
        event.preventDefault()
    )
    .catcomplete(
 	    source: root_url + "sources?autocomplete=true"
      html: true
      select: ( event, ui ) ->
        $("#selected_source_id").val(if ui.item then ui.item.id else '')
      close: ( event, ui ) ->
        $("#sources_form").submit()
        $("#source").val('')

    )
  $("#selected_source_id").val('')

  $("#concept_search_term")
    .on( "keydown", ( event ) ->
      if event.keyCode == $.ui.keyCode.TAB and $( this ).data( "catcomplete" ).menu.active
        event.preventDefault()
    )
    .catcomplete(
      source: root_url + "concepts?autocomplete=true&#{($('#search_form').attr('action') || '?').split('?')[1]}"
      html: true
      select: ( event, ui ) ->
        $("#selected_concept_id").val(if ui.item then ui.item.id else '')
      close: ( event, ui ) ->
        $("#search_form").submit()
        $("#selected_concept_id").val('')
    )
  $("#selected_concept_id").val('')

  $( "#query_concepts" )
    .sortable(
      axis: "y"
      stop: (event, ui) ->
        order = $(this).sortable('toArray').toString()
        $.post($("#query_concepts_form").attr("action"), "&order=#{order}", null, "script")
      cancel: 'span.errors_found, div.qc-cancel'
    )

  $(document).on('click', '[data-object~="folder-show-more"]', () ->
    $($(this).data('target')).show()
    $(this).hide()
    false
  )
