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

#import "OPTLYAttribute.h"
#import "OPTLYAudience.h"
#import "OPTLYBucketer.h"
#import "OPTLYDatafileKeys.h"
#import "OPTLYGroup.h"
#import "OPTLYErrorHandler.h"
#import "OPTLYEvent.h"
#import "OPTLYExperiment.h"
#import "OPTLYLog.h"
#import "OPTLYLogger.h"
#import "OPTLYProjectConfig.h"
#import "OPTLYValidator.h"
#import "OPTLYUserProfile.h"

NSString * const kClientEngine             = @"objective-c-sdk-core";

@interface OPTLYProjectConfig()

@property (nonatomic, strong) NSDictionary<NSString *, OPTLYAudience *><Ignore> *audienceIdToAudienceMap;
@property (nonatomic, strong) NSDictionary<NSString *, OPTLYEvent *><Ignore> *eventKeyToEventMap;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *><Ignore> *eventKeyToEventIdMap;
@property (nonatomic, strong) NSDictionary<NSString *, OPTLYExperiment *><Ignore> *experimentIdToExperimentMap;
@property (nonatomic, strong) NSDictionary<NSString *, OPTLYExperiment *><Ignore> *experimentKeyToExperimentMap;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *><Ignore> *experimentKeyToExperimentIdMap;
@property (nonatomic, strong) NSDictionary<NSString *, OPTLYGroup *><Ignore> *groupIdToGroupMap;
@property (nonatomic, strong) NSDictionary<NSString *, OPTLYAttribute *><Ignore> *attributeKeyToAttributeMap;

@end

@implementation OPTLYProjectConfig

- (nullable instancetype)initWithDatafile:(nullable NSData *)datafile
                               withLogger:(nullable id<OPTLYLogger>)logger
                         withErrorHandler:(nullable id<OPTLYErrorHandler>)errorHandler
                          withUserProfile:(nullable id<OPTLYUserProfile>)userProfile
{    
    if (errorHandler) {
        if ([OPTLYErrorHandler conformsToOPTLYErrorHandlerProtocol:[errorHandler class]]) {
            _errorHandler = (id<OPTLYErrorHandler, Ignore>)errorHandler;
        } else {
            _errorHandler = [OPTLYErrorHandlerDefault new];
            NSError *error = [NSError errorWithDomain:OPTLYErrorHandlerMessagesDomain
                                                 code:OPTLYErrorTypesErrorHandlerInvalid
                                             userInfo:@{NSLocalizedDescriptionKey :
                                                            NSLocalizedString(OPTLYErrorHandlerMessagesErrorHandlerInvalid, nil)}];
            [_errorHandler handleError:error];
            
            NSString *logMessage = OPTLYErrorHandlerMessagesErrorHandlerInvalid;
            [_logger logMessage:logMessage withLevel:OptimizelyLogLevelError];
        }
    }
    
    if (logger) {
        if ([logger conformsToProtocol:@protocol(OPTLYLogger)]) {
            _logger = (id<OPTLYLogger, Ignore>)logger;
        } else {
            NSError *error = [NSError errorWithDomain:OPTLYErrorHandlerMessagesDomain
                                                 code:OPTLYErrorTypesLoggerInvalid
                                             userInfo:@{NSLocalizedDescriptionKey :
                                                            NSLocalizedString(OPTLYErrorHandlerMessagesLoggerInvalid, nil)}];
            [_errorHandler handleError:error];
            
            NSString *logMessage = OPTLYErrorHandlerMessagesLoggerInvalid;
            [_logger logMessage:logMessage withLevel:OptimizelyLogLevelError];
        }
    }
    
    if (userProfile) {
        if ([OPTLYUserProfile conformsToOPTLYUserProfileProtocol:[userProfile class]]) {
            _userProfile = userProfile;
        }
        // TODO - log error
    }
    
    OPTLYProjectConfig* projectConfig = nil;
    NSError *datafileError;
    @try {
        if (!datafile) {
            NSError *error = [NSError errorWithDomain:OPTLYErrorHandlerMessagesDomain
                                                 code:OPTLYErrorTypesDatafileInvalid
                                             userInfo:@{NSLocalizedDescriptionKey :
                                                            NSLocalizedString(OPTLYErrorHandlerMessagesDataFileInvalid, nil)}];
            [_errorHandler handleError:error];
            
            NSString *logMessage = OPTLYErrorHandlerMessagesDataFileInvalid;
            [_logger logMessage:logMessage withLevel:OptimizelyLogLevelError];
        } else {
            projectConfig = [[OPTLYProjectConfig alloc] initWithData:datafile error:&datafileError];
        }
    }
    @catch (NSException *datafileException) {
        [_errorHandler handleException:datafileException];
    }
    
    if (datafileError)
    {
        NSError *error = [NSError errorWithDomain:OPTLYErrorHandlerMessagesDomain
                                             code:OPTLYErrorTypesDatafileInvalid
                                         userInfo:datafileError.userInfo];
        [_errorHandler handleError:error];
    }
    
    return projectConfig;
}

