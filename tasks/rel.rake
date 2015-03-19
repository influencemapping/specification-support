desc "Scrapers RELATIONSHIP terms to CSV"
task :rel do
  CSV($stdout, col_sep: "\t") do |csv|
    csv << ['Term', 'Definition', 'Domain', 'Range']
    parser = RDFParser.new('http://purl.org/vocab/relationship/')

    subjects = parser.own_subjects(predicate: RDF.type, object: RDF::RDFS.Class) +
      parser.own_subjects(predicate: RDF.type, object: RDF.Property) + 
      parser.own_subjects(predicate: RDF.type, object: RDF::OWL.SymmetricProperty) +
      parser.own_subjects(predicate: RDF.type, object: RDF::OWL.TransitiveProperty)

    subjects.uniq.each do |subject| # can be symmetric and transitive
      csv << [
        parser.clean_url(subject),
        parser.clean_object_literal(subject, RDF::SKOS.definition),
        parser.clean_object_url(subject, RDF::RDFS.domain),
        parser.clean_object_url(subject, RDF::RDFS.range),
      ]
    end
  end
end
