//
//  RCImageView.h
//  Replicapp
//
//  Created by Alex Winston on 8/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RCImageView : NSImageView {
    IBOutlet NSWindow *replicappWindow;
    NSPoint mouseDownPoint;
}

@end
