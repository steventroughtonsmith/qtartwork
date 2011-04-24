//
//  main.m
//  qtartwork
//
//  Created by Steven Troughton-Smith on 24/04/2011.
//  Copyright 2011 High Caffeine Content. All rights reserved.
//
//  Apple sample code cribbed from http://developer.apple.com/library/mac/#qa/qa1515/_index.html

#import <Foundation/Foundation.h>
#import <QuickTime/QuickTime.h>
#import <QTKit/QTKit.h>


int main (int argc, const char * argv[])
{
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    NSString *movieFile = nil;
    NSString *artFile = nil;    
    NSString *outputFile = nil;
    
    BOOL editInPlace = NO;
    
    if (argc != 3 && argc !=4)
    {
        printf("\nUsage: qtartwork movie.mp4 artwork.[jpg|png] output.mov\n       qtartwork movie.mov artwork.[jpg|png]\n\n");
        return 1;
    }
    
    if (argc == 3)
    {
        movieFile = [NSString stringWithUTF8String:argv[1]];
        artFile = [NSString stringWithUTF8String:argv[2]];
        
        editInPlace = YES;
    }
    else if (argc == 4)
    {
        movieFile = [NSString stringWithUTF8String:argv[1]];
        artFile = [NSString stringWithUTF8String:argv[2]];
        outputFile = [NSString stringWithUTF8String:argv[3]];
    }
    
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:
                                 movieFile forKey:QTMovieFileNameAttribute];
    
    [dict setObject:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
    
    
    QTMovie *aQTMovie = [[QTMovie alloc] initWithAttributes:dict error:nil];
    
    NSString *filePath = artFile;
    
    QTMetaDataRef   metaDataRef;
    Movie           theMovie;
    OSStatus        status;
    
    theMovie = [aQTMovie quickTimeMovie];
    status = QTCopyMovieMetaData (theMovie, &metaDataRef );
    assert(status == noErr);
    
    if (status == noErr)
    {
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        NSData *artworkData = [fileMgr contentsAtPath:filePath];
        assert(artworkData != NULL);
        
        if (artworkData)
        {
            OSType key = kQTMetaDataCommonKeyArtwork;
            QTMetaDataItem outItem;
            
            int datatype = kQTMetaDataTypeJPEGImage;
            
            if ([[[artFile pathExtension] lowercaseString] isEqualToString:@"png"])
                datatype = kQTMetaDataTypePNGImage;
            else  if ([[[artFile pathExtension] lowercaseString] isEqualToString:@"jpg"])
                datatype = kQTMetaDataTypeJPEGImage;
            
            status = QTMetaDataAddItem(metaDataRef,
                                       kQTMetaDataStorageFormatQuickTime,
                                       kQTMetaDataKeyFormatCommon,
                                       (const UInt8 *)&key,
                                       sizeof(key),
                                       (const UInt8 *)[artworkData bytes],
                                       [artworkData length],
                                       datatype, // image data
                                       &outItem);
            
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            
            NSArray *languages = [defaults objectForKey:@"AppleLanguages"];
            
            NSString *langStr = [languages objectAtIndex:0];
            
            const char *langCodeStr = ([langStr cStringUsingEncoding:NSMacOSRomanStringEncoding]);
            status = QTMetaDataSetItemProperty(
                                               metaDataRef,
                                               outItem,
                                               kPropertyClass_MetaDataItem,
                                               kQTMetaDataItemPropertyID_Locale,
                                               strlen(langCodeStr) + 1,
                                               langCodeStr);
            
            if (status == noErr)
            {
                // we must update the movie file to save the
                // metadata items that were added
                
                if (editInPlace)
                {
                    
                    BOOL success = [aQTMovie canUpdateMovieFile];
                    
                    success = [aQTMovie updateMovieFile];
                    
                    
                    if (!success)
                        printf("Unable to edit in-place. Try passing in an output file path instead.");
                    
                }
                else
                {
                    
                    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
                    [attributes setObject:[NSNumber numberWithBool:YES] forKey:QTMovieFlatten];
                    
                    NSError *error;
                    BOOL success = [aQTMovie writeToFile:outputFile withAttributes:attributes error:&error];
                    
                    if (!success)
                        printf("Unable to write to output file.\n");
                    
                    if (error)
                        NSLog(@"%@", [error description]);
                }
            }
            
        }
        
        QTMetaDataRelease(metaDataRef);
    } 
    
    [pool drain];
    return 0;
}
