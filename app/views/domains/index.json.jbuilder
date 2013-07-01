json.array!(@domains) do |domain|
  json.extract! domain, :folder, :name, :options, :dictionary_id, :version
  json.url domain_url(domain, format: :json)
end
