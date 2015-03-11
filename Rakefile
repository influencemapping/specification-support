# coding: utf-8
require 'rubygems'
require 'bundler/setup'

require 'csv'
require 'json'

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

namespace :bio do
  def bio_parser
    RDFParser.new('http://purl.org/vocab/bio/0.1/', namespaces: {
      'rel:' => 'http://purl.org/vocab/relationship/',
      '' => 'http://purl.org/vocab/bio/0.1/',
    })
  end

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
