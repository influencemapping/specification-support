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
