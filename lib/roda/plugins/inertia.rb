require "oj"
require "uri"

class Roda
  module RodaPlugins
    module Inertia
      HTML_HEAD            = "<html><head><meta charset='utf-8' /><meta name='viewport' content='width=device-width, initial-scale=1, shrink-to-fit=no'>".freeze
      HTML_BODY_START      = "</head><body><div id='app' data-page='".freeze
      HTML_APP_TAG_END     = "'></div>".freeze
      HTML_BODY_END        = "</body></html>".freeze

      HTTP_X_INERTIA = "HTTP_X_INERTIA".freeze
      X_INERTIA_LOCATION = "X-Inertia-Location".freeze
      X_INERTIA = "X-Inertia".freeze
      VARY = "vary".freeze
      STRING_TRUE = "true".freeze
      EMPTY_STRING = "".freeze
      HTTP_X_INERTIA_VERSION = "HTTP_X_INERTIA_VERSION".freeze
      HTTP = "http://".freeze
      HTTPS = "https://".freeze
      JSON_MIME_TYPE = "application/json".freeze
      QUESTION_MARK = "?".freeze

      def self.configure(app, opts = {})
        app.opts[:inertia_version] = opts[:version]
        head = opts.dig(:layout, :head) || EMPTY_STRING
        body = opts.dig(:layout, :body) || EMPTY_STRING

        app.opts[:inertia_html_head] ||= '' << HTML_HEAD << head << HTML_BODY_START
        app.opts[:inertia_html_body] ||= '' << HTML_APP_TAG_END << body << HTML_BODY_END
      end

      module InstanceMethods
        def inertia(component, props: {})
          if request.get? && inertia_request? && version_stale?
            response.status = 409
            response[X_INERTIA_LOCATION] = request.url
            return EMPTY_STRING
          end

          page_data = {
            component: component,
            props: props,
            url: inertia_request_url,
            version: inertia_version
          }

          if inertia_request?
            response[X_INERTIA] = STRING_TRUE
            response[VARY] = X_INERTIA

            page_data
          else
            '' \
              << opts[:inertia_html_head] \
              << Oj.dump(page_data, mode: :compat) \
              << opts[:inertia_html_body] \
          end
        end

        def inertia_redirect(path, status: nil)
          if inertia_request?
            status ||= request.get? ? 302 : 303

            if external_url?(path)
              response.status = 409
              response[X_INERTIA_LOCATION] = path
              EMPTY_STRING
            else
              request.redirect(path, status)
            end
          else
            request.redirect(path, status || 302)
          end
        end

        def inertia_request?
          request.get_header(HTTP_X_INERTIA) == STRING_TRUE
        end

        private

        def version_stale?
          client_version = request.get_header(HTTP_X_INERTIA_VERSION)
          server_version = inertia_version

          server_version && client_version && client_version != server_version.to_s
        end

        def external_url?(path)
          return false unless path.start_with?(HTTP, HTTPS)

          uri = URI.parse(path)
          [uri.scheme, uri.host, uri.port] != [request.scheme, request.host, request.port]
        rescue URI::InvalidURIError
          false
        end

        def inertia_request_url
          query = request.query_string
          return request.path if query.nil? || query.empty?

          '' << request.path << QUESTION_MARK << query
        end

        def inertia_version
          version = opts[:inertia_version]

          if version.respond_to?(:call)
            version.call
          else
            version
          end
        end
      end
    end

    register_plugin(:inertia, Inertia)
  end
end
