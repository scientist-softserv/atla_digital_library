# Generated via
#  `rails generate hyrax:work Work`
module Hyrax
  class WorkPresenter < Hyrax::WorkShowPresenter
    delegate :title, :date_created, :description,
             :creator, :contributor, :subject, :date, :publisher, :language, :embargo_release_date,
             :lease_expiration_date, :license, :source, :rights_statement, :rights_holder, :thumbnail_id, :representative_id,
             :rendering_ids, :member_of_collection_ids, :contributing_institution, :place, :extent, :format_original,
             :format_digital, :time_period, :alternative_title, :types, :remote_manifest_url, :has_manifest, :ancestor_collection_ids,
             :ancestor_relationships,

             to: :solr_document

    def iiif_viewer?
      has_manifest.present? &&
        has_manifest.first == "1" &&
        representative_id.present? &&
        representative_presenter.present? &&
        representative_presenter.image? &&
        Hyrax.config.iiif_image_server? &&
        members_include_viewable_image?
    end
    alias universal_viewer? iiif_viewer?

    def ancestor_collections
      Collection.where(id: self.ancestor_collection_ids)
    end

    # use this to select urls from identifier
    def url
      solr_document.identifier.select {|i| i.match('http')}
    end

  end
end
