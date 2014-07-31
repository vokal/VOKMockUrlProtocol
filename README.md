VOKMockUrlProtocol
==================

A url protocol that parses and returns fake responses with mock data.

## Usage

Create a folder reference called `VOKMockData`, so that the entire `VOKMockData` directory is copied into your test app bundle and place mock data files in there.  The easiest way to determine the proper file name for a mock data item is to make the mock API call and note the missing mock data file reported in the logs.  Mock data files may:

- have the `.json` extension to always return an `HTTP/1.1 200 Success` with `Content-type: text/json` and the content of the `.json` file; or
- have the `.http` extension to parse a full HTTP response including status, headers, and body from the file.