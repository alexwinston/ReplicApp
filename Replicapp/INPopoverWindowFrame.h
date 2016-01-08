//
//  INPopoverWindowFrame.h
//  Copyright 2011 Indragie Karunaratne. All rights reserved.
//
//  Licensed under the BSD License <http://www.opensource.org/licenses/bsd-license>
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <Cocoa/Cocoa.h>
#import "INPopoverControllerDefines.h"

/**
 @class INPopoverWindowFrame
 The NSView subclass responsible for drawing the frame of the popover
 */
@interface INPopoverWindowFrame : NSView {
    NSColor *_color;
    NSColor *_borderColor;
    CGFloat _borderWidth;
    INPopoverArrowDirection _arrowDirection;
}
@property (nonatomic, retain) NSColor *color, *borderColor;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, assign) INPopoverArrowDirection arrowDirection;
@end