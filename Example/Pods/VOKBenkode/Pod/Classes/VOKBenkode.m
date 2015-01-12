//
//  VOKBenkode.m
//
//  Created by Isaac Greenspan on 12/23/14.
//  Copyright (c) 2014 VOKAL Interactive. All rights reserved.
//

#import "VOKBenkode.h"

NSString *const VOKBenkodeErrorDomain = @"com.vokalinteractive.VOKBenkode";

static char const NumberStartDelimiter = 'i';
static char const ArrayStartDelimiter = 'l';
static char const DictionaryStartDelimiter = 'd';
static char const EndDelimiter = 'e';
static char const StringLengthDataSeparator = ':';

static NSComparisonResult CompareNSData(NSData *obj1, NSData *obj2)
{
    int result = memcmp(obj1.bytes, obj2.bytes, MIN(obj1.length, obj2.length));
    if (result < 0
        || (result == 0 && obj1.length < obj2.length)) {
        return NSOrderedAscending;
    }
    if (result > 0
        || (result == 0 && obj1.length > obj2.length)) {
        return NSOrderedDescending;
    }
    return NSOrderedSame;
}

@implementation VOKBenkode

#pragma mark - Encoding

+ (NSData *)encode:(id)obj
    stringEncoding:(NSStringEncoding)stringEncoding
             error:(NSError **)error
{
    if ([obj isKindOfClass:[NSData class]]) {
        return [self encodeData:obj
                 stringEncoding:stringEncoding
                          error:error];
    }
    if ([obj isKindOfClass:[NSString class]]) {
        return [self encodeString:obj
                   stringEncoding:stringEncoding
                            error:error];
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [self encodeNumber:obj
                   stringEncoding:stringEncoding
                            error:error];
    }
    if ([obj isKindOfClass:[NSArray class]]) {
        return [self encodeArray:obj
                  stringEncoding:stringEncoding
                           error:error];
    }
    if ([obj isKindOfClass:[NSDictionary class]]) {
        return [self encodeDictionary:obj
                       stringEncoding:stringEncoding
                                error:error];
    }
    
    // Unknown data type.
    if (error) {
        *error = [NSError errorWithDomain:VOKBenkodeErrorDomain
                                     code:VOKBenkodeErrorUnknownDataType
                                 userInfo:nil];
    }
    return nil;
}

+ (NSData *)encode:(id)obj
             error:(NSError **)error
{
    return [self encode:obj
         stringEncoding:NSUTF8StringEncoding
                  error:error];
}

+ (NSData *)encode:(id)obj
    stringEncoding:(NSStringEncoding)stringEncoding
{
    return [self encode:obj
         stringEncoding:stringEncoding
                  error:NULL];
}

+ (NSData *)encode:(id)obj
{
    return [self encode:obj
                  error:NULL];
}

#pragma mark Encoding Primitives

+ (NSData *)encodeDictionary:(NSDictionary *)dictionary
              stringEncoding:(NSStringEncoding)stringEncoding
                       error:(NSError **)error
{
    NSAssert([dictionary isKindOfClass:[NSDictionary class]], @"Input is not a dictionary.");
    // Construct a dictionary mapping each key to its NSData representation.
    NSMutableDictionary *keyDataByKey = [NSMutableDictionary dictionaryWithCapacity:[dictionary count]];
    for (id key in dictionary) {
        if ([key isKindOfClass:[NSData class]]) {
            keyDataByKey[key] = key;
        } else if ([key isKindOfClass:[NSString class]]) {
            keyDataByKey[key] = [key dataUsingEncoding:stringEncoding];
        } else {
            // The bencode spec says dictionary keys must be strings (NSData ~= bytestring, so...).
            if (error) {
                *error = [NSError errorWithDomain:VOKBenkodeErrorDomain
                                             code:VOKBenkodeErrorDictionaryKeyNotString
                                         userInfo:nil];
            }
            return nil;
        }
    }
    
    // Produce an array of the keys, sorted by their binary NSData representation.
    NSArray *keys = [keyDataByKey.allKeys sortedArrayUsingComparator:^NSComparisonResult(id key1, id key2) {
        return CompareNSData(keyDataByKey[key1], keyDataByKey[key2]);
    }];
    
    NSMutableData *result = [NSMutableData dataWithBytes:&DictionaryStartDelimiter length:1];
    
    for (id key in keys) {
        NSError *innerError;
        NSData *data = [self encode:key
                     stringEncoding:stringEncoding
                              error:&innerError];
        if (!data) {
            if (error) {
                *error = innerError;
            }
            return nil;
        }
        [result appendData:data];
        data = [self encode:dictionary[key]
             stringEncoding:stringEncoding
                      error:&innerError];
        if (!data) {
            if (error) {
                *error = innerError;
            }
            return nil;
        }
        [result appendData:data];
    }
    [result appendBytes:&EndDelimiter length:1];
    return result;
}

