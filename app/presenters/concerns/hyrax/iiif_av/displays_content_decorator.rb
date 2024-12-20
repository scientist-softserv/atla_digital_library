# OVERRIDE from hyrax-iiif_av gem: handles weirdly formatted video & audio durations
module Hyrax
  module IiifAv
    module DisplaysContentDecorator
      def video_display_content(_url, label = '')
        width = Array(solr_document.width).first.try(:to_i) || 320
        height = Array(solr_document.height).first.try(:to_i) || 240
        duration = conformed_duration_in_seconds
        IIIFManifest::V3::DisplayContent.new(
          Hyrax::IiifAv::Engine.routes.url_helpers.iiif_av_content_url(
            solr_document.id, label: label,
                              host: request.base_url
          ),
                                              label: label,
                                              width: width,
                                              height: height,
                                              duration: duration,
                                              type: 'Video',
                                              format: solr_document.mime_type
        )
      end

      def audio_display_content(_url, label = '')
        duration = conformed_duration_in_seconds
        IIIFManifest::V3::DisplayContent.new(
          Hyrax::IiifAv::Engine.routes.url_helpers.iiif_av_content_url(
            solr_document.id, label: label,
                              host: request.base_url
          ),
                                              label: label,
                                              duration: duration,
                                              type: 'Sound',
                                              format: solr_document.mime_type
        )
      end

      def conformed_duration_in_seconds
        if Array(solr_document.duration)&.first&.count(':') == 3
          # takes care of milliseconds like ["0:0:01:001"]
          Time.zone.parse(Array(solr_document.duration).first.sub(/.*\K:/, '.')).seconds_since_midnight
        elsif Array(solr_document.duration)&.first&.include?(':')
          # if solr_document.duration evaluates to something like ["0:01:00"] which will get converted to seconds
          Time.zone.parse(Array(solr_document.duration).first).seconds_since_midnight
        else
          # handles cases if solr_document.duration evaluates to something like ['25 s']
          Array(solr_document.duration).first.try(:to_f)
        end ||
          400.0
      end
    end
  end
end

Hyrax::IiifAv::DisplaysContent.prepend(Hyrax::IiifAv::DisplaysContentDecorator)
