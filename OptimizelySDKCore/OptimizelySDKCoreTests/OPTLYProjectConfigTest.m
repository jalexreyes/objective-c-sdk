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

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "OPTLYAttribute.h"
#import "OPTLYAudience.h"
#import "OPTLYBucketer.h"
#import "OPTLYErrorHandler.h"
#import "OPTLYEvent.h"
#import "OPTLYExperiment.h"
#import "OPTLYGroup.h"
#import "OPTLYLogger.h"
#import "OPTLYProjectConfig.h"
#import "OPTLYUserProfileServiceBasic.h"
#import "OPTLYTestHelper.h"
#import "OPTLYVariation.h"
#import "OPTLYVariable.h"

// static data from datafile
static NSString * const kClientEngine = @"objective-c-sdk";
static NSString * const kDataModelDatafileName = @"datafile_6372300739";
static NSString * const kDatafileNameAnonymizeIPFalse = @"test_data_25_experiments";
static NSString * const kRevision = @"58";
static NSString * const kProjectId = @"6372300739";
static NSString * const kAccountId = @"6365361536";

static NSString * const kInvalidDatafileVersionDatafileName = @"InvalidDatafileVersionDatafile";

@interface OPTLYProjectConfigTest : XCTestCase
@property (nonatomic, strong) OPTLYProjectConfig *projectConfig;
@property (nonatomic, strong) OPTLYBucketer *bucketer;
@end

@implementation OPTLYProjectConfigTest

- (void)setUp {
    [super setUp];
    
    NSData *datafile = [OPTLYTestHelper loadJSONDatafileIntoDataObject:kDataModelDatafileName];
    self.projectConfig = [OPTLYProjectConfig init:^(OPTLYProjectConfigBuilder * _Nullable builder){
        builder.datafile = datafile;
        builder.logger = [OPTLYLoggerDefault new];
        builder.errorHandler = [OPTLYErrorHandlerNoOp new];
        builder.userProfileService = [OPTLYUserProfileServiceNoOp new];
    }];
    
    self.bucketer = [[OPTLYBucketer alloc] initWithConfig:self.projectConfig];
}


- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - Test init:

- (void)testInitWithBuilderBlock
{
    NSData *datafile = [OPTLYTestHelper loadJSONDatafileIntoDataObject:kDataModelDatafileName];
    OPTLYProjectConfig *projectConfig = [OPTLYProjectConfig init:^(OPTLYProjectConfigBuilder * _Nullable builder){
        builder.datafile = datafile;
        builder.logger = [OPTLYLoggerDefault new];
        builder.errorHandler = [OPTLYErrorHandlerNoOp new];
        builder.userProfileService = [OPTLYUserProfileServiceNoOp new];
    }];
    
    XCTAssertNotNil(projectConfig, @"project config should not be nil.");
    XCTAssertNotNil(projectConfig.logger, @"logger should not be nil.");
    XCTAssertNotNil(projectConfig.errorHandler, @"error handler should not be nil.");
    XCTAssertNotNil(projectConfig.userProfileService, @"User profile should not be nil.");
    XCTAssertEqualObjects(projectConfig.clientEngine, kClientEngine, @"Invalid client engine: %@. Expected: %@.", projectConfig.clientEngine, kClientEngine);
    XCTAssertEqualObjects(projectConfig.clientVersion, OPTIMIZELY_SDK_CORE_VERSION, @"Invalid client version: %@. Expected: %@.", projectConfig.clientVersion, OPTIMIZELY_SDK_CORE_VERSION);
}
/**
 * Make sure we can pass in different values for client engine and client version to override the defaults.
 */
- (void)testClientEngineAndClientVersionAreConfigurable {
    NSData *datafile = [OPTLYTestHelper loadJSONDatafileIntoDataObject:kDataModelDatafileName];
    NSString *clientEngine = @"clientEngine";
    NSString *clientVersion = @"clientVersion";
    
    OPTLYProjectConfig *projectConfig = [OPTLYProjectConfig init:^(OPTLYProjectConfigBuilder * _Nullable builder) {
        builder.datafile = datafile;
        builder.clientEngine = clientEngine;
        builder.clientVersion = clientVersion;
    }];
    XCTAssertNotNil(projectConfig);
    XCTAssertEqualObjects(projectConfig.clientEngine, clientEngine);
    XCTAssertEqualObjects(projectConfig.clientVersion, clientVersion);
}

