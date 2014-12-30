# Mock Data Naming

## Extension

Mock data files should have an extension separate from any "extension" included from the path.  Here are the extensions that VOKMockUrlProtocol looks for, in the order in which they are searched:

- `.http` files are parsed as full HTTP server responses, with
    -  status on the first line
    -  headers on the following line(s)
    -  blank line
    -  body on the following line(s)
- `.json` files are parsed as JSON and served up with `HTTP/1.1 200 Success` and `Content-type: application/json`.

## Base Name

The base name consists of:
- the HTTP method
- a pipe character `|`
- the request path
- if there is a query string:
	- a question mark `?`
	- the query string
- if there is a request body:
	- a pipe character `|`
	- if the request's `Content-Type` header is `application/x-www-form-urlencoded`, the content of the body
	- if the request's `Content-Type` header is `application/json`, the [bencoded](http://en.wikipedia.org/wiki/Bencode) form of the JSON data, represented as UTF-8 data, with [percent-encoding](http://en.wikipedia.org/wiki/Percent-encoding) applied to any non-unreserved characters
	- otherwise, the SHA-256 hash of the request body, as a 64-character lower-case hexadecimal string.
- any slashes `/` or colons `:` throughout are replaced by hyphens `-`