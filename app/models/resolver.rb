class Resolver

  attr_reader :conditions, :tables, :position, :errors

  def initialize(query_concept, source, current_user)
    @position = query_concept.id
    @query_concept = query_concept
    @source = source
    @current_user = current_user
    @errors = []
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
    "("*query_concept.left_brackets + conditions + ")"*query_concept.right_brackets + (query_concept.position < (query_concept.query.query_concepts.size - 1) ? " #{query_concept.right_operator}" : '')
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

    def query_concept
      @query_concept
    end

    def construct_conditions
      unless query_concept.concept
        @errors << "No Concept Selected with Query Concept"
        return ['1 = 0', nil]
      end

      if query_concept.source and query_concept.source != source
        # This is get Age at SHHS2 against SHHS1 (linked query)
        # GENERATE LINKED SQL
        # 1) Get the Source Join between query_concept.source and source
        #    This returns table column, table column "the joins" per se....
        source_join = SourceJoin.where( source_id: source.id, source_to_id: query_concept.source.id ).first
        rev_join = SourceJoin.where( source_id: query_concept.source.id, source_to_id: source.id ).first
        if source_join
          table = source_join.from_table
          column = source_join.from_column
          table2 = source_join.to_table
          column2 = source_join.to_column
        elsif rev_join
          table = rev_join.to_table
          column = rev_join.to_column
          table2 = rev_join.from_table
          column2 = rev_join.from_column
        else
          @errors << "No join found between #{query_concept.source.name} and #{source.name}."
          return ['1 = 0', nil]
        end


        (conditions, table) = generate_sql_through_link(table, column, table2, column2)
      else
        # Generate Sql as normal
        # This is the same source against the same source
        (conditions, table) = generate_sql_as_normal(source)
      end

      return [conditions, table]
    end

    # 2) Generate AND EVALUATE sql against linked source and SELECT table2.column2 WHERE sql as normal for query_concept.source (generate_sql_as_normal(query_concept.source))
    # 3) Build the sql to look like WHERE resolving_source.id IN (linked_ids)
    def generate_sql_through_link(table, column, table2, column2)
      result_hash = query_concept.source.sql_codes(current_user)
      sql_open = result_hash[:open]
      sql_close = result_hash[:close]

      wrapper = Aqueduct::Builder.wrapper(query_concept.source, current_user)

      tables_covered_by_concepts = [table2]

      (more_conditions, another_table) = generate_sql_as_normal(query_concept.source)

      tables_covered_by_concepts << another_table

      tables_covered_by_concepts = tables_covered_by_concepts.compact.uniq

      join_hash = query_concept.source.join_conditions(tables_covered_by_concepts, current_user)
      join_hash[:result]
      all_conditions = [join_hash[:result], more_conditions].select{|c| not c.blank?}

      sql_statement = "SELECT #{table2}.#{sql_open}#{column2}#{sql_close} FROM #{tables_covered_by_concepts.join(', ')} WHERE #{all_conditions.join(' and ')}"

      wrapper.connect
      (results, number_of_rows) = wrapper.query(sql_statement)
      wrapper.disconnect

      results.to_a.size > 0 ? ["#{table}.#{sql_open}#{column}#{sql_close} IN (#{results.to_a.collect{|r| r.first.kind_of?(String) ? "'" + r.first.gsub("'", "\\\\'") + "'" : r.first.to_s}.join(', ')})", table] : ["1 = 0", nil]
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

      # Choose first currently, handle multiple later? would need "table" specified by query_concept, or mapping chosen explicitly
      mapping = thesource.mappings.where(concept_id: query_concept.concept.id).first

      return [result, nil] unless mapping

      mapped_name = mapping.table + '.' + sql_open + mapping.column + sql_close
      values = mapping.abstract_value(query_concept)

      all_conditions = []

      if values.blank?
        all_conditions << '1 = 0'
      else
        values.each do |val|
          token_hash = query_concept.find_tokens(val)

          token = token_hash[:token]
          val = token_hash[:val]
          left_token = token_hash[:left_token]
          right_token = token_hash[:right_token]
          range = token_hash[:range]

          if val == nil
            all_conditions << "#{mapped_name} IS NULL"
          elsif val == '1 = 0' or (range.size == 1 and range[0].blank?) or (range.size == 2 and range[0].blank? and range[1].blank?)
            all_conditions << '1 = 0'
          elsif query_concept.concept.date?
            if range[0].blank? # From is empty, so every date less or equal to the to date
              all_conditions << "DATE(#{mapped_name}) <= DATE('#{range[1]}')"
            elsif range[1].blank? # To is empty, so every date greater or equal to the from date
              all_conditions << "DATE(#{mapped_name}) >= DATE('#{range[0]}')"
            else
              all_conditions << "DATE(#{mapped_name}) BETWEEN DATE('#{range[0]}') and DATE('#{range[1]}')"
            end
          elsif query_concept.concept.continuous?
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

      invert_container = (query_concept.negated? and not (query_concept.concept.boolean? or query_concept.concept.categorical?))
      result = "#{'NOT ' if invert_container}(" + all_conditions.uniq.join(' or ') + ')'

      [result, mapping.table]
    end

end
