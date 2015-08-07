namespace :siyazana do
  desc "Scrapes Siyazana classes to CSV"
  task :classes do
    url = 'https://raw.githubusercontent.com/ANCIR/siyazana.co.za/master/data/schema.yaml'

    CSV($stdout, col_sep: "\t") do |csv|
      csv << ['Class', 'Superclass', 'Type' , 'Definition', 'Own properties']
      YAML.load(Faraday.get(url).body).each do |schema|
        # Ignore "hidden", "label", "meta".
        csv << [
          schema['name'],
          schema['parent'],
          schema['obj'],
          schema['description'],
          !schema['attributes'].empty?
        ]
      end
    end
  end

  desc "Scrapes Siyazana properties to CSV"
  task :properties do
    url = 'https://raw.githubusercontent.com/ANCIR/siyazana.co.za/master/data/schema.yaml'

    CSV($stdout, col_sep: "\t") do |csv|
      csv << ['Class', 'Property', 'Label', 'Format']
      YAML.load(Faraday.get(url).body).each do |schema|
        # Ignore "hidden", "label", "service_label", "service_url", "unique".
        schema['attributes'].each do |property|
          csv << [
            schema['name'],
            property['name'],
            property['label'],
            property['datatype'] || property['values'] && property['values'].join(', '),
          ]
        end
      end
    end
  end
end
