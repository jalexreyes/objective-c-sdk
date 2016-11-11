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

#import "OPTLYQueue.h"

const NSInteger OPTLYQueueDefaultMaxSize = 1000;

@interface OPTLYQueue()
@property (nonatomic, strong) NSMutableArray *mutableQueue;
@end

@implementation OPTLYQueue

- (id)init {
    self = [super init];
    if (self) {
        _maxQueueSize = OPTLYQueueDefaultMaxSize;
        _mutableQueue = [[NSMutableArray alloc] initWithCapacity:_maxQueueSize];
    }
    return self;
}

- (instancetype)initWithQueueSize:(NSInteger)maxQueueSize {
    self = [super init];
    if (self) {
        _maxQueueSize = maxQueueSize;
        _mutableQueue = [[NSMutableArray alloc] initWithCapacity:_maxQueueSize];
    }
    return self;
}

- (bool)enqueue:(id)data {
    if (!self.isFull) {
        [self.mutableQueue addObject:data];
        return true;
    }
    return false;
}

- (id)front {
    id item = nil;
    if (!self.isEmpty) {
        item = [self.mutableQueue objectAtIndex:0];
    }
    return item;
}

- (id)dequeue {
    id item = nil;
    if (!self.isEmpty) {
        item = [self.mutableQueue objectAtIndex:0];
        [self.mutableQueue removeObject:item];
    }
    return item;
}

- (NSInteger)size {
    return [self.queue count];
}

- (bool)isFull {
    return ([self.queue count] >= self.maxQueueSize);
}

- (bool)isEmpty {
    return [self.queue count] == 0;
}

- (NSArray *)queue {
    return [self.mutableQueue copy];
}

@end