+ (NSData *)encodeArray:(NSArray *)array
         stringEncoding:(NSStringEncoding)stringEncoding
                  error:(NSError **)error
{
    NSAssert([array isKindOfClass:[NSArray class]], @"Input is not an array.");
    NSMutableData *result = [NSMutableData dataWithBytes:&ArrayStartDelimiter length:1];
    for (id innerObj in array) {
        NSError *innerError;
        NSData *data = [self encode:innerObj
                     stringEncoding:stringEncoding
                              error:&innerError];
        if (!data) {
            if (error) {
                *error = innerError;
            }
            return nil;
        }
        [result appendData:data];
    }
    [result appendBytes:&EndDelimiter length:1];
    return result;
}

+ (NSData *)encodeNumber:(NSNumber *)number
          stringEncoding:(NSStringEncoding)stringEncoding
                   error:(NSError **)error
{
    NSAssert([number isKindOfClass:[NSNumber class]], @"Input is not a number.");
    return [[NSString stringWithFormat:@"%c%ld%c", NumberStartDelimiter, [number longValue], EndDelimiter]
            dataUsingEncoding:NSASCIIStringEncoding];
}

+ (NSData *)encodeString:(NSString *)string
          stringEncoding:(NSStringEncoding)stringEncoding
                   error:(NSError **)error
{
    NSAssert([string isKindOfClass:[NSString class]], @"Input is not a string.");
    return [self encode:[string dataUsingEncoding:stringEncoding]
         stringEncoding:stringEncoding
                  error:error];
}

+ (NSData *)encodeData:(NSData *)data
        stringEncoding:(NSStringEncoding)stringEncoding
                 error:(NSError **)error
{
    NSAssert([data isKindOfClass:[NSData class]], @"Input is not data.");
    NSMutableData *result = [[[NSString stringWithFormat:@"%@%c", @([data length]), StringLengthDataSeparator]
                              dataUsingEncoding:NSASCIIStringEncoding]
                             mutableCopy];
    [result appendData:data];
    return result;
}

#pragma mark - Decoding

+(id)decode:(NSData *)data
    options:(VOKBenkodeDecodeOptions)options
stringEncoding:(NSStringEncoding)stringEncoding
      error:(NSError **)error
     length:(NSUInteger *)length
{
    if (!data.length) {
        if (error) {
            *error = [NSError errorWithDomain:VOKBenkodeErrorDomain
                                         code:VOKBenkodeErrorEmptyData
                                     userInfo:nil];
        }
        return nil;
    }
    char *dataBytes = (char *)data.bytes;
    char firstByte = dataBytes[0];
    switch (firstByte) {
        case DictionaryStartDelimiter:
            return [self decodeDict:data
                            options:options
                     stringEncoding:stringEncoding
                              error:error
                             length:length];
            
        case ArrayStartDelimiter:
            return [self decodeArray:data
                             options:options
                      stringEncoding:stringEncoding
                               error:error
                              length:length];
            
        case NumberStartDelimiter:
            return [self decodeNumber:data
                              options:options
                                error:error
                               length:length];
            
        case '0':  // Intentional grouping.
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
            return [self decodeString:data
                              options:options
                       stringEncoding:stringEncoding
                                error:error
                               length:length];
            
        default:
            if (error) {
                *error = [NSError errorWithDomain:VOKBenkodeErrorDomain
                                             code:VOKBenkodeErrorUnknownDataType
                                         userInfo:nil];
            }
            return nil;
    }
}

+ (id)decode:(NSData *)data
     options:(VOKBenkodeDecodeOptions)options
stringEncoding:(NSStringEncoding)stringEncoding
       error:(NSError **)error
{
    return [self decode:data
                options:options
         stringEncoding:stringEncoding
                  error:error
                 length:NULL];
}

+ (id)decode:(NSData *)data
stringEncoding:(NSStringEncoding)stringEncoding
       error:(NSError **)error
{
    return [self decode:data
                options:0
         stringEncoding:stringEncoding
                  error:error];
}

+ (id)decode:(NSData *)data
     options:(VOKBenkodeDecodeOptions)options
       error:(NSError **)error
{
    return [self decode:data
                options:options
         stringEncoding:NSUTF8StringEncoding
                  error:error];
}

+ (id)decode:(NSData *)data
       error:(NSError **)error
{
    return [self decode:data
         stringEncoding:NSUTF8StringEncoding
                  error:error];
}

+ (id)decode:(NSData *)data
stringEncoding:(NSStringEncoding)stringEncoding
{
    return [self decode:data
         stringEncoding:stringEncoding
                  error:NULL];
}

+ (id)decode:(NSData *)data
{
    return [self decode:data
                  error:NULL];
}

