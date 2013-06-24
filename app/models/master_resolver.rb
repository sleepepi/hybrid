class MasterResolver

  attr_reader :errors, :values

  def initialize(report_concepts, query, current_user, actions_required = ['view data distribution', 'view limited data distribution'])
    @report_concepts = report_concepts.compact.to_a
    @current_user = current_user
    @actions_required = actions_required
    @query = query
    @errors = []
    @super_grid = {}
    @values = []
    set_identifier_concept
    set_values
  end

  def all_sources
    (@query.sources.to_a | @report_concepts.collect(&:source)).uniq
  end

  # The identifier concept is used to link across multiple datasets
  def set_identifier_concept
    identifier_concepts = []
    Concept.current.where( concept_type: 'identifier' ).with_source(all_sources.collect(&:id)).each do |concept|
      identifier_concepts << concept if not all_sources.collect{|s| s.concepts.where( concept_type: 'identifier').pluck(:id).include?(concept.id) }.include?(false)
    end
    @identifier_concept = identifier_concepts.first
  end

  def set_values
    all_sources.each do |source|
      wrapper = Aqueduct::Builder.wrapper(source, @current_user)

      mappings_for_select_clause = []
      @report_concepts.each_with_index do |report_concept, index|
        m = source.mappings.where(concept_id: report_concept.concept.id).first if report_concept.source == source
        mappings_for_select_clause << { table: m.table, column: m.column, concept: m.concept, report_concept_index: index, mapping: m } if m and m.user_can_view?(@current_user, @actions_required)
      end

      if mappings_for_select_clause.size > 0 and @identifier_concept
        m = source.mappings.where(concept_id: @identifier_concept.id).first
        mappings_for_select_clause.prepend( { table: m.table, column: m.column } ) if m
      end

      mappings_for_select_clause.uniq!

      tables_covered_by_concepts = (mappings_for_select_clause.collect{|m| m[:table]} | source_tables(source)).uniq
      join_conditions_hash = source.join_conditions(tables_covered_by_concepts, @current_user)
      @errors += join_conditions_hash[:errors]

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
            @super_grid[row[0].to_s][mapping_hash[:report_concept_index]] = mapping_hash[:mapping].human_normalized_value(row[mapping_index]) if mapping_hash[:report_concept_index]
          end

        end
      end
    end

    @super_grid.each do |key, values|
      @values << values.collect{|val| val || 'unknown'}
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
