class Report < ActiveRecord::Base
  belongs_to :user
  belongs_to :query

  has_many :report_concepts, -> { order :position }, dependent: :destroy
  has_many :concepts, through: :report_concepts

  def name
    self.read_attribute('name').blank? ? "ID ##{self.id}" : self.read_attribute('name')
  end

  def reorder(column_ids, row_ids)
    # return if (query_concept_ids | self.query_concepts.collect{|qc| qc.id.to_s}).size != self.query_concepts.size or query_concept_ids.size != self.query_concepts.size

    row_ids.each_with_index do |report_concept_id, index|
      self.report_concepts.find_by_id(report_concept_id).update_attributes(position: index + 1, strata: true) if self.report_concepts.find_by_id(report_concept_id)
    end

    column_ids.each_with_index do |report_concept_id, index|
      self.report_concepts.find_by_id(report_concept_id).update_attributes(position: index + 1 + row_ids.size, strata: false) if self.report_concepts.find_by_id(report_concept_id)
    end

    self.reload
  end

  def generate_report_table(current_user)
    filtered_report_concepts = self.report_concepts.select{|rc| not rc.position.blank?}
    result_hash = self.query.view_concept_values(current_user, self.query.sources, filtered_report_concepts.collect{|rc| rc.concept_id}, self.query.query_concepts, [], ["download dataset", "download limited dataset"])

    unless result_hash[:error].blank?
      return {error: result_hash[:error], rows: [], columns: [], values: []}
    end

    values = result_hash[:result][1..-1]

    row_values = []
    filtered_report_concepts.each_with_index do |rc, index|
      if rc.statistic == 'year' and rc.strata?
        values.each{|v| v[index] = v[index].year if v[index].kind_of?(Date) or v[index].kind_of?(Time)}
      elsif (rc.statistic == 'month' or rc.statistic.blank?) and rc.concept and rc.concept.date? and rc.strata?
        values.each{|v| v[index] = "#{v[index].year} Month #{'%02d' % v[index].month}" if v[index].kind_of?(Date) or v[index].kind_of?(Time)}
      elsif rc.statistic == 'week' and rc.strata?
        values.each{|v| v[index] = "#{v[index].year} Week #{'%02d' % v[index].to_date.cweek}" if v[index].kind_of?(Date) or v[index].kind_of?(Time)}
      elsif rc.statistic == 'day' and rc.strata?
        values.each{|v| v[index] = v[index].strftime("%Y-%m-%d") if v[index].kind_of?(Date) or v[index].kind_of?(Time)}
      end

      if rc.strata?
        row_values[index] = values.collect{|v| v[index]}.uniq.partition{|x| x.is_a? String}.map{|i| i.sort{|a,b| a.to_s <=> b.to_s}}.flatten
      end
    end

    columns = []

    filtered_report_concepts.each_with_index do |rc, index|
      if rc.strata?
        columns << [rc.id, 'strata']
      elsif rc.concept and rc.concept.continuous?
        if rc.statistic == 'all' or rc.statistic.blank?
          columns << [rc.id, 'min']
          columns << [rc.id, 'avg']
          columns << [rc.id, 'max']
        else
          columns << [rc.id, rc.statistic]
        end
      elsif rc.concept and (rc.concept.boolean? or rc.concept.categorical?)
        values.collect{|v| v[index]}.uniq.partition{|x| x.is_a? String}.map{|i| i.sort{|a,b| a.to_s <=> b.to_s}}.flatten.each do |val|
          if rc.statistic == 'all' or rc.statistic.blank?
            columns << [rc.id, "#{val} (count)"]
            columns << [rc.id, "#{val} (%)"]
          elsif rc.statistic == 'percent'
            columns << [rc.id, "#{val} (%)"]
          elsif rc.statistic == 'count'
            columns << [rc.id, "#{val} (count)"]
          else
            columns << [rc.id, "#{val} #{rc.statistic}"]
          end
          # columns << [rc.id, val]
        end
      elsif rc.concept and rc.concept.date?
        if rc.statistic == 'day'
          values.collect{|v| v[index]}.compact.collect{|d| d.strftime("%Y-%m-%d")}.uniq.sort.each{ |val| columns << [rc.id, "#{val} (count)"] }
        elsif rc.statistic == 'week'
          values.collect{|v| v[index]}.compact.collect{|d| "#{d.year} Week #{'%02d' % d.to_date.cweek}"}.uniq.sort.each{ |val| columns << [rc.id, "#{val} (count)"] }
        elsif rc.statistic == 'month' or rc.statistic.blank?
          values.collect{|v| v[index]}.compact.collect{|d| "#{d.year} Month #{'%02d' % d.month}"}.uniq.sort.each{ |val| columns << [rc.id, "#{val} (count)"] }
        elsif rc.statistic == 'year'
          values.collect{|v| v[index]}.compact.collect{|d| d.year}.uniq.sort.each{ |val| columns << [rc.id, "#{val} (count)"] }
        end
      else
        columns << [rc.id, rc.statistic]
      end
    end
    columns << [nil, 'count']
    columns << [nil, '%']

    rows = []
    tmp_rows = []
    row_values.each_with_index do |row_value, index|
      if rows == []
        rows = row_value.collect{|i| [i]}
      else
        tmp_rows = Array.new(rows)
        rows = []
        tmp_rows.collect{|i| row_value.collect{|j| rows << [i,j].flatten}}
      end
    end

    rows << []

    return { rows: rows, columns: columns, values: values }
  end

  def finalize_report_table(current_user, include_html = true)

    result_hash = self.generate_report_table(current_user)

    values = result_hash[:values]
    columns = result_hash[:columns]
    rows = result_hash[:rows]

    master_table = []
    # master_table =
    # [
    #   [Gender, Age Min, Age Max, Age Avg, Total]
    #   [Male,        20,      50,      30,   200]
    #   [Female,      18,      60,      45,   150]
    #   [Total,       18,      60,      35,   350]
    # ]

    if result_hash[:error].blank?

      # Create the header columns:
      header_row = []
      columns.each_with_index do |(report_concept_id, statistic), index|
        report_concept = ReportConcept.find_by_id(report_concept_id)
        if report_concept
          header_row[index] = (report_concept.concept ? report_concept.concept.human_name : report_concept.external_concept_information(current_user)[:name])
        else
          header_row[index] = 'Total'
        end
        if report_concept = ReportConcept.find_by_id(report_concept_id) and c = Concept.find_by_short_name(statistic)
          header_row[index] = header_row[index].to_s + " - " + c.human_name
        else
          header_row[index] = [header_row[index], ((statistic.blank? or statistic == 'strata') ? nil :  statistic.to_s.titleize)].compact.join(" - ")
        end
      end
      master_table << header_row

      # Create the body
      rows.each_with_index do |strata, row_index|
        body_row = []

        results = Array.new(values)
        orig_results_size = results.size
        strata.each_with_index do |stratum, s_index|
          results.select!{|item| item[s_index] == stratum}
        end
        strata_results_size = results.size

        columns.each_with_index do |(report_concept_id, statistic), index|
          if index == 0 and row_index == rows.size - 1 and statistic == 'strata'
            body_row[index] = "Total"
          elsif rows.size > 1 and row_index == rows.size - 1 and statistic == 'strata'
            body_row[index] = "---"
          elsif strata[index]
            if c = Concept.find_by_short_name(strata[index])
              body_row[index] = c.human_name
            else
              body_row[index] = strata[index]
            end
          else
            filtered_results = Array.new(results)
            if report_concept = ReportConcept.find_by_id(report_concept_id)
              filtered_results.collect!{|item| item[report_concept.position - 1]}
            end

            if report_concept = ReportConcept.find_by_id(report_concept_id)
              if report_concept.concept and (report_concept.concept.categorical? or report_concept.concept.boolean?)
                filtered_results.select!{|item| item.to_s == statistic.to_s.split(' ')[0..-2].join(' ')}
              elsif report_concept.concept and report_concept.concept.date?
                if report_concept.statistic == 'day'
                  filtered_results.select!{|d| (d.kind_of?(Date) or d.kind_of?(Time)) and d.strftime("%Y-%m-%d") == statistic.to_s.split(' ')[0..-2].join(' ')}
                elsif report_concept.statistic == 'week'
                  filtered_results.select!{|d| (d.kind_of?(Date) or d.kind_of?(Time)) and "#{d.year} Week #{'%02d' % d.to_date.cweek}" == statistic.to_s.split(' ')[0..-2].join(' ')}
                elsif report_concept.statistic == 'month' or report_concept.statistic.blank?
                  filtered_results.select!{|d| (d.kind_of?(Date) or d.kind_of?(Time)) and "#{d.year} Month #{'%02d' % d.month}" == statistic.to_s.split(' ')[0..-2].join(' ')}
                elsif report_concept.statistic == 'year'
                  filtered_results.select!{|d| (d.kind_of?(Date) or d.kind_of?(Time)) and "#{d.year}" == statistic.to_s.split(' ')[0..-2].join(' ')}
                end
              end
            end

            filtered_results = filtered_results.select{|val| not val.blank?}.collect{|val| val.to_f} if ['min', 'max', 'avg'].include?(statistic)

            if statistic == 'min'
              body_row[index] = (filtered_results.compact.size > 0) ? (filtered_results.compact.min).round(1) : 'n/a'
            elsif statistic == 'max'
              body_row[index] = (filtered_results.compact.size > 0) ? (filtered_results.compact.max).round(1) : 'n/a'
            elsif statistic == 'avg'
              body_row[index] = (filtered_results.compact.size > 0) ? (filtered_results.compact.sum.to_f / filtered_results.compact.size).round(1) : 'n/a'
            elsif statistic == 'count'
              body_row[index] = filtered_results.size
            elsif statistic == '%'
              if orig_results_size > 0
                body_row[index] = (include_html ? color_for_number((filtered_results.size.to_f / orig_results_size * 100), "#{(filtered_results.size.to_f / orig_results_size * 100).round(1)}%") : "#{(filtered_results.size.to_f / orig_results_size * 100).round(1)}%")
              else
                body_row[index] = "---"
              end
            elsif report_concept = ReportConcept.find_by_id(report_concept_id) and report_concept.concept and (report_concept.concept.categorical? or report_concept.concept.boolean? or report_concept.concept.date?)
              if statistic.to_s.split(' ').last == '(count)'
                body_row[index] = filtered_results.size
              elsif statistic.to_s.split(' ').last == '(%)'
                if strata_results_size > 0
                  body_row[index] = (include_html ? color_for_number((filtered_results.size.to_f / strata_results_size * 100), "#{(filtered_results.size.to_f / strata_results_size * 100).round(1)}%") : "#{(filtered_results.size.to_f / strata_results_size * 100).round(1)}%")
                else
                  body_row[index] = "---"
                end
              else
                body_row[index] = filtered_results.size
                body_row[index] = body_row[index].to_s + ' ' + color_for_number((filtered_results.size.to_f / strata_results_size * 100), "#{(filtered_results.size.to_f / strata_results_size * 100).round(1)}%") if strata_results_size > 0 and include_html
              end
            else
              body_row[index] = "---"
            end
          end
        end

        master_table << body_row unless strata_results_size == 0
      end
    end

    result_hash[:error] = "No report was generated since the associated query is returning 0 results.  Please modify your query and then reload the report." if result_hash[:error].blank? and values.blank?

    { result: master_table, error: result_hash[:error] }
  end

  def color_for_number(number, label)
    colors = ['ff0033', 'ff3333', 'ff6633', 'ff9933', 'E59A00', 'FDB500', '92E400', '3CD600', '3DF400', '33cc00', '00cc00']
    color_size = 11

    if number == 0
      color = 'AAAAAA'
    elsif number == 100
      color = '0066ff'
    else
      color = colors[number.to_i / (colors.size - 1)]
    end

    "<span style=\"color:##{color}\" class='percent'>#{label}</span>".html_safe
  end

end
