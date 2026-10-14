require_relative "spec_helper"
require "json"

RSpec.describe "Inertia Roda Plugin" do
  class TestApp < Roda
    plugin :inertia, version: -> { "v1" }

    route do |r|
      r.is "stale" do
        r.get do
          data = inertia("StaleComponent", props: { name: "test" })
          data.is_a?(Hash) ? (response["Content-Type"] = "application/json"; JSON.generate(data)) : data
        end
      end

      r.is "page" do
        r.get do
          data = inertia("Users/Index", props: { users: [{ id: 1, name: "Alice" }] })
          data.is_a?(Hash) ? (response["Content-Type"] = "application/json"; JSON.generate(data)) : data
        end
      end

      r.is "page-no-props" do
        r.get do
          data = inertia("Home")
          data.is_a?(Hash) ? (response["Content-Type"] = "application/json"; JSON.generate(data)) : data
        end
      end

      r.is "redirect-internal" do
        r.get do
          inertia_redirect("/target")
        end
      end

      r.is "redirect-external" do
        r.get do
          inertia_redirect("https://external.example.com/foo")
        end
      end

      r.is "redirect-status" do
        r.get do
          inertia_redirect("/target", status: 301)
        end
      end

      r.is "check-inertia" do
        r.get do
          inertia_request? ? "inertia" : "not-inertia"
        end
      end

      r.is "query" do
        r.get do
          data = inertia("QueryComponent")
          data.is_a?(Hash) ? (response["Content-Type"] = "application/json"; JSON.generate(data)) : data
        end
      end

      r.is "root" do
        r.get do
          data = inertia("RootComponent")
          data.is_a?(Hash) ? (response["Content-Type"] = "application/json"; JSON.generate(data)) : data
        end
      end
    end
  end

  def app
    TestApp.app
  end

  def inertia_headers(version: "v1")
    {
      "HTTP_X_INERTIA" => "true",
      "HTTP_X_INERTIA_VERSION" => version
    }
  end

  describe "constants" do
    it "defines HTML_HEAD" do
      expect(Roda::RodaPlugins::Inertia::HTML_HEAD).to include("<html><head>")
      expect(Roda::RodaPlugins::Inertia::HTML_HEAD).to include("charset")
      expect(Roda::RodaPlugins::Inertia::HTML_HEAD).to include("viewport")
    end

    it "defines HTML_BODY_START" do
      expect(Roda::RodaPlugins::Inertia::HTML_BODY_START).to include("</head><body>")
      expect(Roda::RodaPlugins::Inertia::HTML_BODY_START).to include("<div id='app' data-page='")
    end

    it "defines HTML_APP_TAG_END" do
      expect(Roda::RodaPlugins::Inertia::HTML_APP_TAG_END).to eq("'></div>")
    end

    it "defines HTML_BODY_END" do
      expect(Roda::RodaPlugins::Inertia::HTML_BODY_END).to eq("</body></html>")
    end

    it "defines HTTP_X_INERTIA" do
      expect(Roda::RodaPlugins::Inertia::HTTP_X_INERTIA).to eq("HTTP_X_INERTIA")
    end

    it "defines X_INERTIA_LOCATION" do
      expect(Roda::RodaPlugins::Inertia::X_INERTIA_LOCATION).to eq("X-Inertia-Location")
    end

    it "defines X_INERTIA" do
      expect(Roda::RodaPlugins::Inertia::X_INERTIA).to eq("X-Inertia")
    end

    it "defines VARY" do
      expect(Roda::RodaPlugins::Inertia::VARY).to eq("vary")
    end

    it "defines STRING_TRUE" do
      expect(Roda::RodaPlugins::Inertia::STRING_TRUE).to eq("true")
    end

    it "defines EMPTY_STRING" do
      expect(Roda::RodaPlugins::Inertia::EMPTY_STRING).to eq("")
    end

    it "defines HTTP_X_INERTIA_VERSION" do
      expect(Roda::RodaPlugins::Inertia::HTTP_X_INERTIA_VERSION).to eq("HTTP_X_INERTIA_VERSION")
    end

    it "defines HTTP" do
      expect(Roda::RodaPlugins::Inertia::HTTP).to eq("http://")
    end

    it "defines HTTPS" do
      expect(Roda::RodaPlugins::Inertia::HTTPS).to eq("https://")
    end

    it "defines JSON_MIME_TYPE" do
      expect(Roda::RodaPlugins::Inertia::JSON_MIME_TYPE).to eq("application/json")
    end

    it "defines QUESTION_MARK" do
      expect(Roda::RodaPlugins::Inertia::QUESTION_MARK).to eq("?")
    end
  end

  describe ".configure" do
    it "stores the version in app opts" do
      klass = Class.new(Roda)
      klass.plugin :inertia, version: "v2"
      expect(klass.opts[:inertia_version]).to eq("v2")
    end

    it "stores a callable version in app opts" do
      klass = Class.new(Roda)
      klass.plugin :inertia, version: -> { "v3" }
      expect(klass.opts[:inertia_version]).to be_a(Proc)
    end

    it "builds inertia_html_head from layout head option" do
      klass = Class.new(Roda)
      klass.plugin :inertia, layout: { head: "<title>My App</title>" }
      expect(klass.opts[:inertia_html_head]).to include("<title>My App</title>")
      expect(klass.opts[:inertia_html_head]).to start_with(Roda::RodaPlugins::Inertia::HTML_HEAD)
      expect(klass.opts[:inertia_html_head]).to end_with(Roda::RodaPlugins::Inertia::HTML_BODY_START)
    end

    it "builds inertia_html_body from layout body option" do
      klass = Class.new(Roda)
      klass.plugin :inertia, layout: { body: "<footer>Bye</footer>" }
      expect(klass.opts[:inertia_html_body]).to include("<footer>Bye</footer>")
      expect(klass.opts[:inertia_html_body]).to start_with(Roda::RodaPlugins::Inertia::HTML_APP_TAG_END)
      expect(klass.opts[:inertia_html_body]).to end_with(Roda::RodaPlugins::Inertia::HTML_BODY_END)
    end

    it "defaults to empty string when no layout option given" do
      klass = Class.new(Roda)
      klass.plugin :inertia
      expect(klass.opts[:inertia_html_head]).to eq(Roda::RodaPlugins::Inertia::HTML_HEAD + Roda::RodaPlugins::Inertia::HTML_BODY_START)
      expect(klass.opts[:inertia_html_body]).to eq(Roda::RodaPlugins::Inertia::HTML_APP_TAG_END + Roda::RodaPlugins::Inertia::HTML_BODY_END)
    end

    it "does not overwrite inertia_html_head if already set" do
      klass = Class.new(Roda)
      klass.opts[:inertia_html_head] = "custom head"
      klass.plugin :inertia, layout: { head: "<title>Ignored</title>" }
      expect(klass.opts[:inertia_html_head]).to eq("custom head")
    end

    it "does not overwrite inertia_html_body if already set" do
      klass = Class.new(Roda)
      klass.opts[:inertia_html_body] = "custom body"
      klass.plugin :inertia, layout: { body: "<footer>Ignored</footer>" }
      expect(klass.opts[:inertia_html_body]).to eq("custom body")
    end
  end

  describe "#inertia (version stale)" do
    it "returns 409 when client version differs from server version" do
      get "/stale", {}, inertia_headers(version: "v0")
      expect(last_response.status).to eq(409)
    end

    it "sets X-Inertia-Location header to request URL" do
      get "/stale", {}, inertia_headers(version: "v0")
      expect(last_response.headers["X-Inertia-Location"]).to eq("http://example.org/stale")
    end

    it "returns empty body" do
      get "/stale", {}, inertia_headers(version: "v0")
      expect(last_response.body).to eq("")
    end
  end

  describe "#inertia (Inertia request)" do
    it "sets X-Inertia response header to true" do
      get "/page", {}, inertia_headers
      expect(last_response.headers["X-Inertia"]).to eq("true")
    end

    it "sets Vary header to X-Inertia" do
      get "/page", {}, inertia_headers
      expect(last_response.headers["Vary"]).to eq("X-Inertia")
    end

    it "returns JSON response" do
      get "/page", {}, inertia_headers
      expect(last_response.content_type).to include("application/json")
    end

    it "includes component in page data" do
      get "/page", {}, inertia_headers
      body = JSON.parse(last_response.body)
      expect(body["component"]).to eq("Users/Index")
    end

    it "includes props in page data" do
      get "/page", {}, inertia_headers
      body = JSON.parse(last_response.body)
      expect(body["props"]).to eq({ "users" => [{ "id" => 1, "name" => "Alice" }] })
    end

    it "defaults props to empty hash" do
      get "/page-no-props", {}, inertia_headers
      body = JSON.parse(last_response.body)
      expect(body["props"]).to eq({})
    end

    it "includes url in page data" do
      get "/page", {}, inertia_headers
      body = JSON.parse(last_response.body)
      expect(body["url"]).to eq("/page")
    end

    it "includes version in page data" do
      get "/page", {}, inertia_headers
      body = JSON.parse(last_response.body)
      expect(body["version"]).to eq("v1")
    end

    it "includes query string in url when present" do
      get "/query?foo=bar&baz=1", {}, inertia_headers
      body = JSON.parse(last_response.body)
      expect(body["url"]).to eq("/query?foo=bar&baz=1")
    end

    it "omits query string from url when empty" do
      get "/page", {}, inertia_headers
      body = JSON.parse(last_response.body)
      expect(body["url"]).not_to include("?")
    end
  end

  describe "#inertia (non-Inertia request)" do
    it "returns HTML response" do
      get "/page"
      expect(last_response.content_type).to include("text/html")
    end

    it "includes the default HTML head" do
      get "/page"
      expect(last_response.body).to include("<html><head>")
    end

    it "includes the JSON page data embedded in the HTML" do
      get "/page"
      expect(last_response.body).to include("Users/Index")
      expect(last_response.body).to include('"props"')
    end

    it "includes the default HTML body closing" do
      get "/page"
      expect(last_response.body).to include("</body></html>")
    end

    it "includes the app div" do
      get "/page"
      expect(last_response.body).to include("<div id='app' data-page='")
    end

    it "does not set X-Inertia header" do
      get "/page"
      expect(last_response.headers).not_to have_key("X-Inertia")
    end

    it "returns a String body" do
      get "/page"
      expect(last_response.body).to be_a(String)
    end
  end

  describe "#inertia_redirect (Inertia request, internal)" do
    it "redirects with 302 for GET requests" do
      get "/redirect-internal", {}, inertia_headers
      expect(last_response.status).to eq(302)
    end

    it "sets Location header" do
      get "/redirect-internal", {}, inertia_headers
      expect(last_response.headers["Location"]).to eq("/target")
    end

    it "uses explicit status when provided" do
      get "/redirect-status", {}, inertia_headers
      expect(last_response.status).to eq(301)
    end

    it "sets Location header with explicit status" do
      get "/redirect-status", {}, inertia_headers
      expect(last_response.headers["Location"]).to eq("/target")
    end
  end

  describe "#inertia_redirect (Inertia request, external)" do
    it "returns 409 for external URL" do
      get "/redirect-external", {}, inertia_headers
      expect(last_response.status).to eq(409)
    end

    it "sets X-Inertia-Location header to external URL" do
      get "/redirect-external", {}, inertia_headers
      expect(last_response.headers["X-Inertia-Location"]).to eq("https://external.example.com/foo")
    end

    it "returns empty body" do
      get "/redirect-external", {}, inertia_headers
      expect(last_response.body).to eq("")
    end
  end

  describe "#inertia_redirect (non-Inertia request)" do
    it "redirects with 302 for internal path" do
      get "/redirect-internal"
      expect(last_response.status).to eq(302)
    end

    it "sets Location header for internal path" do
      get "/redirect-internal"
      expect(last_response.headers["Location"]).to eq("/target")
    end

    it "redirects external URLs without 409" do
      get "/redirect-external"
      expect(last_response.status).to eq(302)
    end

    it "sets Location header for external URL" do
      get "/redirect-external"
      expect(last_response.headers["Location"]).to eq("https://external.example.com/foo")
    end

    it "uses explicit status when provided" do
      get "/redirect-status"
      expect(last_response.status).to eq(301)
    end
  end

  describe "#inertia_request?" do
    it "returns true when X-Inertia header is 'true'" do
      get "/check-inertia", {}, "HTTP_X_INERTIA" => "true"
      expect(last_response.body).to eq("inertia")
    end

    it "returns false when X-Inertia header is 'false'" do
      get "/check-inertia", {}, "HTTP_X_INERTIA" => "false"
      expect(last_response.body).to eq("not-inertia")
    end

    it "returns false when X-Inertia header is missing" do
      get "/check-inertia"
      expect(last_response.body).to eq("not-inertia")
    end

    it "returns false when X-Inertia header has other value" do
      get "/check-inertia", {}, "HTTP_X_INERTIA" => "yes"
      expect(last_response.body).to eq("not-inertia")
    end
  end

  describe "#inertia_version" do
    it "returns the version when it is a string" do
      klass = Class.new(Roda)
      klass.plugin :inertia, version: "v99"
      obj = klass.allocate
      expect(obj.send(:inertia_version)).to eq("v99")
    end

    it "calls the version when it is callable" do
      klass = Class.new(Roda)
      klass.plugin :inertia, version: -> { "v42" }
      obj = klass.allocate
      expect(obj.send(:inertia_version)).to eq("v42")
    end

    it "returns nil when no version is configured" do
      klass = Class.new(Roda)
      klass.plugin :inertia
      obj = klass.allocate
      expect(obj.send(:inertia_version)).to be_nil
    end
  end

  describe "#version_stale? (indirect)" do
    it "does not trigger 409 when client version matches server" do
      get "/page", {}, inertia_headers(version: "v1")
      expect(last_response.status).not_to eq(409)
    end

    it "triggers 409 when client version differs from server" do
      get "/stale", {}, inertia_headers(version: "v0")
      expect(last_response.status).to eq(409)
    end

    it "does not trigger 409 when client version is missing" do
      get "/page", {}, "HTTP_X_INERTIA" => "true"
      expect(last_response.status).not_to eq(409)
    end

    it "does not trigger 409 when server version is nil" do
      klass = Class.new(Roda) do
        plugin :inertia
        def debugger; end
        route do |r|
          r.get do
            data = inertia("NoVersion")
            data.is_a?(Hash) ? (response["Content-Type"] = "application/json"; JSON.generate(data)) : data
          end
        end
      end
      session = Rack::Test::Session.new(Rack::MockSession.new(klass.app))
      session.get "/", {}, "HTTP_X_INERTIA" => "true", "HTTP_X_INERTIA_VERSION" => "v1"
      expect(session.last_response.status).not_to eq(409)
    end
  end

  describe "#external_url? (indirect)" do
    it "treats same-host URL as internal" do
      klass = Class.new(Roda) do
        plugin :inertia, version: -> { "v1" }
        def debugger; end
        route do |r|
          r.get do
            inertia_redirect("http://example.org/same-host")
          end
        end
      end
      session = Rack::Test::Session.new(Rack::MockSession.new(klass.app))
      session.get "/", {}, inertia_headers
      expect(session.last_response.status).to eq(302)
    end

    it "treats different-host URL as external" do
      get "/redirect-external", {}, inertia_headers
      expect(last_response.status).to eq(409)
    end

    it "treats invalid URI as internal (no 409)" do
      klass = Class.new(Roda) do
        plugin :inertia, version: -> { "v1" }
        def debugger; end
        route do |r|
          r.get do
            inertia_redirect("http://[invalid")
          end
        end
      end
      session = Rack::Test::Session.new(Rack::MockSession.new(klass.app))
      session.get "/", {}, inertia_headers
      expect(session.last_response.status).to eq(302)
    end
  end

  describe "#inertia_request_url (indirect)" do
    it "returns path when no query string" do
      get "/page", {}, inertia_headers
      body = JSON.parse(last_response.body)
      expect(body["url"]).to eq("/page")
    end

    it "returns path with query string when present" do
      get "/query?key=value", {}, inertia_headers
      body = JSON.parse(last_response.body)
      expect(body["url"]).to eq("/query?key=value")
    end

    it "returns path when query string is empty" do
      get "/page?", {}, inertia_headers
      body = JSON.parse(last_response.body)
      expect(body["url"]).to eq("/page")
    end
  end
end
