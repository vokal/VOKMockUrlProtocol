//
//  HTTPHeaderFields.m
//  
//
//  Created by Luke Quigley on 4/10/15.
//
//

#import "HTTPHeaderFields.h"

//Request fields
NSString *const kHTTPHeaderFieldAccept = @"Accept";
NSString *const kHTTPHeaderFieldAcceptCharset = @"Accept-Charset";
NSString *const kHTTPHeaderFieldAcceptEncoding = @"Accept-Encoding";
NSString *const kHTTPHeaderFieldAcceptLanguage = @"Accept-Language";
NSString *const kHTTPHeaderFieldAcceptDatetime = @"Accept-Datetime";
NSString *const kHTTPHeaderFieldAuthorization = @"Authorization";
NSString *const kHTTPHeaderFieldCacheControl = @"Cache-Control";
NSString *const kHTTPHeaderFieldConnection = @"Connection";
NSString *const kHTTPHeaderFieldCookie = @"Cookie";
NSString *const kHTTPHeaderFieldContentLength = @"Content-Length";
NSString *const kHTTPHeaderFieldContentMD5 = @"Content-MD5";
NSString *const kHTTPHeaderFieldContentType = @"Content-Type";
NSString *const kHTTPHeaderFieldDate = @"Date";
NSString *const kHTTPHeaderFieldExpect = @"Expect";
NSString *const kHTTPHeaderFieldFrom = @"From";
NSString *const kHTTPHeaderFieldHost = @"Host";
NSString *const kHTTPHeaderFieldIfMatch = @"If-Match";
NSString *const kHTTPHeaderFieldIfModifiedSince = @"If-Modified-Since";
NSString *const kHTTPHeaderFieldIfNoneMatch = @"If-None-Match";
NSString *const kHTTPHeaderFieldIfRange = @"If-Range";
NSString *const kHTTPHeaderFieldIfUnmodifiedSince = @"If-Unmodified-Since";
NSString *const kHTTPHeaderFieldMaxForwards = @"Max-Forwards";
NSString *const kHTTPHeaderFieldOrigin = @"Origin";
NSString *const kHTTPHeaderFieldPragma = @"Pragma";
NSString *const kHTTPHeaderFieldProxyAuthorization = @"Proxy-Authorization";
NSString *const kHTTPHeaderFieldRange = @"Range";
NSString *const kHTTPHeaderFieldReferer = @"Referer";
NSString *const kHTTPHeaderFieldTE = @"TE";
NSString *const kHTTPHeaderFieldUserAgent = @"User-Agent";
NSString *const kHTTPHeaderFieldUpgrade = @"Upgrade";
NSString *const kHTTPHeaderFieldVia = @"Via";
NSString *const kHTTPHeaderFieldWarning = @"Warning";

//Response fields
NSString *const kHTTPHeaderFieldAccessControlAllowOrigin = @"Access-Control-Allow-Origin";
NSString *const kHTTPHeaderFieldAcceptPatch = @"Accept-Patch";
NSString *const kHTTPHeaderFieldAcceptRanges = @"Accept-Ranges";
NSString *const kHTTPHeaderFieldAge = @"Age";
NSString *const kHTTPHeaderFieldAllow = @"Allow";
NSString *const kHTTPHeaderFieldContentDisposition = @"Content-Disposition";
NSString *const kHTTPHeaderFieldContentEncoding = @"Content-Encoding";
NSString *const kHTTPHeaderFieldContentLanguage = @"Content-Language";
NSString *const kHTTPHeaderFieldContentLocation = @"Content-Location";
NSString *const kHTTPHeaderFieldContentRange = @"Content-Range";
NSString *const kHTTPHeaderFieldETag = @"ETag";
NSString *const kHTTPHeaderFieldExpires = @"Expires";
NSString *const kHTTPHeaderFieldLastModified = @"Last-Modified";
NSString *const kHTTPHeaderFieldLink = @"Link";
NSString *const kHTTPHeaderFieldLocation = @"Location";
NSString *const kHTTPHeaderFieldP3P = @"P3P";
NSString *const kHTTPHeaderFieldProxyAuthenticate = @"Proxy-Authenticate";
NSString *const kHTTPHeaderFieldRefresh = @"Reresh";
NSString *const kHTTPHeaderFieldRetryAfter = @"Retry-After";
NSString *const kHTTPHeaderFieldServer = @"Server";
NSString *const kHTTPHeaderFieldSetCookie = @"Set-Cookie";
NSString *const kHTTPHeaderFieldStatus = @"Status";
NSString *const kHTTPHeaderFieldStrictTransportSecurity = @"Strict-Transport-Security";
NSString *const kHTTPHeaderFieldTrailer = @"Trailer";
NSString *const kHTTPHeaderFieldTransferEncoding = @"Transfer-Encoding";
NSString *const kHTTPHeaderFieldVary = @"Vary";
NSString *const kHTTPHeaderFieldWWWAuthenticate = @"WWW-Authenticate";
NSString *const kHTTPHeaderFieldXFrameOptions = @"X-Frame-Options";
