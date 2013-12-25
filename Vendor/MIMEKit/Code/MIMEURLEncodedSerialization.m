//
//  MIMEURLEncodedSerialization.m
//  MIMEKit
//
//  Created by Blake Watters on 9/4/12.
//  Copyright (c) 2012 MIMEKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "MIMEURLEncodedSerialization.h"

@implementation MIMEURLEncodedSerialization

+ (id)objectFromData:(NSData *)data error:(NSError **)error
{
    NSString *string = [NSString stringWithUTF8String:[data bytes]];
    return MIMEDictionaryFromURLEncodedStringWithEncoding(string, NSUTF8StringEncoding);
}

+ (NSData *)dataFromObject:(id)object error:(NSError **)error
{
    NSString *string = MIMEURLEncodedStringFromDictionaryWithEncoding(object, NSUTF8StringEncoding);
    return [string dataUsingEncoding:NSUTF8StringEncoding];
}

@end

NSDictionary *MIMEDictionaryFromURLEncodedStringWithEncoding(NSString *URLEncodedString, NSStringEncoding encoding)
{
    NSMutableDictionary *queryComponents = [NSMutableDictionary dictionary];
    for (NSString *keyValuePairString in [URLEncodedString componentsSeparatedByString:@"&"]) {
        NSArray *keyValuePairArray = [keyValuePairString componentsSeparatedByString:@"="];
        if ([keyValuePairArray count] < 2) continue; // Verify that there is at least one key, and at least one value.  Ignore extra = signs
        NSString *key = [[keyValuePairArray objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:encoding];
        NSString *value = [[keyValuePairArray objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:encoding];
        
        // URL spec says that multiple values are allowed per key
        id results = [queryComponents objectForKey:key];
        if (results) {
            if ([results isKindOfClass:[NSMutableArray class]]) {
                [(NSMutableArray *)results addObject:value];
            } else {
                // On second occurrence of the key, convert into an array
                NSMutableArray *values = [NSMutableArray arrayWithObjects:results, value, nil];
                [queryComponents setObject:values forKey:key];
            }
        } else {
            [queryComponents setObject:value forKey:key];
        }
    }
    return queryComponents;
}

//extern NSString *AFQueryStringFromParametersWithEncoding(NSDictionary *parameters, NSStringEncoding stringEncoding);
NSString *MIMEURLEncodedStringFromDictionaryWithEncoding(NSDictionary *dictionary, NSStringEncoding encoding)
{
//    return AFQueryStringFromParametersWithEncoding(dictionary, encoding);
    return nil;
}

// This replicates `AFPercentEscapedQueryStringPairMemberFromStringWithEncoding`. Should send PR exposing non-static version
NSString *MIMEPercentEscapedQueryStringFromStringWithEncoding(NSString *string, NSStringEncoding encoding)
{
    // Escape characters that are legal in URIs, but have unintentional semantic significance when used in a query string parameter
    static NSString * const kAFLegalCharactersToBeEscaped = @":/.?&=;+!@$()~";

	return (__bridge_transfer  NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, NULL, (__bridge CFStringRef)kAFLegalCharactersToBeEscaped, CFStringConvertNSStringEncodingToEncoding(encoding));
}

NSDictionary *MIMEQueryParametersFromStringWithEncoding(NSString *string, NSStringEncoding encoding)
{
    NSRange chopRange = [string rangeOfString:@"?"];
    if (chopRange.length > 0) {
        chopRange.location += 1; // we want inclusive chopping up *through *"?"
        if (chopRange.location < [string length]) string = [string substringFromIndex:chopRange.location];
    }
    return MIMEDictionaryFromURLEncodedStringWithEncoding(string, encoding);
}
