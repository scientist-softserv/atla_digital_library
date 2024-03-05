module Bulkrax
  class CdriWorkEntry < Entry
    def initialize(attrs = {})
      super(attrs)
      self.identifier ||= raw_metadata_xml['ComponentID'].to_s if raw_metadata.present?
    end

    def self.get_identifier(raw_metadata)
      new(raw_metadata: raw_metadata).identifier
    end

    def collection
      @collection ||= Collection.find(collection_ids.first) if collection_ids.present?
    end

    def files_path
      File.join(parser.parser_fields['upload_path'], collection.name_code.first)
    end

    def factory
      @factory ||= Bulkrax::ObjectFactory.new(attributes: self.parsed_metadata,
        source_identifier_value: identifier,
        work_identifier: parser.work_identifier,
        work_identifier_search_field: parser.work_identifier_search_field,
        related_parents_parsed_mapping: parser.related_parents_parsed_mapping,
        user: user,
        klass: factory_class,
        importer_run_id: importerexporter.last_run.id,
        )
    end

    def factory_class
      Work
    end

    def raw_metadata_xml
      @raw_metadata_xml ||= Nokogiri::XML.fragment(raw_metadata).elements.first
    end

    def build_metadata
      self.parsed_metadata = {}
      raw_metadata_xml.each_with_object({}) do |(key, value), _hash|
        clean_key = key.gsub(/component/i, '').gsub(/\d+/, '').underscore.downcase
        next if clean_key == 'id'
        val = value.respond_to?(:value) ? value.value : value
        add_metadata(clean_key, val)
      end

      # remove any unsupported attributes
      object = factory_class.new
      self.parsed_metadata = parsed_metadata.select do |key, _value|
        object.respond_to?(key.to_sym)
      end

      add_visibility
      add_rights_statement
      add_collections

      if raw_metadata_xml["ComponentFileName"].present?
        parsed_metadata['file'] =
          [File.join(files_path, raw_metadata_xml["ComponentFileName"].downcase)]
      end
      parsed_metadata[work_identifier] ||= [self.identifier]
      parsed_metadata['has_manifest'] = "1"
      parsed_metadata
    end
  end
end
