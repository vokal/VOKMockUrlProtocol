VOKMockUrlProtocol
==================

![](https://api.travis-ci.org/vokalinteractive/VOKMockUrlProtocol.svg)

A url protocol that parses and returns fake responses with mock data.

## Usage

Create a folder reference called `VOKMockData`, so that the entire `VOKMockData` directory is copied into your test app bundle and place mock data files in there.  The easiest way to determine the proper file name for a mock data item is to make the mock API call and note the missing mock data file reported in the logs.  Mock data files may:

- have the `.json` extension to always return an `HTTP/1.1 200 Success` with `Content-type: text/json` and the content of the `.json` file; or
- have the `.http` extension to parse an HTTP response with the following format:
  - status on the first line
  - headers on the following lines
  - blank line
  - body on the following lines

Example HTTP responses:

HTTP response with headers and response body.
```
HTTP/1.1 201 CREATED
Server: nginx/1.4.6 (Ubuntu)
Date: Thu, 02 Oct 2014 20:50:29 GMT
Content-Type: application/json
Transfer-Encoding: chunked
Connection: keep-alive
Vary: Accept, Cookie
X-Frame-Options: SAMEORIGIN
Allow: POST, OPTIONS

{"id": 63, "auth_token": "50db3356e743fa3f1b790a8648fc15cc4bbf04a2", "phone_number": "+13125551214", "email": "test33@test.com", "name": "Testy McTesterson", "role": "Customer"}
```

HTTP response with headers and no body.  Note the blank line at the end!
```
HTTP/1.1 202 Accepted
Content-Type: text/plain; charset=UTF-8
Date: Fri, 17 Oct 2014 14:12:46 GMT
Server: Apache-Coyote/1.1
Content-Length: 0
Connection: keep-alive

```

HTTP response with no headers and no body.  Note the blank line at the end!
```
HTTP/1.1 202 Accepted

```

HTTP response with no headers and a body.
```
HTTP/1.1 202 Accepted

{"favorite_dog_breed": "dogfish"}
```
