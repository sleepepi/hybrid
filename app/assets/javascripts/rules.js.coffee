@toggleCheckboxGroup = (index) ->
  mode = $('.rule_group_'+index+'_parent').is(':checked');
  $('.rule_group_'+index).each( () ->
    $(this).prop('checked', mode)
  )

@toggleCheckboxGroupParent = (index) ->
  mode = true
  $('.rule_group_'+index).each( () ->
    unless $(this).is(':checked')
      mode = false
  )
  $('.rule_group_'+index+'_parent').prop('checked',mode)

@loadRulesReady = () ->
  $("#rule_user_tokens").tokenInput(root_url + "users.json"
    crossDomain: false
    prePopulate: $("#rule_user_tokens").data("pre")
    theme: "facebook"
    preventDuplicates: true
  )

  for index in ['0', '1', '2']
    toggleCheckboxGroupParent(index)
