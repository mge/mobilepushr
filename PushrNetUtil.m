/*
 * PushrNetUtil.m
 * --------------
 *
 * Author: Chris Lee <clee@mg8.org>
 * License: GPL v2 <http://www.opensource.org/licenses/gpl-license.php>
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PushrNetUtil.h"

#include <sys/types.h>
#include <sys/socket.h>
#include <ifaddrs.h>

@implementation PushrNetUtil

- (id)initWithPushr: (MobilePushr *)pushr
{
    if (![super init]) {
        return nil;
    }
    
    _pushr = [pushr retain];
    _activeInterfaceNames = [[NSMutableArray alloc] initWithCapacity: 0];
    
    struct ifaddrs *first_ifaddr, *current_ifaddr;
    getifaddrs(&first_ifaddr);
    current_ifaddr = first_ifaddr;
    while (current_ifaddr != NULL) {
        if (current_ifaddr->ifa_addr->sa_family == 0x02)
            [_activeInterfaceNames addObject: [NSString stringWithFormat: @"%s", current_ifaddr->ifa_name]];
        current_ifaddr = current_ifaddr->ifa_next;
    }
    freeifaddrs(first_ifaddr);
    
    return self;	
}

- (void)dealloc
{
    [_activeInterfaceNames release];
    [_pushr release];
    [super dealloc];
}

- (void)warnUserAboutSlowEDGE
{
    UIAlertView *alertView = [[[UIAlertView alloc] init] autorelease];
    [alertView setTitle: @"This might take a while"];
    [alertView setMessage: @"You don't seem to have an active WiFi connection, and pushing photos over EDGE is really slow. Still want to push over EDGE?"];
    [alertView setCancelButtonIndex: [alertView addButtonWithTitle: @"Try again later"]];
    [alertView addButtonWithTitle: @"Push over EDGE"];
    [alertView setDelegate: self];
    [alertView show];
}

- (void)drownWithoutNetwork
{
    UIAlertView *alertView = [[[UIAlertView alloc] init] autorelease];
    [alertView setTitle: @"No network available"];
    [alertView setMessage: @"Pushr doesn't work if it can't talk to Flickr, and right now, no network connections are active."];
    [alertView setCancelButtonIndex: [alertView addButtonWithTitle: @"Try again later"]];
    [alertView setDelegate: _pushr];
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 1: {
            NSLog(@"Told the user EDGE was slow, but they want to push anyway...");
            break;
        }
        default: {
            [_pushr terminate];
            break;
        }
    }
}

- (NSArray *)activeInterfaceNames
{
    return [NSArray arrayWithArray: _activeInterfaceNames];
}

- (BOOL)hasWiFi
{
    NSArray *activeInterfaces = [self activeInterfaceNames];
    return [activeInterfaces containsObject: @"en0"] || [activeInterfaces containsObject: @"en1"];
}

- (BOOL)hasEDGE
{
    NSArray *activeInterfaces = [self activeInterfaceNames];
    return [activeInterfaces containsObject: @"ip0"] || [activeInterfaces containsObject: @"ip1"];
}

@end