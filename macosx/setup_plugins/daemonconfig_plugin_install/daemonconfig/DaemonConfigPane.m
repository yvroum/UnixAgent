//
//  MyInstallerPane.m
//  daemonconfig
//
//  Created by OCSInventory on 02/02/2020.
//  Copyright © 2020 OCSInventory. All rights reserved.
//

#import "DaemonConfigPane.h"

@implementation DaemonConfigPane

- (NSString *)title
{
    return [[NSBundle bundleForClass:[self class]] localizedStringForKey:@"PaneTitle" value:nil table:nil];
}

- (void)didEnterPane:(InstallerSectionDirection)dir {
    NSString *tmpPath = @"/tmp/ocs_installer";
    
    filemgr = [ NSFileManager defaultManager];
    tmpLaunchdFilePath =@"/tmp/ocs_installer/org.ocsng.agent.plist";
    tmpNowFilePath = @"/tmp/ocs_installer/now";
    
    //Checking if temp directory exists
    if ([filemgr fileExistsAtPath:tmpPath]) {
        [filemgr removeItemAtPath:tmpLaunchdFilePath error:nil];
        [filemgr removeItemAtPath:tmpNowFilePath error:nil];
    } else {
        [filemgr createDirectoryAtPath:tmpPath withIntermediateDirectories:true attributes:nil error:nil];
    }
    
    
    // fill defaults values
    [periodicity setStringValue:@"5"];
    [startup setState:1];
    [now setState:1];
    
    
}


- (BOOL)shouldExitPane:(InstallerSectionDirection)Direction {
    
    
    NSMutableString *launchdCfgFile;
    NSAlert *periodicityValueWrn;
    
    //Creating org.ocsng.agent.plist file for launchd
    //TODO: use XML parser instead of writing the XML as a simple text file ?
    launchdCfgFile = [@"<?xml version='1.0' encoding='UTF-8'?>\n"
                      @"<!DOCTYPE plist PUBLIC '-//Apple//DTD PLIST 1.0//EN' 'http://www.apple.com/DTDs/PropertyList-1.0.dtd'>\n"
                      @"<plist version='1.0'>\n"
                      @"<dict>\n"
                      @"\t<key>Label</key>\n"
                      @"\t<string>org.ocsng.agent</string>\n"
                      @"\t<key>ProgramArguments</key>\n"
                      @"\t\t<array>\n"
                      @"\t\t\t<string>/Applications/OCSNG.app/Contents/MacOS/OCSNG</string>\n"
                      @"\t\t</array>\n"
                      mutableCopy];
    
    
    if ([startup state] == 1) {
        [launchdCfgFile  appendString:@"\t<key>RunAtLoad</key>\n"
                                      @"\t<true/>\n"
                                      ];
    }
    
    
    if ( [[periodicity stringValue] length] > 0) {
    
        //We convert string to numeric value and check if it is integer
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        NSNumber *convert = [formatter numberFromString:[periodicity stringValue]];
        
        if (convert) {
        
            int hours = [convert intValue];
            int seconds =  hours * 3600;
        
            [launchdCfgFile  appendString:@"\t<key>StartInterval</key>\n"
                                          @"\t<integer>"
                                          ];
         
            [launchdCfgFile  appendString:[NSString stringWithFormat:@"%d", seconds]];
            [launchdCfgFile  appendString:@"</integer>\n"];

        } else {
            //We display a warn message and we go back to pane
            periodicityValueWrn = [[NSAlert alloc] init];
        
            [periodicityValueWrn addButtonWithTitle:NSLocalizedString(@"OK", @"OK")];
            [periodicityValueWrn setMessageText:NSLocalizedStringFromTableInBundle(@"Periodicity_warn",nil,[NSBundle bundleForClass:[self class]], @"Peridocity warn")];
            [periodicityValueWrn setInformativeText:NSLocalizedStringFromTableInBundle(@"Periodicity_warn_comment",nil,[NSBundle bundleForClass:[self class]], @"Periodicity warn comment")];
            [periodicityValueWrn setAlertStyle:NSAlertStyleInformational];
            [periodicityValueWrn runModal];
            
            [self gotoPreviousPane];
        }
        
    }
    
    [launchdCfgFile  appendString:@"</dict>\n"
                                  @"</plist>"
                                  ];
    
    //Writing org.ocsng.agent.plist file
    [launchdCfgFile writeToFile:tmpLaunchdFilePath atomically: YES encoding:NSUTF8StringEncoding error:NULL];

    //Check if we launch agent after install
    if ([now state] == 1) {
        [filemgr createFileAtPath:tmpNowFilePath contents:nil attributes:nil];
    }
    
    
    return (YES);
}

@end