#pragma mark Decoding Primitives

+ (NSDictionary *)decodeDict:(NSData *)data
                     options:(VOKBenkodeDecodeOptions)options
              stringEncoding:(NSStringEncoding)stringEncoding
                       error:(NSError **)error
                      length:(NSUInteger *)length
{
    char *dataBytes = (char *)data.bytes;
    NSAssert(dataBytes[0] == DictionaryStartDelimiter, @"Data does not begin with dictionary-data indicator.");
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSUInteger index = 1;
    while (index < data.length
           && dataBytes[index] != EndDelimiter) {
        NSError *innerError;
        NSUInteger innerLength;
        id innerKey = [self decode:[data subdataWithRange:NSMakeRange(index, data.length - index)]
                           options:options
                    stringEncoding:stringEncoding
                             error:&innerError
                            length:&innerLength];
        if (!innerKey) {
            if (error) {
                *error = innerError;
            }
            return nil;
        }
        
        // Is the key a string?
        if ((options & VOKBenkodeDecodeOptionStrict)
            && ![innerKey isKindOfClass:[NSString class]]) {
            // Accoding to the bencode spec, dictionary keys must be strings.
            if (error) {
                *error = [NSError errorWithDomain:VOKBenkodeErrorDomain
                                             code:VOKBenkodeErrorDictionaryKeyNotString
                                         userInfo:nil];
            }
            return nil;
        }
        
        // Do we already have a value for this key?
        if (result[innerKey]) {
            if (error) {
                *error = [NSError errorWithDomain:VOKBenkodeErrorDomain
                                             code:VOKBenkodeErrorDictionaryDuplicateKey
                                         userInfo:nil];
            }
            return nil;
        }
        
        index += innerLength;
        id innerValue = [self decode:[data subdataWithRange:NSMakeRange(index, data.length - index)]
                             options:options
                      stringEncoding:stringEncoding
                               error:&innerError
                              length:&innerLength];
        if (!innerValue) {
            if (error) {
                *error = innerError;
            }
            return nil;
        }
        result[innerKey] = innerValue;
        index += innerLength;
    }
    if (index >= data.length) {
        if (error) {
            *error = [NSError errorWithDomain:VOKBenkodeErrorDomain
                                         code:VOKBenkodeErrorMissingEndingDelimiter
                                     userInfo:nil];
        }
        return nil;
    }
    if (length) {
        *length = index + 1;  // +1 for the EndDelimiter at the end.
    }
    return result;
}

+ (NSArray *)decodeArray:(NSData *)data
                 options:(VOKBenkodeDecodeOptions)options
          stringEncoding:(NSStringEncoding)stringEncoding
                   error:(NSError **)error
                  length:(NSUInteger *)length
{
    char *dataBytes = (char *)data.bytes;
    NSAssert(dataBytes[0] == ArrayStartDelimiter, @"Data does not begin with array-data indicator.");
    NSMutableArray *result = [NSMutableArray array];
    NSUInteger index = 1;
    while (index < data.length
           && dataBytes[index] != EndDelimiter) {
        NSError *innerError;
        NSUInteger innerLength;
        id innerObject = [self decode:[data subdataWithRange:NSMakeRange(index, data.length - index)]
                              options:options
                       stringEncoding:stringEncoding
                                error:&innerError
                               length:&innerLength];
        if (!innerObject) {
            if (error) {
                *error = innerError;
            }
            return nil;
        }
        [result addObject:innerObject];
        index += innerLength;
    }
    if (index >= data.length) {
        if (error) {
            *error = [NSError errorWithDomain:VOKBenkodeErrorDomain
                                         code:VOKBenkodeErrorMissingEndingDelimiter
                                     userInfo:nil];
        }
        return nil;
    }
    if (length) {
        *length = index + 1;  // +1 for the EndDelimiter at the end.
    }
    return result;
}

