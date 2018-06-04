module OAI::QualifiedDC
  class RecordParser < OAI::Base::RecordParser
    matcher 'alternative_title', from: ['alternative', 'alternative_title'], split: true
    matcher 'collection', from: ['relation', 'isPartOf'], if: ->(parser, content) { parser.all }
    matcher 'contributor', split: true
    matcher 'creator', split: true
    matcher 'date', from: ['date', 'created'], split: true
    matcher 'description'
    matcher 'extent'
    matcher 'format_digital', from: ['format_digital', 'format'], parsed: true
    matcher 'format_original', from: ['medium']
    matcher 'language', parsed: true, split: true
    matcher 'original_url', from: ['identifier'], if: ->(parser, content) { content.match(/http(s+):\/\//) }
    matcher 'place', from: ['coverage', 'spatial']
    matcher 'publisher', split: true
    matcher 'rights_holder', from: ['rights_holder', 'rightsHolder']
    matcher 'subject', split: true
    matcher 'time_period', from: ['time_period', 'temporal'], split: true
    matcher 'title', split: true
    matcher 'types', from: ['types', 'type'], split: true
  end
end