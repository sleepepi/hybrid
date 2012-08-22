module ConceptsHelper

  def link_concepts(concept)
    result = ""
    concept.formula.to_s.split(/\b/).each do |word|
      if c = Concept.find_by_short_name(word)
        result += link_to(word, info_concept_path(c), method: :post, remote: true, title: c.human_name, onclick: "showWaiting('#popup_info', ' Loading Concept', true)")
      else
        result += word
      end
    end
    result.html_safe
  end

end
