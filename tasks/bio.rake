namespace :bio do
  def bio_parser
    RDFParser.new('http://purl.org/vocab/bio/0.1/', namespaces: {
      'rel:' => 'http://purl.org/vocab/relationship/',
      '' => 'http://purl.org/vocab/bio/0.1/',
    })
  end

  desc "Scrapes BIO classes to CSV"
  task :classes do
    CSV($stdout, col_sep: "\t") do |csv|
      csv << ['Class', 'Definition']
      parser = bio_parser

      parser.own_subjects(predicate: RDF.type, object: RDF::OWL.Class).each do |subject|
        csv << [
          parser.clean_url(subject),
          parser.clean_object_literal(subject, RDF::RDFS.comment),
        ]
      end
    end
  end

  desc "Scrapes BIO properties to CSV"
  task :properties do
    CSV($stdout, col_sep: "\t") do |csv|
      csv << ['Property', 'Definition', 'Domain', 'Range', 'Superproperty']
      parser = bio_parser

      parser.own_subjects(predicate: RDF.type, object: RDF.Property).each do |subject|
        csv << [
          parser.clean_url(subject),
          parser.clean_object_literal(subject, RDF::RDFS.comment),
          parser.clean_object_url(subject, RDF::RDFS.domain),
          parser.clean_object_url(subject, RDF::RDFS.range),
          parser.clean_object_url(subject, RDF::RDFS.subPropertyOf),
        ]
      end
    end
  end
end