- (void)testInitWithBuilderBlockNoDatafile
{
    OPTLYProjectConfig *projectConfig = [OPTLYProjectConfig init:^(OPTLYProjectConfigBuilder * _Nullable builder){
        builder.datafile = nil;
    }];
    
    XCTAssertNil(projectConfig, @"project config should be nil.");
}

- (void)testInitWithBuilderBlockInvalidModulesFails {
    NSData *datafile = [OPTLYTestHelper loadJSONDatafileIntoDataObject:kDataModelDatafileName];
    
    id<OPTLYUserProfileService> userProfileService = [NSObject new];
    id<OPTLYLogger> logger = [NSObject new];
    id<OPTLYErrorHandler> errorHandler = [NSObject new];
    
    OPTLYProjectConfig *projectConfig = [OPTLYProjectConfig init:^(OPTLYProjectConfigBuilder * _Nullable builder){
        builder.datafile = datafile;
        builder.logger = logger;
        builder.errorHandler = errorHandler;
    }];
    
    XCTAssertNil(projectConfig.userProfileService, @"Invalid user profile should not have been set.");
    XCTAssertNil(projectConfig, @"project config should not be able to be created with invalid modules.");
}

#pragma mark - Test initWithDatafile:

- (void)testInitWithDatafile
{
    NSData *datafile = [OPTLYTestHelper loadJSONDatafileIntoDataObject:kDataModelDatafileName];
    OPTLYProjectConfig *projectConfig = [[OPTLYProjectConfig alloc] initWithDatafile:datafile];
    [self checkProjectConfigProperties:projectConfig];
}

- (void)testInitWithAnonymizeIPFalse {
    NSData *datafile = [OPTLYTestHelper loadJSONDatafileIntoDataObject:kDatafileNameAnonymizeIPFalse];
    OPTLYProjectConfig *projectConfig = [[OPTLYProjectConfig alloc] initWithDatafile:datafile];
    
    XCTAssertFalse(projectConfig.anonymizeIP, @"IP anonymization should be set to false.");
}

#pragma mark - Test getExperimentForKey:

- (void)testGetExperimentForKey
{
    NSString* experimentKey = @"testExperiment31";
    OPTLYExperiment *experiment = [self.projectConfig getExperimentForKey:experimentKey];
    XCTAssertNotNil(experiment, @"Should find experiment for key: %@", experimentKey);
    XCTAssert([experiment isKindOfClass:[OPTLYExperiment class]], @"Expected to be an OPTLYExperiment: %@", experiment);
    XCTAssertEqualObjects(experiment.experimentKey, experimentKey,
                          @"Expecting experiment's experimentKey %@ to be: %@", experiment.experimentKey, experimentKey);
}

- (void)testGetExperimentForNonexistentKey
{
    NSString* experimentKey = @"testExperimentDoesntExist";
    OPTLYExperiment *experiment = [self.projectConfig getExperimentForKey:experimentKey];
    XCTAssertNil(experiment, @"Shouldn't find experiment for key: %@", experimentKey);
}
#pragma mark - Test getExperimentForId:

- (void)testGetExperimentForId
{
    NSString* experimentId = @"6313973431";
    OPTLYExperiment *experiment = [self.projectConfig getExperimentForId:experimentId];
    XCTAssertNotNil(experiment, @"Should find experiment for id: %@", experimentId);
    XCTAssert([experiment isKindOfClass:[OPTLYExperiment class]], @"Expected to be an OPTLYExperiment: %@", experiment);
    XCTAssertEqualObjects(experiment.experimentId, experimentId,
                          @"Expecting experiment's experimentId %@ to be: %@", experiment.experimentId, experimentId);
}

- (void)testGetExperimentForNonexistentId
{
    NSString* experimentId = @"66666666666";
    OPTLYExperiment *experiment = [self.projectConfig getExperimentForId:experimentId];
    XCTAssertNil(experiment, @"Shouldn't find experiment for id: %@", experimentId);
}

#pragma mark - Test getExperimentIdForKey:

