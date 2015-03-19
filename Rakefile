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

Dir['tasks/*.rake'].each { |r| import r }
