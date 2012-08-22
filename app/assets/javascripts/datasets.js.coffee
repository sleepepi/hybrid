jQuery ->
  window.$dataset_name_input = $( "#dataset_name")
  
  # modal dialog init: custom buttons and a "close" callback reseting the form inside
  window.$new_dataset_dialog = $( "#new_dataset_dialog" ).dialog(
      autoOpen: false
      modal: true
      buttons:
        "Create Dataset": () ->
          # addDatasetTab() # DEPRECATED TODO REMOVE
          $.post($("#new_dataset_form").attr("action"), $("#new_dataset_form").serialize(), null, "script")
          $( this ).dialog( "close" )
        Cancel: () -> $( this ).dialog( "close" )
      open: () ->
        window.$dataset_name_input.focus()
      close: () ->
        $form[ 0 ].reset()
  )
  
  # addTab form: calls addTab function on submit and closes the dialog
  $form = $( "form", window.$new_dataset_dialog ).submit( () ->
    window.$new_dataset_dialog.dialog( "close" )
    false
  )
    
  # addTab button: just opens the dialog
  
  $(document).on('click', "#add_dataset_tab", () -> window.$new_dataset_dialog.dialog( "open" ) )