- (void)testGetExperimentIdForKey
{
    NSString* experimentKey = @"testExperiment31";
    NSString* experimentId = [self.projectConfig getExperimentIdForKey:experimentKey];
    XCTAssertNotNil(experimentId, @"Should find experiment id for key: %@", experimentKey);
    XCTAssert([experimentId isKindOfClass:[NSString class]], @"Expected to be an NSString: %@", experimentId);
    XCTAssertEqualObjects(experimentId, @"6313973431",
                          @"Expecting experiment's experimentKey %@ to be: %@", experimentId, @"6313973431");
}

- (void)testGetExperimentIdForNonexistentKey
{
    NSString* experimentKey = @"testExperimentDoesntExist";
    NSString* experimentId = [self.projectConfig getExperimentIdForKey:experimentKey];
    XCTAssertNil(experimentId, @"Shouldn't find experiment id for key: %@", experimentKey);
}

#pragma mark - Test getGroupForGroupId:

- (void)testGetGroupForGroupId
{
    NSString* groupId = @"6455220163";
    OPTLYGroup* group = [self.projectConfig getGroupForGroupId:groupId];
    XCTAssertNotNil(group, @"Should find group for id: %@", groupId);
    XCTAssert([group isKindOfClass:[OPTLYGroup class]], @"Expected to be an OPTLYGroup: %@", group);
    XCTAssertEqualObjects(group.groupId, groupId,
                          @"Expecting group's groupId %@ to be: %@", group.groupId, groupId);
}

- (void)testGetGroupForNonexistentId
{
    NSString* groupId = @"66666666666";
    OPTLYGroup *group = [self.projectConfig getGroupForGroupId:groupId];
    XCTAssertNil(group, @"Shouldn't find group for id: %@", groupId);
}

#pragma mark - Test getEventIdForKey:

- (void)testGetEventIdForKey
{
    NSString* eventKey = @"testEvent";
    NSString* eventId = [self.projectConfig getEventIdForKey:eventKey];
    XCTAssertNotNil(eventId, @"Should find event id for key: %@", eventKey);
    XCTAssert([eventId isKindOfClass:[NSString class]], @"Expected to be an NSString: %@", eventId);
    XCTAssertEqualObjects(eventId, @"6370537431",
                          @"Expecting event's eventId %@ to be: %@", eventId, @"6370537431");
}

- (void)testGetEventIdForNonexistentKey
{
    NSString* eventKey = @"testEventDoesntExist";
    NSString* eventId = [self.projectConfig getEventIdForKey:eventKey];
    XCTAssertNil(eventId, @"Shouldn't find event id for key: %@", eventKey);
}

#pragma mark - Test getEventForKey:

- (void)testGetEventForKey
{
    NSString* eventKey = @"testEvent";
    OPTLYEvent *event = [self.projectConfig getEventForKey:eventKey];
    XCTAssertNotNil(event, @"Should find event for key: %@", eventKey);
    XCTAssert([event isKindOfClass:[OPTLYEvent class]], @"Expected to be an OPTLYEvent: %@", event);
    XCTAssertEqualObjects(event.eventKey, eventKey,
                          @"Expecting event's eventKey %@ to be: %@", event.eventKey, eventKey);
}

- (void)testGetEventForNonexistentKey
{
    NSString* eventKey = @"nonexistent_browser_type";
    OPTLYEvent *event = [self.projectConfig getEventForKey:eventKey];
    XCTAssertNil(event, @"Shouldn't find event for id: %@", eventKey);
}

#pragma mark - Test getAttributeForKey:

- (void)testGetAttributeForKey
{
    NSString* attributeKey = @"browser_type";
    OPTLYAttribute *attribute = [self.projectConfig getAttributeForKey:attributeKey];
    XCTAssertNotNil(attribute, @"Should find attribute for key: %@", attributeKey);
    XCTAssert([attribute isKindOfClass:[OPTLYAttribute class]], @"Expected to be an OPTLYAttribute: %@", attribute);
    XCTAssertEqualObjects(attribute.attributeKey, attributeKey,
                          @"Expecting attribute's attributeKey %@ to be: %@", attribute.attributeKey, attributeKey);
}

