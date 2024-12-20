class CatalogController < ApplicationController
  include BlacklightRangeLimit::ControllerOverride
  include Hydra::Catalog
  include Hydra::Controller::ControllerBehavior

  # This filter applies the hydra access controls
  before_action :enforce_show_permissions, only: :show

  ## UPGRADE NOTE
  # This method serves as a collections index page by using Blacklight search functionality and
  # filtering by type Collection. See here in the Blacklight gem for location of original method:
  # app/controllers/concerns/blacklight/catalog.rb#L24
  def collections_index
    (@response, @document_list) = search_results(params.merge({ "f": { "human_readable_type_sim": ["Collection"] } }))

    respond_to do |format|
      format.html { store_preferred_view }
      format.rss  { render :layout => false }
      format.atom { render :layout => false }
      format.json do
        @presenter = Blacklight::JsonPresenter.new(@response,
                                                   @document_list,
                                                   facets_from_request,
                                                   blacklight_config)
      end
      additional_response_formats(format)
      document_export_formats(format)
    end
  end

  def self.uploaded_field
    solr_name('system_create', :stored_sortable, type: :date)
  end

  def self.modified_field
    solr_name('system_modified', :stored_sortable, type: :date)
  end

  configure_blacklight do |config|
    config.show.tile_source_field = :content_metadata_image_iiif_info_ssm
    config.show.partials.insert(1, :openseadragon)
    # config.search_builder_class = Hyrax::CatalogSearchBuilder

    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = {
      qt: "search",
      rows: 10
    }

    # solr field configuration for document/show views
    config.index.title_field = solr_name("title", :stored_searchable)
    config.index.display_type_field = solr_name("has_model", :symbol)
    config.index.thumbnail_field = 'thumbnail_path_ss'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    config.add_facet_field solr_name("types", :facetable), label: "Type", limit: 10, collapse: false
    config.add_facet_field solr_name("subject", :facetable), label: "Subject", limit: 10, solr_params: { 'facet.mincount' => 2 }
    # config.add_facet_field solr_name("date", :facetable), label: "Date", limit: 10
    config.add_facet_field solr_name('date', :facetable), label: 'Date', range: { facet_field_label: 'Date Range', num_segments: 10, assumed_boundaries: [1100, Time.now.year + 2], segments: false, slider_js: false, maxlength: 4 }, facet_field_label: 'Date Range'
    config.add_facet_field solr_name("place", :facetable), label: "Place", limit: 10
    config.add_facet_field solr_name("language", :facetable), label: "Language", limit: 10
    config.add_facet_field solr_name("extent", :facetable), label: "Extent", limit: 5, show: false
    config.add_facet_field solr_name("format_original", :facetable), label: "Format (Original)", limit: 10
    config.add_facet_field solr_name("format_digital", :facetable), label: "Format (Digital)", limit: 10
    config.add_facet_field solr_name('member_of_collections', :symbol), limit: 5
    config.add_facet_field solr_name("contributing_institution", :facetable), label: "Contributing Institution", limit: 10
    # config.add_facet_field solr_name("creator", :facetable), label: "Creator", limit: 5
    # config.add_facet_field solr_name("resource_type", :facetable), label: "Resource Type", limit: 5
    # config.add_facet_field solr_name("contributor", :facetable), label: "Contributor", limit: 5
    # config.add_facet_field solr_name("keyword", :facetable), limit: 5
    # config.add_facet_field solr_name("subject", :facetable), limit: 5
    # config.add_facet_field solr_name("language", :facetable), limit: 5
    # config.add_facet_field solr_name("based_near_label", :facetable), limit: 5
    # config.add_facet_field solr_name("publisher", :facetable), limit: 5
    # config.add_facet_field solr_name("file_format", :facetable), limit: 5
    # config.add_facet_field solr_name("publisher", :facetable), label: "Publisher", limit: 5
    # config.add_facet_field solr_name("time_period", :facetable), label: "Time Period", limit: 5
    # config.add_facet_field solr_name("human_readable_type", :facetable), label: "Type", limit: 5

    # The generic_type isn't displayed on the facet list
    # It's used to give a label to the filter that comes from the user profile
    config.add_facet_field solr_name("generic_type", :facetable), if: false

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field solr_name("title", :stored_searchable), label: "Title", itemprop: 'name', if: false
    # config.add_index_field solr_name("description", :stored_searchable), itemprop: 'description', helper_method: :iconify_auto_link
    # config.add_index_field solr_name("keyword", :stored_searchable), itemprop: 'keywords', link_to_search: solr_name("keyword", :facetable)
    # config.add_index_field solr_name("subject", :stored_searchable), itemprop: 'about', link_to_search: solr_name("subject", :facetable)
    # config.add_index_field solr_name("creator", :stored_searchable), itemprop: 'creator', link_to_search: solr_name("creator", :facetable)
    # config.add_index_field solr_name("contributor", :stored_searchable), itemprop: 'contributor', link_to_search: solr_name("contributor", :facetable)
    # config.add_index_field solr_name("proxy_depositor", :symbol), label: "Depositor", helper_method: :link_to_profile
    # config.add_index_field solr_name("depositor"), label: "Owner", helper_method: :link_to_profile
    # config.add_index_field solr_name("publisher", :stored_searchable), itemprop: 'publisher', link_to_search: solr_name("publisher", :facetable)
    # config.add_index_field solr_name("based_near_label", :stored_searchable), itemprop: 'contentLocation', link_to_search: solr_name("based_near_label", :facetable)
    # config.add_index_field solr_name("language", :stored_searchable), itemprop: 'inLanguage', link_to_search: solr_name("language", :facetable)
    # config.add_index_field solr_name("date_uploaded", :stored_sortable, type: :date), itemprop: 'datePublished', helper_method: :human_readable_date
    # config.add_index_field solr_name("date_modified", :stored_sortable, type: :date), itemprop: 'dateModified', helper_method: :human_readable_date
    config.add_index_field solr_name("date_created", :stored_searchable), itemprop: 'dateCreated'
    # config.add_index_field solr_name("rights_statement", :stored_searchable), helper_method: :rights_statement_links
    # config.add_index_field solr_name("license", :stored_searchable), helper_method: :license_links
    # config.add_index_field solr_name("file_format", :stored_searchable), link_to_search: solr_name("file_format", :facetable)
    # config.add_index_field solr_name("identifier", :stored_searchable), helper_method: :index_field_link, field_name: 'identifier'
    # config.add_index_field solr_name("embargo_release_date", :stored_sortable, type: :date), label: "Embargo release date", helper_method: :human_readable_date
    # config.add_index_field solr_name("lease_expiration_date", :stored_sortable, type: :date), label: "Lease expiration date", helper_method: :human_readable_date
    config.add_index_field solr_name("creator", :stored_searchable), label: "Creator", itemprop: 'creator', link_to_search: solr_name("creator", :facetable)
    config.add_index_field solr_name("date", :stored_searchable), label: "Date", itemprop: 'dateCreated', link_to_search: solr_name("date", :facetable)
    config.add_index_field solr_name("contributing_institution", :stored_searchable), label: "Contributing Institution", itemprop: 'contributingInstitution', link_to_search: solr_name("contributing_institution", :facetable)
    config.add_index_field solr_name("description", :stored_searchable), label: "Description", itemprop: 'description', helper_method: :truncate_text
    # config.add_index_field solr_name("subject", :stored_searchable), label: "Subject", itemprop: 'about', link_to_search: solr_name("subject", :facetable)
    # config.add_index_field solr_name("place", :symbol), label: "Place", helper_method: :link_to_profile, link_to_search: solr_name("place", :facetable)
    # config.add_index_field solr_name("contributor", :stored_searchable), label: "Contributor", itemprop: 'contributor', link_to_search: solr_name("contributor", :facetable)
    # config.add_index_field solr_name("extent", :stored_searchable), label: "Extent", itemprop: 'extent', link_to_search: solr_name("extent", :facetable)
    # config.add_index_field solr_name("format_original", :stored_searchable), label: "Format (Original)", itemprop: 'formatOriginal', link_to_search: solr_name("format_original", :facetable)
    # config.add_index_field solr_name("language", :stored_searchable), label: "Language", itemprop: 'inLanguage', link_to_search: solr_name("language", :facetable)
    # config.add_index_field solr_name("publisher", :stored_searchable), label: "Publisher", itemprop: 'publisher', link_to_search: solr_name("publisher", :facetable)
    # config.add_index_field solr_name("time_period", :stored_searchable), label: "Time Period", itemprop: 'timePeriod'
    # config.add_index_field solr_name("format_digital", :stored_searchable), label: "Format (Digital)", itemprop: 'formatDigital', link_to_search: solr_name("format_digital", :facetable)
    # config.add_index_field solr_name("types", :stored_searchable), label: "Type", link_to_search: solr_name("types", :facetable)

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    # config.add_show_field solr_name("title", :stored_searchable)
    # config.add_show_field solr_name("description", :stored_searchable)
    # config.add_show_field solr_name("keyword", :stored_searchable)
    # config.add_show_field solr_name("subject", :stored_searchable)
    # config.add_show_field solr_name("creator", :stored_searchable)
    # config.add_show_field solr_name("contributor", :stored_searchable)
    # config.add_show_field solr_name("publisher", :stored_searchable)
    # config.add_show_field solr_name("based_near_label", :stored_searchable)
    # config.add_show_field solr_name("language", :stored_searchable)
    # config.add_show_field solr_name("date_uploaded", :stored_searchable)
    # config.add_show_field solr_name("date_modified", :stored_searchable)
    # config.add_show_field solr_name("date_created", :stored_searchable)
    # config.add_show_field solr_name("rights_statement", :stored_searchable)
    # config.add_show_field solr_name("license", :stored_searchable)
    # config.add_show_field solr_name("resource_type", :stored_searchable), label: "Resource Type"
    # config.add_show_field solr_name("format", :stored_searchable)
    # config.add_show_field solr_name("identifier", :stored_searchable)
    config.add_show_field solr_name("title", :stored_searchable), label: "Title"
    config.add_show_field solr_name("creator", :stored_searchable), label: "Creator"
    config.add_show_field solr_name("date", :stored_searchable), label: "Date"
    config.add_show_field solr_name("contributing_institution", :stored_searchable), label: "Contributing Institution"
    config.add_show_field solr_name("description", :stored_searchable), label: "Description"

    config.add_show_field solr_name("subject", :stored_searchable), label: "Subject"
    config.add_show_field solr_name("place", :stored_searchable), label: "Place"
    config.add_show_field solr_name("contributor", :stored_searchable), label: "Contributor"
    config.add_show_field solr_name("extent", :stored_searchable), label: "Extent"
    config.add_show_field solr_name("format_original", :stored_searchable), label: "Format (Original)"
    config.add_show_field solr_name("language", :stored_searchable), label: "Language"
    config.add_show_field solr_name("publisher", :stored_searchable), label: "Publisher"
    config.add_show_field solr_name("alternative_title", :stored_searchable), label: "Alternative Title"
    config.add_show_field solr_name("time_period", :stored_searchable), label: "Time Period"
    config.add_show_field solr_name("format_digital", :stored_searchable), label: "Format (Digital)"
    config.add_show_field solr_name("types", :stored_searchable), label: "Type"
    config.add_show_field solr_name("identifier", :stored_searchable), label: "URL"

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.
    #
    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.
    config.add_search_field('all_fields', label: 'All Fields') do |field|
      all_names = config.show_fields.values.map(&:field).join(" ")
      title_name = solr_name("title", :stored_searchable)
      field.solr_parameters = {
        qf: "#{all_names} file_format_tesim transcript_tesimv all_text_timv",
        pf: title_name.to_s
      }
    end

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.
    # creator, title, description, publisher, date_created,
    # subject, language, resource_type, format, identifier, based_near,
    config.add_search_field('contributor') do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params.

      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      solr_name = solr_name("contributor", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('creator') do |field|
      solr_name = solr_name("creator", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('title') do |field|
      solr_name = solr_name("title", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('description') do |field|
      field.label = "Abstract or Summary"
      solr_name = solr_name("description", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('publisher') do |field|
      solr_name = solr_name("publisher", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('date_created') do |field|
      solr_name = solr_name("created", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end
    # BEGIN addtions for atla
    config.add_search_field('date') do |field|
      solr_name = solr_name("date", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('type') do |field|
      solr_name = solr_name("types", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('format_original') do |field|
      field.include_in_advanced_search = false
      solr_name = solr_name("format_orginal", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('format_digital') do |field|
      field.include_in_advanced_search = false
      solr_name = solr_name("format_digital", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end
    # END addtions for atla
    config.add_search_field('subject') do |field|
      solr_name = solr_name("subject", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('language') do |field|
      solr_name = solr_name("language", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('resource_type') do |field|
      solr_name = solr_name("resource_type", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('format') do |field|
      solr_name = solr_name("format", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('identifier') do |field|
      solr_name = solr_name("id", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('place') do |field|
      field.label = "Place"
      solr_name = solr_name("place", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('keyword') do |field|
      solr_name = solr_name("keyword", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('depositor') do |field|
      solr_name = solr_name("depositor", :symbol)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('rights_statement') do |field|
      solr_name = solr_name("rights_statement", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('license') do |field|
      solr_name = solr_name("license", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('transcript') do |field|
      solr_name = solr_name("transcript", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    # label is key, solr field is value
    config.add_sort_field "score desc, #{uploaded_field} desc", label: "relevance"
    config.add_sort_field "title_sim asc", label: 'title A-Z'
    config.add_sort_field "title_sim desc", label: 'title Z-A'
    # config.add_sort_field "#{uploaded_field} desc", label: "date uploaded \u25BC"
    # config.add_sort_field "#{uploaded_field} asc", label: "date uploaded \u25B2"
    # config.add_sort_field "#{modified_field} desc", label: "date modified \u25BC"
    # config.add_sort_field "#{modified_field} asc", label: "date modified \u25B2"

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5
  end

  # disable the bookmark control from displaying in gallery view
  # Hyrax doesn't show any of the default controls on the list view, so
  # this method is not called in that context.
  def render_bookmarks_control?
    false
  end
end