+ (NSNumber *)decodeNumber:(NSData *)data
                   options:(VOKBenkodeDecodeOptions)options
                     error:(NSError **)error
                    length:(NSUInteger *)length
{
    char *dataBytes = (char *)data.bytes;
    NSAssert(dataBytes[0] == NumberStartDelimiter, @"Data does not begin with numeric-data indicator.");
    NSMutableString *buffer = [NSMutableString stringWithCapacity:data.length - 2];
    NSUInteger index = 1;
    BOOL hasSeenDigit = NO;
    static NSCharacterSet *asciiDigits;
    if (!asciiDigits) {
        asciiDigits = [NSCharacterSet characterSetWithCharactersInString:@"1234567890"];
    }
    while (index < data.length
           && dataBytes[index] != EndDelimiter) {
        char byte = dataBytes[index];
        
        // Check format validity.
        if ([asciiDigits characterIsMember:byte]) {
            hasSeenDigit = YES;
        } else {
            if (hasSeenDigit || (byte != '+' && byte != '-')) {
                if (error) {
                    *error = [NSError errorWithDomain:VOKBenkodeErrorDomain
                                                 code:VOKBenkodeErrorNumberInvalid
                                             userInfo:nil];
                }
                return nil;
            }
        }
        
        // Append to the buffer to be interpreted later.
        [buffer appendFormat:@"%c", byte];
        index++;
    }
    
    // Did we hit the end of the input?
    if (index >= data.length) {
        if (error) {
            *error = [NSError errorWithDomain:VOKBenkodeErrorDomain
                                         code:VOKBenkodeErrorMissingEndingDelimiter
                                     userInfo:nil];
        }
        return nil;
    }
    
    // Did we get actual digits that weren't unnecessarily zero-padded?
    if (![buffer stringByTrimmingCharactersInSet:[asciiDigits invertedSet]].length
        || ((options & VOKBenkodeDecodeOptionStrict)
            && ((buffer.length > 1 && [buffer characterAtIndex:0] == '0')
                || [buffer hasPrefix:@"-0"]
                )
            )
        ) {
        if (error) {
            *error = [NSError errorWithDomain:VOKBenkodeErrorDomain
                                         code:VOKBenkodeErrorNumberInvalid
                                     userInfo:nil];
        }
        return nil;
    }
    
    if (length) {
        *length = index + 1;  // +1 for the EndDelimiter at the end.
    }
    return [NSNumber numberWithLongLong:[buffer longLongValue]];
}

+ (NSString *)decodeString:(NSData *)data
                   options:(VOKBenkodeDecodeOptions)options
            stringEncoding:(NSStringEncoding)stringEncoding
                     error:(NSError **)error
                    length:(NSUInteger *)length
{
    char *dataBytes = (char *)data.bytes;
    NSMutableString *buffer = [NSMutableString stringWithCapacity:data.length - 2];
    NSUInteger index = 0;
    while (index < data.length
           && dataBytes[index] != StringLengthDataSeparator) {
        [buffer appendFormat:@"%c", dataBytes[index]];
        index++;
    }
    
    // Did we hit the end of the input?
    if (index >= data.length) {
        if (error) {
            *error = [NSError errorWithDomain:VOKBenkodeErrorDomain
                                         code:VOKBenkodeErrorStringMissingColon
                                     userInfo:nil];
        }
        return nil;
    }
    long long llStringLength = [buffer longLongValue];
    // Is the string length beyond what can be represented in an NSUInteger?  (NSMakeRange takes NSUInteger inputs, so...)
    if (llStringLength > NSUIntegerMax) {
        if (error) {
            *error = [NSError errorWithDomain:VOKBenkodeErrorDomain
                                         code:VOKBenkodeErrorStringLengthExceedesNSUIntegerMax
                                     userInfo:nil];
        }
        return nil;
    }
    
    // Is the string length negative?
    if (llStringLength < 0) {
        if (error) {
            *error = [NSError errorWithDomain:VOKBenkodeErrorDomain
                                         code:VOKBenkodeErrorStringLengthNegative
                                     userInfo:nil];
        }
        return nil;
    }
    
    // Safe to cast to NSUInteger (in the interval [0, NSUIntegerMax]).
    NSUInteger stringLength = (NSUInteger)llStringLength;
    
    // Is the string length properly formatted (no leading 0s, etc.)?
    if ((options & VOKBenkodeDecodeOptionStrict)
        && ![buffer isEqualToString:[NSString stringWithFormat:@"%@", @(stringLength)]]) {
        if (error) {
            *error = [NSError errorWithDomain:VOKBenkodeErrorDomain
                                         code:VOKBenkodeErrorStringLengthMalformed
                                     userInfo:nil];
        }
        return nil;
    }
    index++;  // +1 for the StringLengthDataSeparator between the length and the string.
    NSUInteger localLength = index + stringLength;
    
    // Does the expected length of the string itself exceed the input?
    if (localLength > data.length) {
        if (error) {
            *error = [NSError errorWithDomain:VOKBenkodeErrorDomain
                                         code:VOKBenkodeErrorStringLengthExceedsData
                                     userInfo:nil];
        }
        return nil;
    }
    
    if (length) {
        *length = localLength;
    }
    NSData *stringData = [data subdataWithRange:NSMakeRange(index, stringLength)];
    NSString *result = [[NSString alloc] initWithData:stringData
                                             encoding:stringEncoding];
    if (!result) {
        if (error) {
            *error = [NSError errorWithDomain:VOKBenkodeErrorDomain
                                         code:VOKBenkodeErrorStringDataInvalid
                                     userInfo:nil];
        }
        return nil;
    }
    return result;
}

@end
