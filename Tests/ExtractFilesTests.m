//
//  ExtractFilesTests.m
//  UnzipKit
//
//  Created by Dov Frankel on 7/16/15.
//  Copyright (c) 2015 Abbey Code. All rights reserved.
//

#import "UZKArchiveTestCase.h"
@import UnzipKit;

@interface ExtractFilesTests : UZKArchiveTestCase
@end

@implementation ExtractFilesTests


- (void)testExtractFiles
{
    NSArray *testArchives = @[@"Test Archive.zip",
                              @"Test Archive (Password).zip"];
    
    NSSet *expectedFileSet = self.nonZipTestFilePaths;
    NSArray *expectedFiles = [expectedFileSet.allObjects sortedArrayUsingSelector:@selector(compare:)];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    for (NSString *testArchiveName in testArchives) {
        NSURL *testArchiveURL = self.testFileURLs[testArchiveName];
        NSString *extractDirectory = [self randomDirectoryWithPrefix:
                                      [testArchiveName stringByDeletingPathExtension]];
        NSURL *extractURL = [self.tempDirectory URLByAppendingPathComponent:extractDirectory];
        
        NSString *password = ([testArchiveName rangeOfString:@"Password"].location != NSNotFound
                              ? @"password"
                              : nil);
        UZKArchive *archive = [[UZKArchive alloc] initWithURL:testArchiveURL password:password error:nil];
        
        NSError *error = nil;
        BOOL success = [archive extractFilesTo:extractURL.path
                                     overwrite:NO
                                      progress:^(UZKFileInfo *currentFile, CGFloat percentArchiveDecompressed) {
#if DEBUG
                                          NSLog(@"Extracting %@: %f%% complete", currentFile.filename, percentArchiveDecompressed);
#endif
                                      }
                                         error:&error];
        
        XCTAssertNil(error, @"Error returned by extractFilesTo:overWrite:error:");
        XCTAssertTrue(success, @"Failed to extract %@ to %@", testArchiveName, extractURL);
        
        error = nil;
        NSArray *extractedFiles = [fm contentsOfDirectoryAtPath:extractURL.path
                                                          error:&error];
        
        XCTAssertNil(error, @"Failed to list contents of extract directory: %@", extractURL);
        
        XCTAssertNotNil(extractedFiles, @"No list of files returned");
        XCTAssertEqual(extractedFiles.count, expectedFileSet.count,
                       @"Incorrect number of files listed in archive");
        
        for (NSUInteger i = 0; i < extractedFiles.count; i++) {
            NSString *extractedFilename = extractedFiles[i];
            NSString *expectedFilename = expectedFiles[i];
            
            XCTAssertEqualObjects(extractedFilename, expectedFilename, @"Incorrect filename listed");
            
            NSURL *extractedFileURL = [extractURL URLByAppendingPathComponent:extractedFilename];
            NSURL *expectedFileURL = self.testFileURLs[expectedFilename];
            
            NSData *extractedFileData = [NSData dataWithContentsOfURL:extractedFileURL];
            NSData *expectedFileData = [NSData dataWithContentsOfURL:expectedFileURL];
            
            XCTAssertTrue([expectedFileData isEqualToData:extractedFileData], @"Data in file doesn't match source");
        }
    }
}

- (void)testExtractFiles_Unicode
{
    NSSet *expectedFileSet = self.nonZipUnicodeFilePaths;
    NSArray *expectedFiles = [expectedFileSet.allObjects sortedArrayUsingSelector:@selector(compare:)];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *testArchiveName = @"Ⓣest Ⓐrchive.zip";
    NSURL *testArchiveURL = self.unicodeFileURLs[testArchiveName];
    NSString *extractDirectory = [self randomDirectoryWithPrefix:
                                  [testArchiveName stringByDeletingPathExtension]];
    NSURL *extractURL = [self.tempDirectory URLByAppendingPathComponent:extractDirectory];
    
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:testArchiveURL error:nil];
    
    NSError *error = nil;
    BOOL success = [archive extractFilesTo:extractURL.path
                                 overwrite:NO
                                  progress:^(UZKFileInfo *currentFile, CGFloat percentArchiveDecompressed) {
#if DEBUG
                                      NSLog(@"Extracting %@: %f%% complete", currentFile.filename, percentArchiveDecompressed);
#endif
                                  }
                                     error:&error];
    
    XCTAssertNil(error, @"Error returned by extractFilesTo:overWrite:error:");
    XCTAssertTrue(success, @"Failed to extract %@ to %@", testArchiveName, extractURL);
    
    error = nil;
    NSArray *extractedFiles = [fm contentsOfDirectoryAtPath:extractURL.path
                                                      error:&error];
    
    XCTAssertNil(error, @"Failed to list contents of extract directory: %@", extractURL);
    
    XCTAssertNotNil(extractedFiles, @"No list of files returned");
    XCTAssertEqual(extractedFiles.count, expectedFileSet.count,
                   @"Incorrect number of files listed in archive");
    
    for (NSUInteger i = 0; i < extractedFiles.count; i++) {
        NSString *extractedFilename = extractedFiles[i];
        NSString *expectedFilename = expectedFiles[i];
        
        XCTAssertEqualObjects(extractedFilename, expectedFilename, @"Incorrect filename listed");
        
        NSURL *extractedFileURL = [extractURL URLByAppendingPathComponent:extractedFilename];
        NSURL *expectedFileURL = self.unicodeFileURLs[expectedFilename];
        
        NSData *extractedFileData = [NSData dataWithContentsOfURL:extractedFileURL];
        NSData *expectedFileData = [NSData dataWithContentsOfURL:expectedFileURL];
        
        XCTAssertTrue([expectedFileData isEqualToData:extractedFileData], @"Data in file doesn't match source");
    }
}

