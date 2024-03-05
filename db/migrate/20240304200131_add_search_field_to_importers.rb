class AddSearchFieldToImporters < ActiveRecord::Migration[5.2]
  def change
    Bulkrax::Importer.find_each do |i|
      i.field_mapping['identifier']["search_field"] = "identifier_tesim" if i.field_mapping&.[]('identifier')&.[]("search_field")
      i.save
    end
  end
end
