namespace :poder do
  def poder_parser
    RDFParser.new('https://raw.githubusercontent.com/poderopedia/PoderVocabulary/master/schema.ttl', namespaces: {
      'bio:' => 'http://purl.org/vocab/bio/0.1/',
      '' => 'http://poderopedia.com/vocab/',
    })
  end

  desc "Scrapes PoderVocabulary classes to CSV"
  task :classes do
    CSV($stdout, col_sep: "\t") do |csv|
      csv << ['Class', 'Superclass', 'Definition', 'Own properties']
      parser = poder_parser

      subjects = parser.graph.query(predicate: RDF.type, object: RDF::OWL.Class).map(&:subject) +
        # WorkRole subclasses.
        parser.graph.query(predicate: RDF.type, object: RDF::URI.new('http://poderopedia.com/vocab/WorkRole')).map(&:subject) +
        # Undeclared classes.
        parser.graph.subjects.reject{|subject| parser.graph.first(subject: subject, predicate: RDF.type)}

      subjects.each do |subject|
        csv << [
          parser.clean_url(subject),
          parser.clean_object_url(subject, RDF::RDFS.subClassOf),
          parser.clean_object_literal(subject, RDF::RDFS.comment),
          parser.clean_url(parser.own_subjects(predicate: RDF::RDFS.domain, object: subject)),
        ]
      end
    end
  end

  desc "Scrapes PoderVocabulary properties to CSV"
  task :properties do
    CSV($stdout, col_sep: "\t") do |csv|
      csv << ['Property', 'Superproperty', 'Domain', 'Range', 'Definition']
      parser = poder_parser

      parser.own_subjects(predicate: RDF.type, object: RDF.Property).each do |subject|
        csv << [
          parser.clean_url(subject),
          parser.clean_object_url(subject, RDF::RDFS.subPropertyOf),
          parser.clean_object_url(subject, RDF::RDFS.domain),
          parser.clean_object_url(subject, RDF::RDFS.range),
          parser.clean_object_literal(subject, RDF::RDFS.comment),
        ]
      end
    end
  end
end
