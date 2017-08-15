//
//  FMDatabaseAdditionsTests.m
//  fmdb
//
//  Created by Graham Dennis on 24/11/2013.
//
//
/****************************************************************************
 * Modifications to FMDB by Optimizely, Inc.                                *
 * Copyright 2017, Optimizely, Inc. and contributors                        *
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

#import <XCTest/XCTest.h>
#import "FMDatabaseAdditions.h"

#if FMDB_SQLITE_STANDALONE
#import <sqlite3/sqlite3.h>
#else
#import <sqlite3.h>
#endif

@interface FMDatabaseAdditionsTests : FMDBTempDBTests

@end

@implementation FMDatabaseAdditionsTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testFunkyTableNames
{
    [self.db executeUpdate:@"create table '234 fds' (foo text)"];
    XCTAssertFalse([self.db hadError], @"table creation should have succeeded");
    FMResultSet *rs = [self.db getTableSchema:@"234 fds"];
    XCTAssertTrue([rs next], @"Schema should have succeded");
    [rs close];
    XCTAssertFalse([self.db hadError], @"There shouldn't be any errors");
}

- (void)testBoolForQuery
{
    BOOL result = [self.db boolForQuery:@"SELECT ? not null", @""];
    XCTAssertTrue(result, @"Empty strings should be considered true");
    
    result = [self.db boolForQuery:@"SELECT ? not null", [NSMutableData data]];
    XCTAssertTrue(result, @"Empty mutable data should be considered true");
    
    result = [self.db boolForQuery:@"SELECT ? not null", [NSData data]];
    XCTAssertTrue(result, @"Empty data should be considered true");
}


- (void)testIntForQuery
{
    [self.db executeUpdate:@"create table t1 (a integer)"];
    [self.db executeUpdate:@"insert into t1 values (?)", [NSNumber numberWithInt:5]];
    
    XCTAssertEqual([self.db changes], 1, @"There should only be one change");
    
    int ia = [self.db intForQuery:@"select a from t1 where a = ?", [NSNumber numberWithInt:5]];
    XCTAssertEqual(ia, 5, @"foo");
}

- (void)testDateForQuery
{
    NSDate *date = [NSDate date];
    [self.db executeUpdate:@"create table datetest (a double, b double, c double)"];
    [self.db executeUpdate:@"insert into datetest (a, b, c) values (?, ?, 0)" , [NSNull null], date];

    NSDate *foo = [self.db dateForQuery:@"select b from datetest where c = 0"];
    XCTAssertEqualWithAccuracy([foo timeIntervalSinceDate:date], 0.0, 1.0, @"Dates should be the same to within a second");
}

- (void)testValidate {
    NSError *error;
    XCTAssert([self.db validateSQL:@"create table datetest (a double, b double, c double)" error:&error]);
    XCTAssertNil(error, @"There should be no error object");
}

- (void)testFailValidate {
    NSError *error;
    XCTAssertFalse([self.db validateSQL:@"blah blah blah" error:&error]);
    XCTAssert(error, @"There should be no error object");
}

- (void)testTableExists {
    XCTAssertTrue([self.db executeUpdate:@"create table t4 (a text, b text)"]);

    XCTAssertTrue([self.db tableExists:@"t4"]);
    XCTAssertFalse([self.db tableExists:@"thisdoesntexist"]);
    
    FMResultSet *rs = [self.db getSchema];
    while ([rs next]) {
        XCTAssertEqualObjects([rs stringForColumn:@"type"], @"table");
    }

}

- (void)testColumnExists {
    [self.db executeUpdate:@"create table nulltest (a text, b text)"];
    
    XCTAssertTrue([self.db columnExists:@"a" inTableWithName:@"nulltest"]);
    XCTAssertTrue([self.db columnExists:@"b" inTableWithName:@"nulltest"]);
    XCTAssertFalse([self.db columnExists:@"c" inTableWithName:@"nulltest"]);
}

- (void)testUserVersion {
    [[self db] setUserVersion:12];
    
    XCTAssertTrue([[self db] userVersion] == 12);
}

@end