#pragma mark -- Getters --
- (OPTLYAudience *)getAudienceForId:(NSString *)audienceId
{
    OPTLYAudience *audience = self.audienceIdToAudienceMap[audienceId];
    if (!audience) {
        NSString *logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesAudienceUnknownForAudienceId, audienceId];
        [self.logger logMessage:logMessage withLevel:OptimizelyLogLevelWarning];
    }
    return audience;
}

- (OPTLYAttribute *)getAttributeForKey:(NSString *)attributeKey {
    OPTLYAttribute *attribute = self.attributeKeyToAttributeMap[attributeKey];
    if (!attribute) {
        NSString *logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesAttributeUnknownForAttributeKey, attributeKey];
        [self.logger logMessage:logMessage withLevel:OptimizelyLogLevelWarning];
    }
    return attribute;
}

- (NSString *)getEventIdForKey:(NSString *)eventKey {
    NSString *eventId = self.eventKeyToEventIdMap[eventKey];
    if (!eventId) {
        NSString *logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesEventIdUnknownForEventKey, eventKey];
        [self.logger logMessage:logMessage withLevel:OptimizelyLogLevelWarning];
    }
    return eventId;
}

- (OPTLYEvent *)getEventForKey:(NSString *)eventKey{
    OPTLYEvent *event = self.eventKeyToEventMap[eventKey];
    if (!event) {
        NSString *logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesEventUnknownForEventKey, eventKey];
        [self.logger logMessage:logMessage withLevel:OptimizelyLogLevelWarning];
    }
    return event;
}

- (OPTLYExperiment *)getExperimentForId:(NSString *)experimentId {
    OPTLYExperiment *experiment = self.experimentIdToExperimentMap[experimentId];
    if (!experiment) {
        NSString *logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesExperimentUnknown, experimentId];
        [self.logger logMessage:logMessage withLevel:OptimizelyLogLevelWarning];
    }
    return experiment;
}

- (OPTLYExperiment *)getExperimentForKey:(NSString *)experimentKey {
    OPTLYExperiment *experiment = self.experimentKeyToExperimentMap[experimentKey];
    if (!experiment) {
        NSString *logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesExperimentUnknownForExperimentKey, experimentKey];
        [self.logger logMessage:logMessage withLevel:OptimizelyLogLevelWarning];
    }
    return experiment;
}

- (NSString *)getExperimentIdForKey:(NSString *)experimentKey
{
    NSString *experimentId = self.experimentKeyToExperimentIdMap[experimentKey];
    if (!experimentId) {
        NSString *logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesExperimentIdUnknownForExperimentKey, experimentKey];
        [self.logger logMessage:logMessage withLevel:OptimizelyLogLevelWarning];
    }
    return experimentId;
}

