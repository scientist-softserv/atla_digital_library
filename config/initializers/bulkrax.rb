Bulkrax.setup do |config|
  config.parsers += [
    { name: 'OAI - Princeton Theological Commons', class_name: 'Bulkrax::OaiPtcParser', partial: 'oai_ptc_fields' },
    { name: 'OAI - Internet Archive', class_name: 'Bulkrax::OaiIaParser', partial: 'oai_ia_fields' },
    { name: 'OAI - Omeka', class_name: 'Bulkrax::OaiOmekaParser', partial: 'oai_omeka_fields' },
    { name: 'CDRI Xml File', class_name: 'Bulkrax::CdriParser', partial: 'cdri_fields' }
  ]

  # Field to use during import to identify if the Work or Collection already exists.
  # Default is 'source'.
  config.system_identifier_field = 'identifier'

  # Field mappings
  # Create a completely new set of mappings by replacing the whole set as follows
  #   config.field_mappings = {
  #     "Bulkrax::OaiDcParser" => { **individual field mappings go here*** }
  #   }
  
  # Add to, or change existing mappings as follows
  #   e.g. to exclude date
  #   config.field_mappings["Bulkrax::OaiDcParser"]["date"] = { from: ["date"], excluded: true  }
  
  # To duplicate a set of mappings from one parser to another
  #   config.field_mappings["Bulkrax::OaiOmekaParser"] = {}
  #   config.field_mappings["Bulkrax::OaiDcParser"].each {|key,value| config.field_mappings["Bulkrax::OaiOmekaParser"][key] = value }

  config.field_mappings = {
    # custom base oai mappings
    "Bulkrax::OaiDcParser" => {
      "contributor" => { from: ["contributor"], split: /\s*[;]\s*/ },
      "place"=>{:from=>["coverage"]},
      "creator" => { from: ["creator"], split: /\s*[;]\s*/ },
      "date" => { from: ["date"], split: /\s*[;]\s*/ },
      "description" => { from: ["description"] },
      "format_digital" => { from: ["format"], parsed: true },
      "identifier" => { from: ["identifier"], if: ['match', /http(s{0,1}):\/\//] },
      "language" => { from: ["language"], split: /\s*[;]\s*/, parsed: true },
      "publisher" => { from: ["publisher"], split: /\s*[;]\s*/ },
      "related_url" => { from: ["relation"], excluded: true },
      "rights_statement" => { from: ["rights"] },
      "source" => { from: ["source"], excluded: true },
      "subject" => { from: ["subject"], split: /\s*[;]\s*/, parsed: true},
      "title" => { from: ["title"] },
      "types" => { from: ["type"], split: /\s*[;]\s*/, parsed: true },
      "remote_files" => { from: ['thumbnail_url'], parsed: true }
    },
    "Bulkrax::CdriParser" => {
      "contributing_institution" => {from: ['publisher'] },
      "creator" => { from: ["creator"], split: true },
      "date" => { from: ['date', 'pub_date'], split: true },
      "language" => { from: ["language"], parsed: true, split: /\s*,\s*/ },
      "subject" => { from: ["subject"], parsed: true },
    },
    "Bulkrax::OaiIaParser" => {},
    "Bulkrax::OaiOmekaParser" => {},
    "Bulkrax::OaiPtcParser" => {},
    "Bulkrax::CsvParser" => {},
    "Bulkrax::OaiQualifiedDcParser" => {}
  }

  # omeka - uses the same mappings as oai
  config.field_mappings["Bulkrax::OaiDcParser"].each {|key,value| config.field_mappings["Bulkrax::OaiOmekaParser"][key] = value }

  # csv - custom mappings
  config.field_mappings["Bulkrax::OaiDcParser"].each {|key,value| config.field_mappings["Bulkrax::CsvParser"][key] = value }
  config.field_mappings["Bulkrax::CsvParser"]["rights_statement"] = { from: ["rights", "rights_statement"] }
  config.field_mappings["Bulkrax::CsvParser"]["types"] = { from: ["type", "types", "resource_type"], split: /\s*[;]\s*/, parsed: true }
  config.field_mappings["Bulkrax::CsvParser"]["format_digital"] = { from: ["format", "format_digital"], parsed: true }
  config.field_mappings["Bulkrax::CsvParser"]["remote_files"] = { from: ["thumbnail_url", "remote_files"], parsed: true }

  # internet archive - custom mappings - exclude contributor and format
  config.field_mappings["Bulkrax::OaiDcParser"].each {|key,value| config.field_mappings["Bulkrax::OaiIaParser"][key] = value }
  config.field_mappings["Bulkrax::OaiIaParser"]["contributor"] = { from: ["contributor"], excluded: true}
  config.field_mappings["Bulkrax::OaiIaParser"]["format_digital"] = { from: ["format"], excluded: true}
  

  # ptc - custom mappings - add date parser, switch format_digital for format_original
  config.field_mappings["Bulkrax::OaiDcParser"].each {|key,value| config.field_mappings["Bulkrax::OaiPtcParser"][key] = value }
  config.field_mappings["Bulkrax::OaiPtcParser"]["format_original"] = { from: ["format"], parsed: true }
  config.field_mappings["Bulkrax::OaiPtcParser"].delete("format_digital")
  config.field_mappings["Bulkrax::OaiPtcParser"]["date"] = { from: ["date"], split: /\s*[;]\s*/ , parsed: true }

  # custom mappings for qdc
  config.field_mappings["Bulkrax::OaiDcParser"].each {|key,value| config.field_mappings["Bulkrax::OaiQualifiedDcParser"][key] = value }
  config.field_mappings["Bulkrax::OaiQualifiedDcParser"]["abstract"] = { from: ["abstract"] }
  config.field_mappings["Bulkrax::OaiQualifiedDcParser"]["alternative_title"] = { from: ["alternative"] }
  config.field_mappings["Bulkrax::OaiQualifiedDcParser"]["date"] = { from: ["date_created", "date"] }
  config.field_mappings["Bulkrax::OaiQualifiedDcParser"]["format_original"] = { from: ['medium'], parsed: true }
  config.field_mappings["Bulkrax::OaiQualifiedDcParser"]["remote_manifest_url"] = { from: ["hasFormat"] }
  config.field_mappings["Bulkrax::OaiQualifiedDcParser"]["time_period"] = { from: ["temporal"], split: /\s*[;]\s*/ }
  config.field_mappings["Bulkrax::OaiQualifiedDcParser"]["extent"] = { from: ["extent"] }
  config.field_mappings["Bulkrax::OaiQualifiedDcParser"]["place"] = { from: ["coverage", "spatial"] }
end
