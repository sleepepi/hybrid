class MasterResolver

  attr_reader :errors, :value_hash, :super_grid, :values

  def initialize(concepts, query, current_user, resolving_source, actions_required = ['view data distribution', 'view limited data distribution'], additional_sources = [])
    @concepts = concepts.compact.to_a
    @current_user = current_user
    @actions_required = actions_required
    @query = query
    @additional_sources = additional_sources
    @errors = []
    @resolving_source = resolving_source
    @super_grid = {}
    @values = []
    set_values
  end

  def find_links_to(source)
    source_join = SourceJoin.where( source_id: @resolving_source.id, source_to_id: source.id ).first
    rev_join = SourceJoin.where( source_id: source.id, source_to_id: @resolving_source.id ).first
    if source_join
      table = source_join.to_table
      column = source_join.to_column
    elsif rev_join
      table = rev_join.from_table
      column = rev_join.from_column
    else
      @errors << "No join found between #{source.name} and #{@resolving_source.name}."
      return {}
    end
    { table: table, column: column }
  end

  def set_values
    @value_hash = {}
    (@query.sources.to_a | @additional_sources).uniq.each do |source|
      wrapper = Aqueduct::Builder.wrapper(source, @current_user)

      mappings_for_select_clause = []
      @concepts.each_with_index do |concept, index|
        m = source.mappings.where(concept_id: concept.id).first
        mappings_for_select_clause << { table: m.table, column: m.column, concept: m.concept, concept_index: index, mapping: m } if m and m.user_can_view?(@current_user, @actions_required)
      end

      mappings_for_select_clause.uniq!

      tables_covered_by_concepts = (mappings_for_select_clause.collect{|m| m[:table]} | source_tables(source)).uniq
      join_conditions_hash = source.join_conditions(tables_covered_by_concepts, @current_user)
      @errors += join_conditions_hash[:errors]

      links_hash = find_links_to(source)
      mappings_for_select_clause.prepend( { table: links_hash[:table], column: links_hash[:column] } ) if mappings_for_select_clause.size > 0 and not links_hash.blank?

      result_hash = wrapper.sql_codes
      sql_open = result_hash[:open]
      sql_close = result_hash[:close]
      sql_statement = "SELECT #{mappings_for_select_clause.collect{|m| m[:table] + '.' + sql_open + m[:column] + sql_close}.join(',')} FROM #{tables_covered_by_concepts.join(', ')} WHERE #{join_conditions_hash[:result].join(' and ')}#{' and ' unless join_conditions_hash[:result].blank?}#{source_conditions(source)}"
      if mappings_for_select_clause.size > 0
        begin
          wrapper.connect
          (results, number_of_rows) = wrapper.query(sql_statement)
        rescue
          results = []
        ensure
          wrapper.disconnect
        end
        results.to_a.each do |row|
          @super_grid[row[0].to_s] ||= []
          mappings_for_select_clause.each_with_index do |mapping_hash, mapping_index|
            @super_grid[row[0].to_s][mapping_hash[:concept_index]] = mapping_hash[:mapping].human_normalized_value(row[mapping_index]) if mapping_hash[:concept_index]
          end

        end
        @value_hash[source.name] = results.to_a
      end
    end

    @super_grid.each do |key, values|
      @values << values
    end
  end

  private

  def generate_resolvers(source)
    @query.query_concepts.collect{|qc| Resolver.new(qc, source, @current_user)}
  end

  def source_tables(source)
    generate_resolvers(source).collect(&:tables).flatten.compact.uniq
  end

  def source_conditions(source)
    resolvers = generate_resolvers(source)
    join_hash = source.join_conditions(source_tables(source), @current_user)
    resolver_conditions = resolvers.collect(&:conditions_for_entire_query).join(' ')
    [join_hash[:result], resolver_conditions].select{|c| not c.blank?}.join(' and ')
  end

end