- (OPTLYGroup *)getGroupForGroupId:(NSString *)groupId {
    OPTLYGroup *group = self.groupIdToGroupMap[groupId];
    if (!group) {
        NSString *logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesGroupUnknownForGroupId, groupId];
        [self.logger logMessage:logMessage withLevel:OptimizelyLogLevelWarning];
    }
    return group;
}

- (OPTLYVariation *)getVariationForVariationKey:(NSString *)variationKey {
    NSArray *allVariations = [self allVariations];
    for (OPTLYVariation *variation in allVariations) {
        if ([variation.variationKey isEqualToString:variationKey]) {
            return variation;
        }
    }
    // TODO - log error
    return nil;
}
#pragma mark -- Property Getters --

- (NSArray *)allExperiments
{
    if (!_allExperiments) {
        NSMutableArray *all = [[NSMutableArray alloc] initWithArray:self.experiments];
        for (OPTLYGroup *group in self.groups) {
            for (OPTLYExperiment *experiment in group.experiments) {
                [all addObject:experiment];
            }
        }
        _allExperiments = [all copy];
    }
    return _allExperiments;
}

- (NSArray *)allVariations
{
    if (!_allVariations) {
        NSMutableArray *all = [NSMutableArray new];
        for (OPTLYExperiment *experiment in [self allExperiments]) {
            [all addObject:experiment.variations];
        }
        _allVariations = [all copy];
    }
    return _allVariations;
}

- (NSDictionary *)audienceIdToAudienceMap
{
    if (!_audienceIdToAudienceMap) {
        _audienceIdToAudienceMap = [self generateAudienceIdToAudienceMap];
    }
    return _audienceIdToAudienceMap;
}


- (NSDictionary *)attributeKeyToAttributeMap
{
    if (!_attributeKeyToAttributeMap) {
        _attributeKeyToAttributeMap = [self generateAttributeToKeyMap];
    }
    return _attributeKeyToAttributeMap;
}

- (NSDictionary *)eventKeyToEventIdMap {
    if (!_eventKeyToEventIdMap) {
        _eventKeyToEventIdMap = [self generateEventKeyToEventIdMap];
    }
    return _eventKeyToEventIdMap;
}

- (NSDictionary *)eventKeyToEventMap {
    if (!_eventKeyToEventMap) {
        _eventKeyToEventMap = [self generateEventKeyToEventMap];
    }
    return _eventKeyToEventMap;
}

- (NSDictionary<NSString *, OPTLYExperiment *> *)experimentIdToExperimentMap {
    if (!_experimentIdToExperimentMap) {
        _experimentIdToExperimentMap = [self generateExperimentIdToExperimentMap];
    }
    return _experimentIdToExperimentMap;
}

- (NSDictionary<NSString *, OPTLYExperiment *> *)experimentKeyToExperimentMap {
    if (!_experimentKeyToExperimentMap) {
        _experimentKeyToExperimentMap = [self generateExperimentKeyToExperimentMap];
    }
    return  _experimentKeyToExperimentMap;
}

- (NSDictionary<NSString *, NSString *> *)experimentKeyToExperimentIdMap
{
    if (!_experimentKeyToExperimentIdMap) {
        _experimentKeyToExperimentIdMap = [self generateExperimentKeyToIdMap];
    }
    return _experimentKeyToExperimentIdMap;
}

- (NSDictionary<NSString *, OPTLYGroup *> *)groupIdToGroupMap {
    if (!_groupIdToGroupMap) {
        _groupIdToGroupMap = [OPTLYProjectConfig generateGroupIdToGroupMapFromGroupsArray:_groups];
    }
    return _groupIdToGroupMap;
}

#pragma mark -- Generate Mappings --

- (NSDictionary *)generateAudienceIdToAudienceMap
{
    NSMutableDictionary *map = [NSMutableDictionary new];
    for (OPTLYAudience *audience in self.audiences) {
        NSString *audienceId = audience.audienceId;
        map[audienceId] = audience;
    }
    return map;
}