- (void)testExtractFiles_NoPasswordGiven
{
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:self.testFileURLs[@"Test Archive (Password).zip"] error:nil];
    
    NSString *extractDirectory = [self randomDirectoryWithPrefix:archive.filename.stringByDeletingPathExtension];
    NSURL *extractURL = [self.tempDirectory URLByAppendingPathComponent:extractDirectory];
    
    
    NSError *error = nil;
    BOOL success = [archive extractFilesTo:extractURL.path
                                 overwrite:NO
                                  progress:^(UZKFileInfo *currentFile, CGFloat percentArchiveDecompressed) {
#if DEBUG
                                      NSLog(@"Extracting %@: %f%% complete", currentFile.filename, percentArchiveDecompressed);
#endif
                                  }
                                     error:&error];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL dirExists = [fm fileExistsAtPath:extractURL.path];
    
    XCTAssertFalse(success, @"Extract without password succeeded");
    XCTAssertEqual(error.code, UZKErrorCodeInvalidPassword, @"Unexpected error code returned");
    XCTAssertFalse(dirExists, @"Directory successfully created without password");
}

- (void)testExtractFiles_InvalidArchive
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:self.testFileURLs[@"Test File A.txt"] error:nil];
    
    NSString *extractDirectory = [self randomDirectoryWithPrefix:@"ExtractInvalidArchive"];
    NSURL *extractURL = [self.tempDirectory URLByAppendingPathComponent:extractDirectory];
    
    NSError *error = nil;
    BOOL success = [archive extractFilesTo:extractURL.path
                                 overwrite:NO
                                  progress:^(UZKFileInfo *currentFile, CGFloat percentArchiveDecompressed) {
#if DEBUG
                                      NSLog(@"Extracting %@: %f%% complete", currentFile.filename, percentArchiveDecompressed);
#endif
                                  }
                                     error:&error];
    BOOL dirExists = [fm fileExistsAtPath:extractURL.path];
    
    XCTAssertFalse(success, @"Extract invalid archive succeeded");
    XCTAssertEqual(error.code, UZKErrorCodeBadZipFile, @"Unexpected error code returned");
    XCTAssertFalse(dirExists, @"Directory successfully created for invalid archive");
}

- (void)testExtractFiles_Aces
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    UZKArchive *archive = [[UZKArchive alloc] initWithURL:self.testFileURLs[@"Aces.zip"] error:nil];
    
    NSString *extractDirectory = [self randomDirectoryWithPrefix:@"ExtractAcesArchive"];
    NSURL *extractURL = [self.tempDirectory URLByAppendingPathComponent:extractDirectory];
    
    NSError *error = nil;
    BOOL success = [archive extractFilesTo:extractURL.path
                                 overwrite:NO
                                  progress:^(UZKFileInfo *currentFile, CGFloat percentArchiveDecompressed) {
#if DEBUG
                                      NSLog(@"Extracting %@: %f%% complete", currentFile.filename, percentArchiveDecompressed);
#endif
                                  }
                                     error:&error];
    
    XCTAssertTrue(success, @"Extract Aces archive failed");
    
    NSDirectoryEnumerator *enumerator = [fm enumeratorAtURL:extractURL
                                 includingPropertiesForKeys:nil
                                                    options:(NSDirectoryEnumerationOptions)0
                                               errorHandler:^(NSURL *url, NSError *error) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu-zero-variadic-macro-arguments" // This appears to be an erroneous warning. rdar://22133126
                                                   // Handle the error.
                                                   // Return YES if the enumeration should continue after the error.
                                                   XCTFail(@"Error listing contents of directory %@: %@", url, error);
                                                   return NO;
#pragma clang diagnostic pop
                                               }];
    
    NSArray *expectedFiles = @[
                               @"aces-dev-1.0",
                               @"aces-dev-1.0/CHANGELOG.md",
                               @"aces-dev-1.0/documents",
                               @"aces-dev-1.0/documents/README.md",
                               @"aces-dev-1.0/images",
                               @"aces-dev-1.0/images/README.md",
                               @"aces-dev-1.0/LICENSE.md",
                               @"aces-dev-1.0/README.md",
                               ];
    
    NSUInteger i = 0;
    
    for (NSURL *extractedURL in enumerator) {
        NSString *actualPath = extractedURL.path;
        NSString *expectedPath = expectedFiles[i++];
        XCTAssertTrue([actualPath hasSuffix:expectedPath], @"Unexpected file extracted: %@", actualPath);
    }
}


@end
