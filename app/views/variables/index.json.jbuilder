json.array!(@variables) do |variable|
  json.extract! variable, :folder, :name, :display_name, :description, :variable_type, :dictionary_id, :domain_id, :units, :version, :calculation, :design_file, :design_name, :sensitivity, :commonly_used
  json.url variable_url(variable, format: :json)
end
