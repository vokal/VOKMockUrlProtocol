//
//  VOKBenkode.h
//
//  Created by Isaac Greenspan on 12/23/14.
//  Copyright (c) 2014 VOKAL Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  The error domain for any errors generated during the bencode/bdecode process.
 */
FOUNDATION_EXPORT NSString *const VOKBenkodeErrorDomain;

enum {
    /// The input data is empty.
    VOKBenkodeErrorEmptyData,
    /// Encountered an unknown data type.
    VOKBenkodeErrorUnknownDataType,
    /// Reached the end of the data without finding a matching ending delimiter.
    VOKBenkodeErrorMissingEndingDelimiter,
    /// Reached the end of the input without finding the colon expected in a string.
    VOKBenkodeErrorStringMissingColon,
    /// Read an apparently-negative string length.
    VOKBenkodeErrorStringLengthNegative,
    /// Read a string length that exceeded NSUIntegerMax.
    VOKBenkodeErrorStringLengthExceedesNSUIntegerMax,
    /// Read a malformed string length.
    VOKBenkodeErrorStringLengthMalformed,
    /// The length of the string indicates more data than was passed in.
    VOKBenkodeErrorStringLengthExceedsData,
    /// The data for a particular string could not be decoded.
    VOKBenkodeErrorStringDataInvalid,
    /// A dictionary key is not a string.
    VOKBenkodeErrorDictionaryKeyNotString,
    /// A dictionary has the same key more than once.
    VOKBenkodeErrorDictionaryDuplicateKey,
    /// A number is not valid.
    VOKBenkodeErrorNumberInvalid,
} VOKBenkodeErrorCodes;

typedef NS_OPTIONS(NSUInteger, VOKBenkodeDecodeOptions) {
    VOKBenkodeDecodeOptionStrict = 1 << 0,
};

/**
 *  Provides bencode and bdecode services as class methods.
 */
@interface VOKBenkode : NSObject

#pragma mark Encoding

/**
 *  Bencode an object.  Note that the object should consist of strings (NSString or potentially NSData objects), 
 *  integers (NSNumber objects), or lists or dictionaries (NSArray or NSDictionary objects) containing strings, 
 *  integers, lists, and dictionaries.
 *
 *  @param obj            The object to encode
 *  @param stringEncoding The encoding to use when converting NSString objects to NSData objects
 *  @param error          If an error occurs, upon return contains an NSError object that describes the problem
 *
 *  @return The bencoding of the given object, as NSData, or nil on error
 */
+ (NSData *)encode:(id)obj
    stringEncoding:(NSStringEncoding)stringEncoding
             error:(NSError **)error;

/**
 *  Bencode an object, encoding any strings with NSUTF8StringEncoding.  Note that the object should consist of strings 
 *  (NSString or potentially NSData objects), integers (NSNumber objects), or lists or dictionaries (NSArray or 
 *  NSDictionary objects) containing strings, integers, lists, and dictionaries.
 *
 *  @param obj   The object to encode
 *  @param error If an error occurs, upon return contains an NSError object that describes the problem
 *
 *  @return The bencoding of the given object, as NSData, or nil on error
 */
+ (NSData *)encode:(id)obj
             error:(NSError **)error;

/**
 *  Bencode an object.  Note that the object should consist of strings (NSString or potentially NSData objects),
 *  integers (NSNumber objects), or lists or dictionaries (NSArray or NSDictionary objects) containing strings,
 *  integers, lists, and dictionaries.
 *
 *  @param obj            The object to encode
 *  @param stringEncoding The encoding to use when converting NSString objects to NSData objects
 *
 *  @return The bencoding of the given object, as NSData, or nil on error
 */
+ (NSData *)encode:(id)obj
    stringEncoding:(NSStringEncoding)stringEncoding;

/**
 *  Bencode an object, encoding any strings with NSUTF8StringEncoding.  Note that the object should consist of strings
 *  (NSString or potentially NSData objects), integers (NSNumber objects), or lists or dictionaries (NSArray or
 *  NSDictionary objects) containing strings, integers, lists, and dictionaries.
 *
 *  @param obj The object to encode
 *
 *  @return The bencoding of the given object, as NSData, or nil on error
 */
+ (NSData *)encode:(id)obj;

#pragma mark Decoding

/**
 *  Bdecode data that was bencoded.  The resulting object will be a string (NSString), integer (NSNumber), or list or
 *  dictionary (NSArray or NSDictionary) containing strings, integers, lists, and dictionaries.
 *
 *  @param data           The data to decode
 *  @param options        The options for decoding
 *  @param stringEncoding The encoding to use when converting NSData objects to NSString objects
 *  @param error          If an error occurs, upon return contains an NSError object that describes the problem
 *
 *  @return The bdecoded object, or nil on error
 */
+ (id)decode:(NSData *)data
     options:(VOKBenkodeDecodeOptions)options
stringEncoding:(NSStringEncoding)stringEncoding
       error:(NSError **)error;

/**
 *  Bdecode data that was bencoded.  The resulting object will be a string (NSString), integer (NSNumber), or list or
 *  dictionary (NSArray or NSDictionary) containing strings, integers, lists, and dictionaries.
 *
 *  @param data           The data to decode
 *  @param stringEncoding The encoding to use when converting NSData objects to NSString objects
 *  @param error          If an error occurs, upon return contains an NSError object that describes the problem
 *
 *  @return The bdecoded object, or nil on error
 */
+ (id)decode:(NSData *)data
stringEncoding:(NSStringEncoding)stringEncoding
       error:(NSError **)error;

/**
 *  Bdecode data that was bencoded, decoding any strings with NSUTF8StringEncoding.  The resulting object will be a
 *  string (NSString), integer (NSNumber), or list or dictionary (NSArray or NSDictionary) containing strings,
 *  integers, lists, and dictionaries.
 *
 *  @param data    The data to decode
 *  @param options The options for decoding
 *  @param error   If an error occurs, upon return contains an NSError object that describes the problem
 *
 *  @return The bdecoded object, or nil on error
 */
+ (id)decode:(NSData *)data
     options:(VOKBenkodeDecodeOptions)options
       error:(NSError **)error;

/**
 *  Bdecode data that was bencoded, decoding any strings with NSUTF8StringEncoding.  The resulting object will be a
 *  string (NSString), integer (NSNumber), or list or dictionary (NSArray or NSDictionary) containing strings,
 *  integers, lists, and dictionaries.
 *
 *  @param data  The data to decode
 *  @param error If an error occurs, upon return contains an NSError object that describes the problem
 *
 *  @return The bdecoded object, or nil on error
 */
+ (id)decode:(NSData *)data
       error:(NSError **)error;

/**
 *  Bdecode data that was bencoded.  The resulting object will be a string (NSString), integer (NSNumber), or list or
 *  dictionary (NSArray or NSDictionary) containing strings, integers, lists, and dictionaries.
 *
 *  @param data           The data to decode
 *  @param stringEncoding The encoding to use when converting NSData objects to NSString objects
 *
 *  @return The bdecoded object, or nil on error
 */
+ (id)decode:(NSData *)data
stringEncoding:(NSStringEncoding)stringEncoding;

/**
 *  Bdecode data that was bencoded, decoding any strings with NSUTF8StringEncoding.  The resulting object will be a
 *  string (NSString), integer (NSNumber), or list or dictionary (NSArray or NSDictionary) containing strings,
 *  integers, lists, and dictionaries.
 *
 *  @param data The data to decode
 *
 *  @return The bdecoded object, or nil on error
 */
+ (id)decode:(NSData *)data;

@end
