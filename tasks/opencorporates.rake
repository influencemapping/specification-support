desc "Scrapes OpenCorporates classes and properties to CSV"
task :opencorporates do
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
