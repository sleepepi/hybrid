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


#           <%# TODO: Move this into the assets/javascripts folder, no longer dependent on table and column for autocomplete? %>
#           <script type="text/javascript">
# $(document).ready(function(){
#   $("#database_concepts_<%= @column.gsub(' ', '_') %>_search")
#     .on( "keydown", function( event ) {
#          if ( event.keyCode === $.ui.keyCode.TAB &&
#            $( this ).data( "autocomplete" ).menu.active ) {
#              event.preventDefault();
#          }
#        })

#     .catcomplete({
#      source: "<%= search_available_mappings_url(source_id: @source.id, autocomplete: true) %>",
#      html: true,
#       select: function( event, ui ) {
#                 $("#new_concept_id").val(ui.item ? ui.item.id : '');
#                 $("#new_column").val("<%= @column %>");
#                 $("#new_mapping_form").submit();
#               },
#       close: function( event, ui ){
#         // alert('close!');
#         //$("#new_mapping_form").submit();
#       }
#   });

# });
#           </script>