- (void)testGetAttributeForNonexistentKey
{
    NSString* attributeKey = @"nonexistent_browser_type";
    OPTLYAttribute *attribute = [self.projectConfig getAttributeForKey:attributeKey];
    XCTAssertNil(attribute, @"Shouldn't find attribute for id: %@", attributeKey);
}

#pragma mark - Test getAudienceForId:

- (void)testGetAudienceForId
{
    NSString* audienceId = @"6373742627";
    OPTLYAudience *audience = [self.projectConfig getAudienceForId:audienceId];
    XCTAssertNotNil(audience, @"Should find audience for id: %@", audienceId);
    XCTAssert([audience isKindOfClass:[OPTLYAudience class]], @"Expected to be an OPTLYAudience: %@", audience);
    XCTAssertEqualObjects(audience.audienceId, audienceId,
                          @"Expecting audience's audienceId %@ to be: %@", audience.audienceId, audienceId);
}

- (void)testGetAudienceForNonexistentId
{
    NSString* audienceId = @"66666666666";
    OPTLYAudience *audience = [self.projectConfig getAudienceForId:audienceId];
    XCTAssertNil(audience, @"Shouldn't find audience for id: %@", audienceId);
}

#pragma mark - Test getVariableForVariableKey:

- (void)testGetVariableForVariableKey
{
    NSString* variableKey = @"someString";
    OPTLYVariable *variable = [self.projectConfig getVariableForVariableKey:variableKey];
    XCTAssertNotNil(variable, @"Should find variable for key: %@", variableKey);
    XCTAssert([variable isKindOfClass:[OPTLYVariable class]], @"Expected to be an OPTLYVariable: %@", variable);
    XCTAssertEqualObjects(variable.variableKey, variableKey,
                          @"Expecting variable's variableKey %@ to be: %@", variable.variableKey, variableKey);
}

- (void)testGetVariableForVariableNonexistentKey
{
    NSString* variableKey = @"someBlob";
    OPTLYVariable *variable = [self.projectConfig getVariableForVariableKey:variableKey];
    XCTAssertNil(variable, @"Shouldn't find variable for key: %@", variableKey);
}

#pragma mark - Test setForcedVariation:userId:variationKey: and getForcedVariation:userId:

- (void)testSetForcedVariationAndGetForcedVariation
{
    NSString* experimentKey = @"testExperiment31";
    [self.projectConfig setForcedVariation:experimentKey
                                 userId:@"user_a"
                           variationKey:@"variation"];
    OPTLYVariation* variation = [self.projectConfig getForcedVariation:experimentKey
                                                                userId:@"user_a"];
    XCTAssertNotNil(variation, @"getForcedVariation should find forced variation");
    XCTAssert([variation isKindOfClass:[OPTLYVariation class]], @"Expected to be an OPTLYVariation: %@", variation);
    XCTAssertEqualObjects(variation.variationKey, @"variation",
                          @"Expecting variation's variationKey %@ to be: %@", variation.variationKey, @"variation");
}

- (void)testGetForcedVariationWhenNoVariationIsForced
{
    NSString* experimentKey = @"testExperiment31";
    OPTLYVariation* variation = [self.projectConfig getForcedVariation:experimentKey
                                                                userId:@"user_a"];
    XCTAssertNil(variation, @"getForcedVariation shouldn't find forced variation");
}

#pragma mark - Test getVariationForExperiment:userId:attributes:bucketer:

// "user_b": "b"
- (void)testGetVariationWhitelisted
{
    OPTLYVariation *variation = [self.projectConfig getVariationForExperiment:@"mutex_exp2"
                                                                       userId:@"user_b"
                                                                   attributes:@{@"abc":@"123"}
                                                                     bucketer:self.bucketer];
    
    XCTAssert([variation.variationKey isEqualToString:@"b"], @"Invalid variation for getVariation with whitelisted user: %@", variation.variationKey);
}

