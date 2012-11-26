# This file will contain application generic JavaScript (CoffeeScript)

# TODO: Check that all of these functions belong here and that they are being currently used in application.

jQuery ->
  $(".datepicker").datepicker
    showOtherMonths: true
    selectOtherMonths: true
    changeMonth: true
    changeYear: true

  $("#ui-datepicker-div").hide()

  $(document).on('click', ".pagination a, .page a, .next a, .prev a", () ->
    $.get(this.href, null, null, "script")
    false
  )

  $(document).on("click", ".per_page a", () ->
    object_class = $(this).data('object')
    $.get($("#"+object_class+"_search").attr("action"), $("#"+object_class+"_search").serialize() + "&"+object_class+"_per_page="+ $(this).data('count'), null, "script")
    false
  )

  $("#table_columns_search select, #table_columns_search input").change( () ->
    $.post($("#table_columns_search").attr("action"), $("#table_columns_search").serialize(), null, "script")
    showWaiting('#table_content', ' Loading Table Mappings', true)
    false
  )

  # # Custom Category output for Autocomplete
  # $.widget( "custom.catcomplete", $.ui.autocomplete,
  #   _renderMenu: ( ul, items ) ->
  #     self = this
  #     currentCategory = "";
  #     $.each( items, ( index, item ) ->
  #       if item.category != currentCategory
  #         ul.append( "<li class='ui-autocomplete-category'>" + item.category + "</li>" )
  #         currentCategory = item.category
  #       self._renderItem( ul, item ) unless item.category_only == "true"
  #     )
  # )

  $("#source_rule_user_tokens").tokenInput(root_url + "users.json"
    crossDomain: false
    prePopulate: $("#source_rule_user_tokens").data("pre")
    theme: "facebook"
    preventDuplicates: true
  )

  # Show and hide a delete icon on mouseover and mouseout for query_concepts
  $(document)
    .on('mouseover', ".faded_delete_icon", () -> $('#'+$(this).attr('data-image-id')).attr('src', root_url + 'assets/contour/delete.png'))
    .on('mouseout', ".faded_delete_icon", () -> $('#'+$(this).attr('data-image-id')).attr('src', root_url + 'assets/contour/blank.png'))

  $(document)
    .on('mouseover', ".smudge", () -> $(this).attr('src', $(this).attr('src').replace(/(-(.*?))?.png/, '_g1.png')))
    .on('mouseout', ".smudge",  () -> $(this).attr('src', $(this).attr('src').replace(/(-(.*?))?_g1.png/, '.png')))
