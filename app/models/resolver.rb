class Resolver

  attr_reader :conditions, :tables, :position, :errors

  def initialize(filter, source, current_user)
    @position = filter.id
    @filter = filter
    @source = source
    @current_user = current_user
    @errors = []
    set_identifier
    set_conditions
  end

  def count
    return 0 if tables.size == 0
    wrapper = Aqueduct::Builder.wrapper(source, current_user)

    join_hash = source.join_conditions(tables, current_user)
    all_conditions = [join_hash[:result], conditions].select{|c| not c.blank?}

    sql_statement = "SELECT COUNT(*) FROM #{tables.join(', ')} WHERE #{all_conditions.join(' and ')}"

    wrapper.connect
    (results, number_of_rows) = wrapper.query(sql_statement)
    wrapper.disconnect
    results.to_a.first[0]
  end

  def conditions_for_entire_query
    "("*filter.left_brackets + conditions + ")"*filter.right_brackets + (filter.position < (filter.query.query_concepts.size - 1) ? " #{filter.right_operator}" : '')
  end

  private

    def set_conditions
      @conditions = "1 = 0"
      (@conditions, table) = construct_conditions
      @tables = [table].compact
    end

    def current_user
      @current_user
    end

    def source
      @source
    end

    def filter
      @filter
    end

    def all_sources
      [filter.source, source].uniq.compact
    end

    def set_identifier
      identifiers = []
      Variable.current.where( variable_type: 'identifier' ).with_source(all_sources.collect(&:id)).each do |variable|
        identifiers << variable if not all_sources.collect{|s| s.variables.where( variable_type: 'identifier' ).pluck(:id).include?(variable.id) }.include?(false)
      end
      @identifier = identifiers.first
    end

    def construct_conditions
      if filter.source and filter.source != source
        # This is get Age at SHHS2 against SHHS1 (linked query)
        # GENERATE LINKED SQL
        # 1) Get the Source Join between filter.source and source
        #    This returns table column, table column "the joins" per se....
        if @identifier
          source_identifer_mapping = source.mappings.where( variable_id: @identifier.id ).first
          filter_source_identifer_mapping = filter.source.mappings.where( variable_id: @identifier.id ).first
        end

        if source_identifer_mapping and filter_source_identifer_mapping
          (conditions, table) = generate_sql_through_link(source_identifer_mapping, filter_source_identifer_mapping)
        else
          @errors << "No join found between #{filter.source.name} and #{source.name}."
          return ['1 = 0', nil]
        end

      else
        # Generate Sql as normal
        # This is the same source against the same source
        (conditions, table) = generate_sql_as_normal(source)
      end

      return [conditions, table]
    end

    # 2) Generate AND EVALUATE sql against linked source and SELECT table2.column2 WHERE sql as normal for filter.source (generate_sql_as_normal(filter.source))
    # 3) Build the sql to look like WHERE resolving_source.id IN (linked_ids)
    def generate_sql_through_link(source_identifer_mapping, filter_source_identifer_mapping)
      result_hash = filter.source.sql_codes(current_user)
      sql_open = result_hash[:open]
      sql_close = result_hash[:close]

      wrapper = Aqueduct::Builder.wrapper(filter.source, current_user)

      tables_covered = [filter_source_identifer_mapping.table]

      (more_conditions, another_table) = generate_sql_as_normal(filter.source)

      tables_covered << another_table

      tables_covered = tables_covered.compact.uniq

      join_hash = filter.source.join_conditions(tables_covered, current_user)
      join_hash[:result]
      all_conditions = [join_hash[:result], more_conditions].select{|c| not c.blank?}

      sql_statement = "SELECT #{filter_source_identifer_mapping.table}.#{sql_open}#{filter_source_identifer_mapping.column}#{sql_close} FROM #{tables_covered.join(', ')} WHERE #{all_conditions.join(' and ')}"

      wrapper.connect
      (results, number_of_rows) = wrapper.query(sql_statement)
      wrapper.disconnect

      results.to_a.size > 0 ? ["#{source_identifer_mapping.table}.#{sql_open}#{source_identifer_mapping.column}#{sql_close} IN (#{results.to_a.collect{|r| r.first.kind_of?(String) ? "'" + r.first.gsub("'", "\\\\'") + "'" : r.first.to_s}.join(', ')})", source_identifer_mapping.table] : ["1 = 0", nil]
    end

    # Takes a source and a concept, and generates SQL.
    # Checks for mapping on the same source, otherwise, returns 1 = 0
    def generate_sql_as_normal(thesource)
      result = "1 = 0"

      result_hash = thesource.sql_codes(current_user)
      sql_text = result_hash[:text]
      sql_numeric = result_hash[:numeric]
      sql_open = result_hash[:open]
      sql_close = result_hash[:close]

      # Choose first currently, handle multiple later? would need "table" specified by filter, or mapping chosen explicitly
      mapping = thesource.mappings.where( variable_id: filter.variable_id ).first

      return [result, nil] unless mapping

      mapped_name = mapping.table + '.' + sql_open + mapping.column + sql_close
      values = mapping.abstract_value(filter)

      all_conditions = []

      if values.blank?
        all_conditions << '1 = 0'
      else
        values.each do |val|
          token_hash = filter.find_tokens(val)

          token = token_hash[:token]
          val = token_hash[:val]
          left_token = token_hash[:left_token]
          right_token = token_hash[:right_token]
          range = token_hash[:range]

          if val == nil
            all_conditions << "#{mapped_name} IS NULL"
          elsif val == '1 = 0' or (range.size == 1 and range[0].blank?) or (range.size == 2 and range[0].blank? and range[1].blank?)
            all_conditions << '1 = 0'
          elsif filter.variable.variable_type == 'date'
            if range[0].blank? # From is empty, so every date less or equal to the to date
              all_conditions << "DATE(#{mapped_name}) <= DATE('#{range[1]}')"
            elsif range[1].blank? # To is empty, so every date greater or equal to the from date
              all_conditions << "DATE(#{mapped_name}) >= DATE('#{range[0]}')"
            else
              all_conditions << "DATE(#{mapped_name}) BETWEEN DATE('#{range[0]}') and DATE('#{range[1]}')"
            end
          elsif ['numeric', 'integer'].include?(filter.variable.variable_type)
            numeric_string = sql_numeric.blank? ? "(#{mapped_name}+0.0)" : "CAST(#{mapped_name} AS #{sql_numeric})"
            if range.size == 2
              if left_token.blank? and right_token.blank?
                all_conditions << "#{numeric_string} BETWEEN #{range[0]} and #{range[1]}"
              else
                all_conditions << "#{numeric_string} #{left_token} #{range[0]} and #{numeric_string} #{right_token} #{range[1]}"
              end
            else
              all_conditions << "#{numeric_string} #{token} #{range[0]}"
            end
          else
            all_conditions << "CAST(#{mapped_name} AS #{sql_text}) = #{val}"
          end
        end
      end

      invert_container = (filter.negated? and filter.variable.variable_type != 'choices')
      result = "#{'NOT ' if invert_container}(" + all_conditions.uniq.join(' or ') + ')'

      [result, mapping.table]
    end

end