- (void)testGetVariationAudience
{
    // invalid audience
    OPTLYVariation *variationInvalidAudience = [self.projectConfig getVariationForExperiment:@"testExperimentWithFirefoxAudience"
                                                                                      userId:@"user_b"
                                                                                  attributes:@{@"browser_type":@"chrome"}
                                                                                    bucketer:self.bucketer];
    
    XCTAssertNil(variationInvalidAudience, @"Variation should be nil for experiment that does not pass audience evaluation: %@", variationInvalidAudience);
    
    // valid audience
    OPTLYVariation *variationValidAudience = [self.projectConfig getVariationForExperiment:@"testExperimentWithFirefoxAudience"
                                                                                    userId:@"user_b"
                                                                                attributes:@{@"browser_type":@"firefox"}
                                                                                  bucketer:self.bucketer];
    XCTAssert([variationValidAudience.variationKey isEqualToString:@"variation"], @"Invalid variation for getVariation with whitelisted user: %@", variationValidAudience.variationKey);
}

- (void)testGetVariationExperiment
{
    // experiment does not exist
    OPTLYVariation *variationExpNotExist = [self.projectConfig getVariationForExperiment:@"invalidExperiment"
                                                                                  userId:@"user_b"
                                                                              attributes:@{@"abc":@"123"}
                                                                                bucketer:self.bucketer];
    XCTAssertNil(variationExpNotExist, @"Variation should be nil for experiment that does not exist: %@", variationExpNotExist.variationKey);
    
    // experiment is paused
    OPTLYVariation *variationExpNotRunning = [self.projectConfig getVariationForExperiment:@"testExperimentNotRunning"
                                                                                    userId:@"user_b"
                                                                                attributes:nil
                                                                                  bucketer:self.bucketer];
    XCTAssertNil(variationExpNotRunning, @"Variation should be nil for experiment that is paused: %@", variationExpNotRunning.variationKey);
}

#pragma mark - Helper Methods

// Check all properties in an ProjectConfig object
- (void)checkProjectConfigProperties:(OPTLYProjectConfig *)projectConfig
{
    XCTAssertNotNil(projectConfig, @"ProjectConfig is nil.");
    
    // validate projectId
    NSAssert([projectConfig.projectId isEqualToString:kProjectId], @"Invalid project id.");
    
    // validate accountID
    NSAssert([projectConfig.accountId isEqualToString:kAccountId], @"Invalid account id.");
    
    // validate version number
    NSAssert([projectConfig.version isEqualToString:kExpectedDatafileVersion], @"Invalid version number.");
    
    // validate revision number
    NSAssert([projectConfig.revision isEqualToString:kRevision], @"Invalid revision number.");
    
    // validate IP anonymization value
    XCTAssertTrue(projectConfig.anonymizeIP, @"IP anonymization should be set to true.");
    
    // check experiments
    NSAssert([projectConfig.experiments count] == 48, @"deserializeJSONArray failed to deserialize the right number of experiments objects in project config.");
    for (id experiment in projectConfig.experiments) {
        NSAssert([experiment isKindOfClass:[OPTLYExperiment class]], @"deserializeJSONArray failed to deserialize the experiment object in project config.");
    }
    
    // check audiences
    NSAssert([projectConfig.audiences count] == 8, @"deserializeJSONArray failed to deserialize the right number of audience objects in project config.");
    for (id audience in projectConfig.audiences) {
        NSAssert([audience isKindOfClass:[OPTLYAudience class]], @"deserializeJSONArray failed to deserialize the audience object in project config.");
    }
    
    // check attributes
    NSAssert([projectConfig.attributes count] == 1, @"deserializeJSONArray failed to deserialize the right number of attribute objects in project config.");
    for (id attribute in projectConfig.attributes) {
        NSAssert([attribute isKindOfClass:[OPTLYAttribute class]], @"deserializeJSONArray failed to deserialize the attribute object in project config.");
    }
    
    // check groups
    NSAssert([projectConfig.groups count] == 1, @"deserializeJSONArray failed to deserialize the right number of group objects in project config.");
    for (id group in projectConfig.groups) {
        NSAssert([group isKindOfClass:[OPTLYGroup class]], @"deserializeJSONArray failed to deserialize the group object in project config.");
    }
    
    // check events
    NSAssert([projectConfig.events count] == 7, @"deserializeJSONArray failed to deserialize the right number of event objects in project config.");
    for (id event in projectConfig.events) {
        NSAssert([event isKindOfClass:[OPTLYEvent class]], @"deserializeJSONArray failed to deserialize the event object in project config.");
    }
}

@end
