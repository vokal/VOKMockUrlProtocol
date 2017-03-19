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
	- the query string (it is expected that the keys and values in a standard query string will be [percent-encoded](http://en.wikipedia.org/wiki/Percent-encoding) )
	- if the percent-encoded query string would make the filename too long for HFS+ (255 character max) the SHA-256 hash of the percent-encoded query string (as a 64-character lower-case hexadecimal string) will be used instead
- if there is a request body:
	- a pipe character `|`
	- the encoding of the request body, [as described below](#request-body)
- any slashes `/` or colons `:` throughout are replaced by hyphens `-`

### Request Body

If the request's `Content-Type` header is `application/x-www-form-urlencoded`, use the content of the body.

If the request's `Content-Type` header is one of (list subject to expansion):

- `application/json`

indicating a structured data format that can be decoded, then use the [bencoded](http://en.wikipedia.org/wiki/Bencode) form of the decoded data, represented as UTF-8 data, with [percent-encoding](http://en.wikipedia.org/wiki/Percent-encoding) applied to any non-unreserved characters.

Otherwise, use the SHA-256 hash of the request body, as a 64-character lower-case hexadecimal string.

**Note:** For backward compatibility when additional specific content-type handling is added in the future, if a more-specific content-type-based filename is not found, the hash-based filename will be tried before returning a `HTTP/1.1 404 Not Found` response.

### Wildcards

Some URL requests may be hard to mock due to query or body data that is too dynamic (eg: based on a date).  You can allow wildcards in the mock data filename using `setAllowsWildcardInMockDataFiles` to mock these requests.  If enabled, mock data files may include a `*` in place of the query string, body, or both.

### Examples

The request

```
GET /foo/?page=2 HTTP/1.1
Host: example.com
Accept: */*

```

yields the base name
```
GET|-foo-?page=2
```
with an optional wildcard base name
```
GET|-foo-?*
```

---

The request

```
GET /details?one=1&two=2&three=3&four=4&five=5&six=6&seven=7&eight=8&nine=9&ten=10&eleven=11&twelve=12&thirteen=13&fourteen=14&fifteen=15&sixteen=16&seventeen=17&eighteen=18&nineteen=19&twenty=20&twentyone=21&twntytwo=22&twentythree=23&twentyfour=24&twentyfive=25" HTTP/1.1
Host: example.com
Accept: */*

```

yields the base name
```
GET|-details?fb73ef92daa60d3b526724dd5f50738e8477d10e0edcf96ce79794666f6b0c0e
```
with an optional wildcard base name
```
GET|-details?*
```

---

The request

```
POST /login/ HTTP/1.1
Host: example.com
Content-Type: application/x-www-form-urlencoded; charset=utf-8
Content-Length: 42

email=user%40example.com&password=password
```

yields the base name
```
POST|-login-|email=user%40example.com&password=password
```
with the fallback base name
```
POST|-login-|169d720631e603967135cfce10d235e94aac22b87500ea09d1be295f5b300dca
```
and an optional wildcard base name
```
POST|-login-|*
```

---

The request

```
POST /login/ HTTP/1.1
Host: example.com
Content-Type: application/json
Content-Length: 50

{"email":"user@example.com","password":"password"}
```

yields the base name
```
POST|-login-|d5-email16-user@example.com8-password8-passworde
```
with the fallback base name
```
POST|-login-|236a9780f782b62654f6caf7c4614e47b15800c087a9d43c87c47164617a74f0
```
and an optional wildcard base name
```
POST|-login-|*
```