- (NSDictionary *)generateAttributeToKeyMap
{
    NSMutableDictionary *map = [NSMutableDictionary new];
    for (OPTLYAttribute *attribute in self.attributes) {
        NSString *attributeKey = attribute.attributeKey;
        map[attributeKey] = attribute;
    }
    return map;
}

+ (NSDictionary<NSString *, OPTLYEvent *> *)generateEventIdToEventMapFromEventArray:(NSArray<OPTLYEvent *> *) events {
    NSMutableDictionary *map = [[NSMutableDictionary alloc] initWithCapacity:events.count];
    for (OPTLYEvent *event in events) {
        map[event.eventId] = event;
    }
    return [NSDictionary dictionaryWithDictionary:map];
}

- (NSDictionary<NSString *, NSString *> *)generateEventKeyToEventIdMap
{
    NSMutableDictionary *map = [[NSMutableDictionary alloc] initWithCapacity:self.events.count];
    for (OPTLYEvent *event in self.events) {
        map[event.eventKey] = event.eventId;
    }
    return [map copy];
}

- (NSDictionary<NSString *, OPTLYEvent *> *)generateEventKeyToEventMap
{
    NSMutableDictionary *map = [[NSMutableDictionary alloc] initWithCapacity:self.events.count];
    for (OPTLYEvent *event in self.events) {
        map[event.eventKey] = event;
    }
    return [map copy];
}

- (NSDictionary<NSString *, OPTLYExperiment *> *)generateExperimentIdToExperimentMap {
    NSMutableDictionary *map = [[NSMutableDictionary alloc] init];
    for (OPTLYExperiment *experiment in self.allExperiments) {
        map[experiment.experimentId] = experiment;
    }
    
    return [NSDictionary dictionaryWithDictionary:map];
}

- (NSDictionary<NSString *, OPTLYExperiment *> *)generateExperimentKeyToExperimentMap {
    NSMutableDictionary *map = [[NSMutableDictionary alloc] init];
    for (OPTLYExperiment *experiment in self.allExperiments) {
        map[experiment.experimentKey] = experiment;
    }
    return [NSDictionary dictionaryWithDictionary:map];
}

- (NSDictionary<NSString *, NSString *> *)generateExperimentKeyToIdMap {
    NSMutableDictionary *map = [[NSMutableDictionary alloc] init];
    for (OPTLYExperiment *experiment in self.allExperiments) {
        map[experiment.experimentKey] = experiment.experimentId;
    }
    return [map copy];
}

+ (NSDictionary<NSString *, OPTLYGroup *> *)generateGroupIdToGroupMapFromGroupsArray:(NSArray<OPTLYGroup *> *) groups{
    NSMutableDictionary *map = [[NSMutableDictionary alloc] initWithCapacity:groups.count];
    for (OPTLYGroup *group in groups) {
        map[group.groupId] = group;
    }
    return [NSDictionary dictionaryWithDictionary:map];
}

# pragma mark - Helper Methods

- (OPTLYVariation *)getVariationForExperiment:(NSString *)experimentKey
                                       userId:(NSString *)userId
                                   attributes:(NSDictionary<NSString *,NSString *> *)attributes
                                     bucketer:(id<OPTLYBucketer>)bucketer
{
    OPTLYExperiment *experiment = [self getExperimentForKey:experimentKey];
    OPTLYVariation *variation;
    
    // validate preconditions
    if ([OPTLYValidator validatePreconditions:self
                                experimentKey:experiment.experimentKey
                                       userId:userId
                                   attributes:attributes]) {
        
        // bucket user into a variation
        variation = [bucketer bucketExperiment:experiment withUserId:userId];
        if (variation != nil) {
            NSString *logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesVariationUserAssigned, userId, variation.variationKey, experiment.experimentKey];
            [self.logger logMessage:logMessage withLevel:OptimizelyLogLevelInfo];
        }
    }
    
    return variation;
}

- (NSString *)clientEngine
{
    return kClientEngine;
}

- (NSString *)clientVersion
{
    return OPTIMIZELY_SDK_CORE_VERSION;
}

@end
