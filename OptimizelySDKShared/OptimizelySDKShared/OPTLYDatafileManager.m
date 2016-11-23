/****************************************************************************
 * Copyright 2016, Optimizely, Inc. and contributors                        *
 *                                                                          *
 * Licensed under the Apache License, Version 2.0 (the "License");          *
 * you may not use this file except in compliance with the License.         *
 * You may obtain a copy of the License at                                  *
 *                                                                          *
 *    http://www.apache.org/licenses/LICENSE-2.0                            *
 *                                                                          *
 * Unless required by applicable law or agreed to in writing, software      *
 * distributed under the License is distributed on an "AS IS" BASIS,        *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. *
 * See the License for the specific language governing permissions and      *
 * limitations under the License.                                           *
 ***************************************************************************/

#import "OPTLYDatafileManager.h"

@implementation OPTLYDatafileManagerUtility

+ (BOOL)conformsToOPTLYDatafileManagerProtocol:(Class)instanceClass {
    // compile time check
    BOOL validProtocolDeclaration = [instanceClass conformsToProtocol:@protocol(OPTLYDatafileManager)];
    
    // runtime check
    BOOL implementsDownloadDatafileMethod = [instanceClass instancesRespondToSelector:@selector(downloadDatafile:completionHandler:)];
    
    return validProtocolDeclaration && implementsDownloadDatafileMethod;
}

@end

@implementation OPTLYDatafileManagerNoOp

- (void)downloadDatafile:(NSString *)projectId completionHandler:(OPTLYHTTPRequestManagerResponse)completion {
    completion(nil, nil, nil);
    return;
}

@end