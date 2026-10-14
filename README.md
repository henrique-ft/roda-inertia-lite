# Inertia.js Roda (Lite)

A standalone [Roda](https://roda.jeremyevans.net/) plugin for seamlessly integrating [Inertia.js](https://inertiajs.com/) into your Ruby web applications without views or other plugins dependency.

---

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem "roda-inertia-lite"
```

Then run:

```bash
bundle install
```

## Usage

### 1. Register the plugin

```ruby
require "roda"

class App < Roda
  plugin :inertia, version: -> { "v1" }
end
```

The `version` option is **required**. It can be a string or a callable (e.g., a lambda reading from an environment variable):

```ruby
# Static version
plugin :inertia, version: "abc123"

# Dynamic version (re-read on every request)
plugin :inertia, version: { ENV.fetch("ASSET_VERSION", "v1") }
```

### 2. Render Inertia responses

Use `inertia` in your routes to return page data as JSON (for Inertia requests) or as a full HTML document (for initial page loads):

```ruby
class App < Roda
  plugin :inertia, version: -> { "v1" }

  route do |r|
    r.get "users" do
      inertia "Users/Index", props: { users: User.all }
    end
  end
end
```

**For Inertia requests** (headers include `X-Inertia: true`):
- Sets response header `X-Inertia: true`
- Sets response header `Vary: X-Inertia`
- Returns a JSON page object:

```json
{
  "component": "Users/Index",
  "props": { "users": [{ "id": 1, "name": "Alice" }] },
  "url": "/users",
  "version": "v1"
}
```

**For non-Inertia requests** (initial page load):
- Returns a full HTML document with the JSON page data embedded in a `<div id="app" data-page='...'>` tag
- The HTML structure is built from the configured layout (see [Custom Layout](#custom-layout))

### 3. Handle redirects

Use `inertia_redirect` for both Inertia and non-Inertia requests:

```ruby
class App < Roda
  plugin :inertia, version: -> { "v1" }

  route do |r|
    r.post "users" do
      user = User.create(r.params["user"])
      inertia_redirect "/users/#{user.id}"
    end
  end
end
```

**For Inertia requests:**
- Internal paths (same host): redirects with **302** (GET) or **303** (non-GET)
- External URLs (different host): returns **409 Conflict** with an `X-Inertia-Location` header, telling the client to perform a full page visit

**For non-Inertia requests:**
- Always performs a standard redirect (default **302**, or specify a custom status)

**Custom status:**

```ruby
inertia_redirect "/dashboard", status: 301
```

### 4. Check if a request is an Inertia request

Use `inertia_request?` to conditionally handle Inertia vs. non-Inertia requests:

```ruby
route do |r|
  r.get "dashboard" do
    if inertia_request?
      inertia "Dashboard", props: { stats: calculate_stats }
    else
      # Handle non-Inertia request differently
    end
  end
end
```

## Configuration

### Custom Layout

You can customize the HTML document structure string using the `layout` option:

```ruby
plugin :inertia,
  version: -> { "v1" },
  layout: {
    head: "<title>My App</title>",
    body: "<footer>&copy; 2024 My App</footer>"
  }
```

This produces:

```html
<html><head><meta charset='utf-8' /><meta name='viewport' content='width=device-width, initial-scale=1, shrink-to-fit=no'><title>My App</title></head><body><div id='app' data-page='{...}'></div><footer>&copy; 2024 My App</footer></body></html>
```

## How It Works

### Version Conflicts (409 Responses)

When the client's asset version doesn't match the server's version (detected via the `X-Inertia-Version` header), the plugin returns a **409 Conflict** response with an `X-Inertia-Location` header. This tells the Inertia client to perform a full page reload to fetch fresh assets.

```
Client Request:
  X-Inertia: true
  X-Inertia-Version: v0

Server Response:
  Status: 409 Conflict
  X-Inertia-Location: https://example.com/page
```

### Request Flow

```
                    +------------------+
                    |   Inertia Request?|
                    +--------+---------+
                             |
              +--------------+--------------+
              |                             |
              v                             v
      +-------+-------+           +--------+--------+
      | X-Inertia: true|           |  Initial Load   |
      +-------+-------+           +--------+--------+
              |                             |
              v                             v
    +---------+---------+         +---------+---------+
    | Version matches?  |         |  Return full HTML  |
    +---------+---------+         |  document with    |
              |                   |  embedded JSON    |
    +---------+---------+         +-------------------+
    | Yes       | No    |
    v           v
+---+---+   +---+---+   +------------------+
| Return|   | 409   |   |  Redirect:       |
| JSON  |   |Conflict|   |  302/303         |
+---+---+   +---+---+   +------------------+
                           External? -> 409
```

## License

MIT
