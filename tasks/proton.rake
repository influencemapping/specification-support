namespace :proton do
  def parse_proton(*args)
    CSV($stdout, col_sep: "\t") do |csv|
      csv << ['Term']
      parser = RDFParser.new(*args)

      subjects = parser.own_subjects(predicate: RDF.type, object: RDF::OWL.AnnotationProperty) +
        parser.own_subjects(predicate: RDF.type, object: RDF::OWL.DatatypeProperty) +
        parser.own_subjects(predicate: RDF.type, object: RDF::OWL.ObjectProperty)

      subjects.each do |subject|
        csv << [parser.clean_url(subject)]
      end
    end
  end

  desc "Scrapers PROTON Top module properties to CSV"
  task :ptop do
    parse_proton('http://old.ontotext.com/proton/protontop#', namespaces: {
      '' => 'http://www.ontotext.com/proton/protontop#',
    })
  end

  desc "Scrapers PROTON Extension module properties to CSV"
  task :pext do
    parse_proton('http://old.ontotext.com/proton/protonext#', namespaces: {
      '' => 'http://www.ontotext.com/proton/protonext#',
    })
  end
end
