# coding: utf-8
require 'rubygems'
require 'bundler/setup'

require 'csv'
require 'json'

require 'active_support/inflector'
require 'faraday'
require 'nokogiri'
require 'rdf/turtle'
require 'rdf/rdfxml'

class RDFParser
  attr_reader :graph

  def initialize(url, options = {})
    @namespaces = options.fetch(:namespaces, {
      '' => url,
    })
    @graph = RDF::Graph.load(url)
  end

  def own_subjects(criteria)
    @graph.query(criteria).reject do |statement|
      RDF::Node === statement.subject || statement.subject.qname || @namespaces.any?{|k,v| !k.empty? && statement.subject.pname.start_with?(v)}
    end.map(&:subject)
  end

  def clean_object_url(subject, predicate)
    statements = @graph.query(subject: subject, predicate: predicate).reject do |statement|
      RDF::Node === statement.object || statement.object == RDF::OWL.differentFrom
    end
    if statements.empty?
      'N/A'
    else
      statements.map{|statement| clean_url(statement.object)}.sort.join(', ')
    end
  end

  def clean_object_literal(subject, predicate)
    statements = @graph.query(subject: subject, predicate: predicate).select do |statement|
      statement.object.language == :en
    end

    if statements.empty?
      'N/A'
    else
      statements.map{|statement| statement.object.value}.sort.join(', ')
    end
  end

  def clean_url(url)
    if Array === url
      if url.empty?
        'N/A'
      else
        url.map{|url| clean_url(url)}.sort.join(', ')
      end
    elsif url
      @namespaces.each do |replacement,pattern|
        if url.pname.start_with?(pattern)
          return url.pname.sub(pattern, replacement)
        end
      end
      url.pname
    else
      'N/A'
    end
  end
end

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

namespace :littlesis do
  def xml_to_csv(url, selector)
    CSV($stdout, col_sep: "\t") do |csv|
      csv << ['Class', 'Property']
      Nokogiri::XML(Faraday.get(url).body).xpath(selector).each do |type|
        name = type.xpath('./name').text
        csv << [name]
        type.xpath('./fields').text.split(',').each do |field|
          csv << [name, field]
        end
      end
    end
  end

  desc "Scrapes LittleSis entity types to CSV"
  task :types do
    xml_to_csv('http://api.littlesis.org/entities/types.xml', '//EntityType')
  end

  desc "Scrapes LittleSis relationship categories to CSV"
  task :categories do
    xml_to_csv('http://api.littlesis.org/relationships/categories.xml', '//RelationshipCategory')
  end
end

def filename_to_classname(filename)
  File.basename(filename, File.extname(filename)).underscore.classify.sub(/Schema\z/, '')
end

def json_schema_to_csv(properties, prefix = '')
  data = []
  properties.each do |property,attributes|
    type = if Array === attributes['type']
      attributes['type'].join(', ')
    elsif attributes['type'] == 'array' && attributes['items'].key?('$ref')
      "array<#{filename_to_classname(attributes['items']['$ref'])}>"
    elsif attributes['type'] == 'array' && attributes['items'].key?('name')
      "array<#{filename_to_classname(attributes['items']['name'])}>"
    elsif attributes.key?('$ref')
      "<#{filename_to_classname(attributes['$ref'])}>"
    elsif attributes.key?('anyOf')
      attributes['anyOf'].map{|x| x['type']}.join(', ')
    else
      attributes['type']
    end

    format = if attributes.key?('enum')
      attributes['enum'].compact.sort.map{|value| %("#{value}")}.join(', ')
    elsif attributes.key?('anyOf')
      attributes['anyOf'].map{|x| x['format']}.compact.join(', ')
    elsif attributes.key?('minimum') && attributes.key?('maximum')
      "#{attributes['minimum']}-#{attributes['maximum']}"
    else
      attributes['format']
    end


    data << [
      nil,
      "#{prefix}#{property}",
      type,
      format,
    ]

    if attributes['type'] == 'object'
      data += json_schema_to_csv(attributes['properties'], "#{prefix}#{property}.")
    elsif attributes['type'] == 'array' && attributes['items'].key?('properties')
      subclass = filename_to_classname(attributes['items']['name'])
      data << [subclass, '', '', '']
      data += json_schema_to_csv(attributes['items']['properties']).map do |_,property,type,format|
        [
          subclass,
          property,
          type,
          format,
        ]
      end
    end
  end
  data
end

desc "Scrapes OpenCorporates classes and properties to CSV"
task :opencorporates do
  CSV($stdout, col_sep: "\t") do |csv|
    csv << ['Class', 'Property', 'Type', 'Format', 'Notes', 'URL']

    [ 'company-schema.json',
      # financial-payment-schema.json
      # licence-schema.json
      'primary-data-schema.json',
      # share-parcel-schema.json see company-schema.json
      # simple-financial-payment-schema.json
      # simple-licence-schema.json
      'simple-subsidiary-schema.json',
      'subsidiary-relationship-schema.json',

      'includes/address.json',
      'includes/alternative_name.json',
      # includes/company-for-nesting.json see company-schema.json
      # includes/company.json see company-schema.json
      # includes/entity.json see company-for-nesting.json, person.json, organisation.json, unknown_entity_type.json
      # includes/filing.json
      # includes/financial-payment-data-object.json
      'includes/identifier.json',
      'includes/industry_code.json',
      # includes/licence-data-object.json
      'includes/officer.json',
      # includes/organisation.json see company-schema.json
      # includes/permission.json
      'includes/person.json',
      'includes/person_name.json',
      'includes/previous_name.json',
      # includes/share-parcel-data.json see company-schema.json
      'includes/share-parcel.json',
      'includes/subsidiary-relationship-data.json',
      'includes/total-shares.json',
      # includes/unknown_entity_type.json see company-schema.json
    ].each do |filename|
      url = "https://raw.githubusercontent.com/openc/openc-schema/master/schemas/#{filename}"

      klass = filename_to_classname(filename)
      csv << [klass, '', '', '', '', url]

      schema = JSON.load(Faraday.get(url).body)
      properties = if schema.key?('properties')
        if schema['properties'].key?('properties')
          schema['properties']['properties']['properties']
        else
          schema['properties']
        end
      else
        schema['oneOf'].find{|subschema| subschema.key?('properties')}['properties']
      end

      json_schema_to_csv(properties).each do |subclass,property,type,format|
        csv << [
          subclass || klass,
          property,
          type,
          format,
          '',
          "https://github.com/openc/openc-schema/blob/master/schemas/#{filename}",
        ]
      end
    end
  end
end
