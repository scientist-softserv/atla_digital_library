Bulkrax.setup do |config|
  config.parsers += [
    { name: 'OAI - Princeton Theological Commons', class_name: 'Bulkrax::OaiPtcParser', partial: 'oai_ptc_fields' },
    { name: 'OAI - Internet Archive', class_name: 'Bulkrax::OaiIaParser', partial: 'oai_ia_fields' },
    { name: 'OAI - Manual Sets', class_name: 'Bulkrax::OaiSetsParser', partial: 'oai_sets_fields' },
    { name: 'OAI - Omeka', class_name: 'Bulkrax::OaiOmekaParser', partial: 'oai_omeka_fields' },
    { name: 'CDRI Xml File', class_name: 'Bulkrax::CdriParser', partial: 'cdri_fields' }
  ]

  config.parsers -= [
    { name: "Bagit", class_name: "Bulkrax::BagitParser", partial: "bagit_fields" }
  ]

  config.default_work_type = 'Work'

  # Field to use during import to identify if the Work or Collection already exists.
  # Default is 'source'; defined in #work_identifier.
  # config.system_identifier_field = 'identifier'

  # Field mappings
  # Create a completely new set of mappings by replacing the whole set as follows
  #   config.field_mappings = {
  #     "Bulkrax::OaiDcParser" => { **individual field mappings go here*** }
  #   }

  # Add to, or change existing mappings as follows
  #   e.g. to exclude date
  #   config.field_mappings["Bulkrax::OaiDcParser"]["date"] = { from: ["date"], excluded: true }

  default_field_mapping = {
    'contributor' => { from: ['contributor'], split: /\s*[;]\s*/ },
    'contributing_institution' => { from: ['source'] },
    'creator' => { from: ['creator'], split: /\s*[;]\s*/ },
    'date' => { from: ['date'], split: /\s*[;]\s*/ },
    'description' => { from: ['description'] },
    'format_digital' => { from: ['format'], parsed: true, split: /\s*[;]\s*/ },
    'identifier' => { from: ['identifier'], if: ['match?', /http(s{0,1}):\/\//], source_identifier: true, search_field: 'identifier_tesim' },
    'language' => { from: ['language'], split: /\s*[;]\s*/, parsed: true },
    'place'=>{:from=>['coverage'], split: /\s*[;]\s*/ },
    'publisher' => { from: ['publisher'], split: /\s*[;]\s*/ },
    'remote_files' => { from: ['thumbnail_url'], parsed: true },
    'related_url' => { from: ['relation'], excluded: true },
    'rights_statement' => { from: ['rights'], split: /\s*[;]\s*/ },
    'subject' => { from: ['subject'], split: /\s*[;]\s*/, parsed: true },
    'title' => { from: ['title'] },
    'types' => { from: ['type'], split: /\s*[;]\s*/, parsed: true }
  }

  config.field_mappings['Bulkrax::CdriParser'] = {
    'contributing_institution' => {from: ['publisher'] },
    'creator' => { from: ['creator'], split: /\s*[;]\s*/ },
    'date' => { from: ['date', 'pub_date'], split: /\s*[;]\s*/ },
    'language' => { from: ['language'], parsed: true, split: /\s*,\s*/ },
    'subject' => { from: ['subject'], parsed: true, split: /\s*[;]\s*/ }
  }

  config.field_mappings['Bulkrax::CsvParser'] = default_field_mapping.merge({
    'abstract' => { from: ['abstract'], excluded: true },
    'alternative_title' => { from: ['alternative_title'], split: /\s*[;]\s*/ },
    'children' => { from: ['children'], related_children_field_mapping: true },
    'contributing_institution' => { from: ['contributing_institution'], split: /\s*[;]\s*/ },
    'extent' => { from: ['extent'], split: /\s*[;]\s*/ },
    'format_digital' => { from: ['format', 'format_digital'], parsed: true, split: /\s*[;]\s*/ },
    'format_original' => { from: ['format_original'], split: /\s*[;]\s*/, parsed: true },
    'has_manifest' => { from: ['has_manifest'] },
    'parents' => { from: ['parents'], related_parents_field_mapping: true },
    'place' => { from: ['place'], split: /\s*[;]\s*/ },
    'remote_files' => { from: ['thumbnail_url', 'remote_files'], parsed: true },
    'remote_manifest_url' => { from: ['remote_manifest_url'], split: /\s*[;]\s*/ },
    'rights_holder' => { from: ['rights_holder'], split: /\s*[;]\s*/ },
    'rights_statement' => { from: ['rights', 'rights_statement'], split: /\s*[;]\s*/ },
    'time_period' => { from: ['time_period'], split: /\s*[;]\s*/ },
    'types' => { from: ['type', 'types', 'resource_type'], split: /\s*[;]\s*/, parsed: true }
  })

  config.field_mappings['Bulkrax::OaiDcParser'] = default_field_mapping.merge({
    # add, remove or override custom mappings for this parser here
  })

  config.field_mappings['Bulkrax::OaiIaParser'] = default_field_mapping.merge({
    'contributor' => { from: ['contributor'], excluded: true },
    'date' => { from: ['date'], parsed: true, split: /\s*[;]\s*/ },
    'format_digital' => { from: ['format'], excluded: true }
  })

  config.field_mappings['Bulkrax::OaiOmekaParser'] = default_field_mapping.merge({
    # add, remove or override custom mappings for this parser here
  })

  config.field_mappings['Bulkrax::OaiPtcParser'] = default_field_mapping.merge({
    'format_original' => { from: ['format'], parsed: true, split: /\s*[;]\s*/ }
  })
  # switch format_digital for format_original
  config.field_mappings['Bulkrax::OaiPtcParser'].delete('format_digital')

  config.field_mappings['Bulkrax::OaiSetsParser'] = default_field_mapping.merge({
    # add, remove or override custom mappings for this parser here
  })

  config.field_mappings['Bulkrax::OaiQualifiedDcParser'] = default_field_mapping.merge({
    'abstract' => { from: ['abstract'], excluded: true },
    'alternative_title' => { from: ['alternative'], split: /\s*[;]\s*/ },
    'date' => { from: ['date_created', 'date'], split: /\s*[;]\s*/ },
    'extent' => { from: ['extent'], split: /\s*[;]\s*/ },
    'format_original' => { from: ['medium'], parsed: true, split: /\s*[;]\s*/ },
    'place' => { from: ['coverage', 'spatial'], split: /\s*[;]\s*/ },
    'remote_files' => { from: ['thumbnail_url', 'hasVersion', 'dcterms:hasVersion'], parsed: true },
    'remote_manifest_url' => { from: ['hasFormat'] },
    'rights_holder' => { from: ['rightsHolder'] },
    'time_period' => { from: ['temporal'], split: /\s*[;]\s*/ },
    'transcript_url' => { from: ['transcript'] }
  })
end

# Verify that scheduled jobs get created when needed
begin
i = Bulkrax::Importer.where('frequency <> ?', 'PT0S')
i.each do |importer|
  if importer.schedulable? && Delayed::Job.find_by('handler LIKE ? AND handler LIKE ?', "job_class: Bulkrax::ImporterJob", importer.to_gid.to_s)
    Bulkrax::ImporterJob.set(wait_until: importer.next_import_at).perform_later(importer.id, true)
  end
end
rescue => e
  puts "Bulkrax Importers not scheduled #{e.message}"
end
