#import <Cocoa/Cocoa.h>
#import <JavaScriptCore/JavaScriptCore.h>

@interface GRMMainViewController : NSViewController
@end

@interface GRMAppDelegate : NSObject <NSApplicationDelegate>
@property NSWindowController *windowController;
@end

@implementation GRMAppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  NSWindow *window = [NSWindow windowWithContentViewController:[[GRMMainViewController alloc] init]];
  self.windowController = [[NSWindowController alloc] initWithWindow:window];
  [self.windowController showWindow:self];
}
@end

@interface GRMMainViewController ()
@property JSContext *context;
@property NSMutableArray *timeoutArray;
@property NSStackView *stackView;
@end

@class GRMJSConstraint;
@class GRMJSConstraintItem;

@protocol GRMJSConstraintExports <JSExport>
@property id from;
@property id to;
@end

@interface GRMJSConstraint : NSObject <GRMJSConstraintExports>
@property NSLayoutRelation relation;
@property CGFloat multipler;
@property CGFloat constant;
@property GRMJSConstraintItem *from;
@property GRMJSConstraintItem *to;
@property(nullable, readonly) NSLayoutConstraint *constraint;
- (instancetype)initWithConstant:(CGFloat)constant multiplier:(CGFloat)multiplier relation:(NSLayoutRelation)relation;
@end

typedef NS_ENUM(NSInteger, GRMJSConstraintItemRelation) {
  GRMJSConstraintItemFrom = 1,
  GRMJSConstraintItemTo,
  GRMJSConstraintItemInvalid = 0
};

@interface GRMJSConstraintItem : NSObject
@property(weak) GRMJSConstraint *constraint;
@property(readonly) GRMJSConstraintItemRelation relation;
@property(weak) NSView *view;
@property NSLayoutAttribute attribute;
@end

@implementation GRMJSConstraint
@synthesize constraint = _constraint;

- (instancetype)initWithConstant:(CGFloat)constant multiplier:(CGFloat)multiplier relation:(NSLayoutRelation)relation {
  self = [super init];
  self.constant = constant;
  self.multipler = multiplier;
  self.relation = relation;
  self.from = [[GRMJSConstraintItem alloc] init];
  self.to = [[GRMJSConstraintItem alloc] init];
  self.from.constraint = self;
  self.to.constraint = self;
  return self;
}

- (NSLayoutConstraint *)constraint {
  if (self.from.view == nil || self.from.attribute == 0 || self.to.view == nil || self.to.attribute == 0) {
    _constraint = nil;
    return nil;
  }

  if (!_constraint) {
    _constraint = [NSLayoutConstraint constraintWithItem:self.from.view
                                               attribute:self.from.attribute
                                               relatedBy:self.relation
                                                  toItem:self.to.view
                                               attribute:self.to.attribute
                                              multiplier:self.multipler
                                                constant:self.constant];
  }

  return _constraint;
}
@end

@implementation GRMJSConstraintItem
- (GRMJSConstraintItemRelation)relation {
  if (self.constraint == nil) {
    return GRMJSConstraintItemInvalid;
  }

  if (self.constraint.from == self) {
    return GRMJSConstraintItemFrom;
  } else if (self.constraint.to == self) {
    return GRMJSConstraintItemTo;
  } else {
    return GRMJSConstraintItemInvalid;
  }
}
@end

NSDictionary<NSString *, NSNumber *> *constraintAttributeNames = @{
  @"top" : @(NSLayoutAttributeTop),
  @"bottom" : @(NSLayoutAttributeBottom),
  @"leading" : @(NSLayoutAttributeLeading),
  @"trailing" : @(NSLayoutAttributeTrailing),
  @"width" : @(NSLayoutAttributeWidth),
  @"height" : @(NSLayoutAttributeHeight),
  @"centerX" : @(NSLayoutAttributeCenterX),
  @"centerY" : @(NSLayoutAttributeCenterY)
};

@protocol GRMJSView
@property JSManagedValue *props;
@optional
- (void)addArrangedSubview:(NSView *)view;
@end

@interface GRMJSView : NSView <GRMJSView>
@property JSManagedValue *props;
- (instancetype)initFromProps:(JSValue *)props;
@end

@implementation GRMJSView
- (instancetype)initFromProps:(JSValue *)props {
  self = [super init];
  self.props = [JSManagedValue managedValueWithValue:props andOwner:self];
  for (NSString *attributeName in constraintAttributeNames) {
    for (GRMJSConstraintItem *constraintItem in [props[attributeName] toArray]) {
      constraintItem.view = self;
      constraintItem.attribute = [[constraintAttributeNames objectForKey:attributeName] intValue];
    }
  }
  self.wantsLayer = YES;
  NSLog(@"self.wantsLayer <- YES");
  NSLog(@"self.layer = %@", self.layer);
  self.layer.backgroundColor = [[NSColor colorWithRed:[props[@"color"][@"r"] toDouble]
                                                green:[props[@"color"][@"g"] toDouble]
                                                 blue:[props[@"color"][@"b"] toDouble]
                                                alpha:[props[@"color"][@"a"] toDouble]] CGColor];
  NSLog(@"self.layer.backgroundColor = %@", self.layer.backgroundColor);
  return self;
}

@end

@interface GRMJSStackVew : NSStackView <GRMJSView>
@property JSManagedValue *props;
- (instancetype)initFromProps:(JSValue *)props;
@end

@implementation GRMJSStackVew
- (instancetype)initFromProps:(JSValue *)props {
  self = [super init];
  self.props = [JSManagedValue managedValueWithValue:props andOwner:self];
  if ([[props[@"orientation"] toString] isEqualToString:@"vertical"]) {
    self.orientation = NSUserInterfaceLayoutOrientationVertical;
  }
  return self;
}
@end

@interface GRMJSButton : NSButton <GRMJSView>
@property JSManagedValue *props;
+ (instancetype)buttonFromProps:(JSValue *)props;
@end

@implementation GRMJSButton
+ (instancetype)buttonFromProps:(JSValue *)props {
  GRMJSButton *instance = [self buttonWithTitle:[props[@"title"] toString] target:nil action:nil];
  for (NSString *attributeName in constraintAttributeNames) {
    for (GRMJSConstraintItem *constraintItem in [props[attributeName] toArray]) {
      constraintItem.view = instance;
      constraintItem.attribute = [[constraintAttributeNames objectForKey:attributeName] intValue];
    }
  }
  instance.props = [JSManagedValue managedValueWithValue:props andOwner:instance];
  instance.target = instance;
  instance.action = @selector(invokePropsAction:);
  return instance;
}

- (void)invokePropsAction:(id)sender {
  NSLog(@"self.props.value=%@", self.props.value);
  [self.props.value[@"action"] callWithArguments:nil];
}
@end

@interface GRMJSTextField : NSTextField <GRMJSView>
@property JSManagedValue *props;
+ (instancetype)labelFromProps:(JSValue *)props;
@end

@implementation GRMJSTextField
+ (instancetype)labelFromProps:(JSValue *)props {
  GRMJSTextField *instance = [self labelWithString:[props[@"string"] toString]];
  instance.props = [JSManagedValue managedValueWithValue:props andOwner:instance];
  return instance;
}
@end

@interface NSView (GRMJSView)
- (NSCountedSet<GRMJSConstraint *> *)getAllConstraints;
- (NSSet<GRMJSConstraint *> *)getAllActiveConstraints;
@end

@implementation NSView (GRMJSView)
- (NSCountedSet<GRMJSConstraint *> *)getAllConstraints {
  NSCountedSet<GRMJSConstraint *> *set = [[NSCountedSet alloc] init];
  for (NSView *view in [self.subviews arrayByAddingObject:self]) {
    if ([view conformsToProtocol:@protocol(GRMJSView)]) {
      NSLog(@"Inspecting GRMJSView-conforming view %@", view);
      NSView<GRMJSView> *jsView = (NSView<GRMJSView> *)view;
      for (NSString *attributeName in constraintAttributeNames) {
        for (GRMJSConstraintItem *constraintItem in [jsView.props.value[attributeName] toArray]) {
          NSLog(@"%@ in view.props.value[%@]", constraintItem, attributeName);
          [set addObject:constraintItem.constraint];
        }
      }
    }
    if (view != self) {
      [set unionSet:[view getAllConstraints]];
    }
  }
  return set;
}
- (NSSet<GRMJSConstraint *> *)getAllActiveConstraints {
  NSCountedSet<GRMJSConstraint *> *countedSet = [self getAllConstraints];
  NSMutableSet<GRMJSConstraint *> *set = [[NSMutableSet alloc] init];
  for (GRMJSConstraint *constraint in countedSet) {
    if ([countedSet countForObject:constraint] > 1) {
      NSLog(@"Constraint %@ found to be active", constraint);
      [set addObject:constraint];
    }
  }
  return set;
}
@end

@implementation GRMMainViewController
- (NSString *)title {
  return @"Strange";
}

- (void)loadView {
  self.view = [[NSView alloc] init];
}

- (void)viewDidLoad {
  self.stackView = [NSStackView stackViewWithViews:@[]];
  self.stackView.orientation = NSUserInterfaceLayoutOrientationVertical;
  [self.view addSubview:self.stackView];
  [NSLayoutConstraint activateConstraints:@[
    [self.stackView.topAnchor constraintEqualToSystemSpacingBelowAnchor:self.view.topAnchor multiplier:1],
    [self.stackView.leftAnchor constraintEqualToSystemSpacingAfterAnchor:self.view.leftAnchor multiplier:1],
    [self.stackView.rightAnchor constraintEqualToSystemSpacingAfterAnchor:self.view.rightAnchor multiplier:-1],
    [self.stackView.bottomAnchor constraintEqualToSystemSpacingBelowAnchor:self.view.bottomAnchor multiplier:-1]
  ]];
  self.context = [[JSContext alloc] init];
  self.context.exceptionHandler = ^(JSContext *context, JSValue *exception) {
    NSLog(@"Exception from JS: %@", [exception toString]);
    NSLog(@"Stack trace: %@", [exception[@"stack"] toString]);
    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleCritical;
    alert.messageText = [NSString stringWithFormat:@"Exception from JS: %@", [exception toString]];
    alert.informativeText = [NSString stringWithFormat:@"Stack trace: %@", [exception[@"stack"] toString]];
    [alert runModal];
    [NSApp terminate:nil];
  };
  NSView<GRMJSView> * (^createViewBlock)(NSString *, JSValue *) = ^NSView<GRMJSView> *(NSString *type, JSValue *props) {
    if ([type isEqualToString:@"button"]) {
      GRMJSButton *button = [GRMJSButton buttonFromProps:props];
      NSLog(@"button=%@", button);
      button.translatesAutoresizingMaskIntoConstraints = false;
      return button;
    } else if ([type isEqualToString:@"label"]) {
      GRMJSTextField *label = [GRMJSTextField labelFromProps:props];
      NSLog(@"label=%@", label);
      label.translatesAutoresizingMaskIntoConstraints = false;
      return label;
    } else if ([type isEqualToString:@"stack"]) {
      GRMJSStackVew *stackView = [[GRMJSStackVew alloc] initFromProps:props];
      NSLog(@"stack=%@", stackView);
      stackView.translatesAutoresizingMaskIntoConstraints = false;
      return stackView;
    } else if ([type isEqualToString:@"view"]) {
      GRMJSView *view = [[GRMJSView alloc] initFromProps:props];
      NSLog(@"view=%@", view);
      view.translatesAutoresizingMaskIntoConstraints = false;
      return view;
    } else {
      NSLog(@"Unexpected node type %@", type);
      return nil;
    }
  };

  void (^addViewBlock)(NSView<GRMJSView> *, NSView<GRMJSView> *) =
      ^(NSView<GRMJSView> *parentView, NSView<GRMJSView> *view) {
        [self.context.virtualMachine addManagedReference:view withOwner:parentView];
        if ([parentView respondsToSelector:@selector(addArrangedSubview:)]) {
          NSLog(@"%@ responds to selector addManagedSubview:%@", parentView, view);
          [parentView addArrangedSubview:view];
        } else {
          NSLog(@"%@ doesn't respond to selector addManagedSubview:%@", parentView, view);
          [parentView addSubview:view];
        }
        for (GRMJSConstraint *constraint in [view getAllActiveConstraints]) {
          NSLog(@"Activating constraint wrapper %@", constraint);
          constraint.constraint.active = YES;
        }
      };

  void (^addViewToRootBlock)(NSView<GRMJSView> *) = ^(NSView<GRMJSView> *view) {
    [self.context.virtualMachine addManagedReference:view withOwner:self.stackView];
    [self.stackView addArrangedSubview:view];
  };

  void (^removeFromSuperviewBlock)(NSView<GRMJSView> *) = ^(NSView<GRMJSView> *view) {
    [self.context.virtualMachine removeManagedReference:view withOwner:view.superview];
    [view removeFromSuperview];
  };

  void (^updateViewBlock)(NSView<GRMJSView> *, NSString *, JSValue *, JSValue *) =
      ^(NSView<GRMJSView> *view, NSString *type, JSValue *prevProps, JSValue *nextProps) {
        if ([type isEqualToString:@"view"] && [view isKindOfClass:[GRMJSView class]]) {
          view.layer.backgroundColor = [[NSColor colorWithRed:[nextProps[@"color"][@"r"] toDouble]
                                                        green:[nextProps[@"color"][@"g"] toDouble]
                                                         blue:[nextProps[@"color"][@"b"] toDouble]
                                                        alpha:[nextProps[@"color"][@"a"] toDouble]] CGColor];

        } else {
          NSLog(@"Unexpected update of node type: expected view but got %@ (%@)", [view className], type);
        }
      };
  GRMJSConstraint * (^createEqualConstraintBlock)(CGFloat, CGFloat) = ^(CGFloat constant, CGFloat multiplier) {
    return [[GRMJSConstraint alloc] initWithConstant:constant multiplier:multiplier relation:NSLayoutRelationEqual];
  };
  GRMJSConstraint * (^createLessThanOrEqualConstraintBlock)(CGFloat, CGFloat) =
      ^(CGFloat constant, CGFloat multiplier) {
        return [[GRMJSConstraint alloc] initWithConstant:constant
                                              multiplier:multiplier
                                                relation:NSLayoutRelationLessThanOrEqual];
      };
  GRMJSConstraint * (^createGreaterThanOrEqualConstraintBlock)(CGFloat, CGFloat) =
      ^(CGFloat constant, CGFloat multiplier) {
        return [[GRMJSConstraint alloc] initWithConstant:constant
                                              multiplier:multiplier
                                                relation:NSLayoutRelationGreaterThanOrEqual];
      };
  self.context[@"_rootViewReference"] = self.stackView;
  self.context[@"createView"] = createViewBlock;
  self.context[@"addView"] = addViewBlock;
  self.context[@"addViewToRoot"] = addViewToRootBlock;
  self.context[@"updateView"] = updateViewBlock;
  self.context[@"removeFromSuperview"] = removeFromSuperviewBlock;
  self.context[@"createEqualConstraint"] = createEqualConstraintBlock;
  self.context[@"createLessThanOrEqualConstraint"] = createLessThanOrEqualConstraintBlock;
  self.context[@"createGreaterThanOrEqualConstraint"] = createGreaterThanOrEqualConstraintBlock;
  self.context[@"nslog"] = ^(JSValue *message) {
    NSLog(@"js: %@", [message toString]);
  };
  self.timeoutArray = [[NSMutableArray alloc] init];
  __typeof(self) __weak weakSelf = self;
  self.context[@"setTimeout"] = ^(JSValue *function, int delay) {
    if (weakSelf == nil) {
      return NSUIntegerMax;
    }
    NSUInteger timeoutIndex = [weakSelf.timeoutArray indexOfObject:NSNull.null];
    if (timeoutIndex == NSNotFound) {
      timeoutIndex = weakSelf.timeoutArray.count;
      [weakSelf.timeoutArray addObject:NSNull.null];
    }
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:(double)delay / 1000
                                                     repeats:NO
                                                       block:^(NSTimer *timer) {
                                                         [function callWithArguments:nil];
                                                         [weakSelf.timeoutArray replaceObjectAtIndex:timeoutIndex
                                                                                          withObject:NSNull.null];
                                                       }];
    [weakSelf.timeoutArray replaceObjectAtIndex:timeoutIndex withObject:timer];
    return timeoutIndex;
  };
  self.context[@"clearTimeout"] = ^(NSUInteger timeoutIndex) {
    if (weakSelf == nil) {
      return;
    }
    NSTimer *timer = [weakSelf.timeoutArray objectAtIndex:timeoutIndex];
    [timer invalidate];
    [weakSelf.timeoutArray replaceObjectAtIndex:timeoutIndex withObject:NSNull.null];
  };
  NSURL *scriptURL = [[NSBundle mainBundle] URLForResource:@"main.bundle" withExtension:@"js"];
  [self.context evaluateScript:[[NSString alloc] initWithContentsOfURL:scriptURL
                                                              encoding:NSUTF8StringEncoding
                                                                 error:nil]];
}
@end

int main(int argc, const char *argv[]) {
  GRMAppDelegate *delegate = [[GRMAppDelegate alloc] init];
  NSString *bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
  NSMenu *mainMenu = [[NSMenu alloc] init];
  NSApplication.sharedApplication.mainMenu = mainMenu;
  NSMenuItem *mainAppMenuItem = [mainMenu addItemWithTitle:@"Application" action:nil keyEquivalent:@""];
  NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"Application"];
  mainAppMenuItem.submenu = appMenu;
  NSMenuItem *mainFileMenuItem = [mainMenu addItemWithTitle:@"File" action:nil keyEquivalent:@""];
  NSMenu *fileMenu = [[NSMenu alloc] initWithTitle:@"File"];
  mainFileMenuItem.submenu = fileMenu;
  NSMenuItem *mainEditMenuItem = [mainMenu addItemWithTitle:@"Edit" action:nil keyEquivalent:@""];
  NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Edit"];
  mainEditMenuItem.submenu = editMenu;
  NSMenuItem *mainWindowMenuItem = [mainMenu addItemWithTitle:@"Window" action:nil keyEquivalent:@""];
  NSMenu *windowMenu = [[NSMenu alloc] initWithTitle:@"Window"];
  mainWindowMenuItem.submenu = windowMenu;
  NSApplication.sharedApplication.windowsMenu = windowMenu;
  NSMenuItem *mainHelpMenuItem = [mainMenu addItemWithTitle:@"Help" action:nil keyEquivalent:@""];
  NSMenu *helpMenu = [[NSMenu alloc] initWithTitle:@"Help"];
  mainHelpMenuItem.submenu = helpMenu;
  NSApplication.sharedApplication.helpMenu = helpMenu;
  [appMenu addItemWithTitle:[NSString stringWithFormat:@"About %@", bundleName]
                     action:@selector(orderFrontStandardAboutPanel:)
              keyEquivalent:@""];
  [appMenu addItem:NSMenuItem.separatorItem];
  [appMenu addItemWithTitle:@"Preferences…" action:nil keyEquivalent:@","];
  [appMenu addItem:NSMenuItem.separatorItem];
  [appMenu addItemWithTitle:[NSString stringWithFormat:@"Hide %@", bundleName]
                     action:@selector(hide:)
              keyEquivalent:@"h"];
  [appMenu addItemWithTitle:@"Hide Others" action:@selector(hideOtherApplications:) keyEquivalent:@"h"]
      .keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagOption;
  [appMenu addItemWithTitle:@"Show All" action:@selector(unhideAllApplications:) keyEquivalent:@""];
  [appMenu addItem:NSMenuItem.separatorItem];
  [appMenu addItemWithTitle:[NSString stringWithFormat:@"Quit %@", bundleName]
                     action:@selector(terminate:)
              keyEquivalent:@"q"];
  [editMenu addItemWithTitle:@"Undo" action:@selector(undo:) keyEquivalent:@"z"];
  [editMenu addItemWithTitle:@"Redo" action:@selector(redo:) keyEquivalent:@"Z"];
  [editMenu addItem:NSMenuItem.separatorItem];
  [editMenu addItemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"];
  [editMenu addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"];
  [editMenu addItemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v"];
  [editMenu addItemWithTitle:@"Paste and Match Style" action:@selector(pasteAsPlainText:) keyEquivalent:@"V"];
  [editMenu addItemWithTitle:@"Delete" action:@selector(delete:) keyEquivalent:@""];
  [editMenu addItemWithTitle:@"Select All" action:@selector(selectAll:) keyEquivalent:@""];
  // a whole lot more...
  [windowMenu addItemWithTitle:@"Minimize" action:@selector(performMiniaturize:) keyEquivalent:@"m"];
  [windowMenu addItemWithTitle:@"Zoom" action:@selector(performZoom:) keyEquivalent:@""];
  [windowMenu addItem:NSMenuItem.separatorItem];
  [windowMenu addItemWithTitle:@"Bring All to Front" action:@selector(arrangeInFront:) keyEquivalent:@""];
  [helpMenu addItemWithTitle:[NSString stringWithFormat:@"%@ Help", bundleName]
                      action:@selector(showHelp:)
               keyEquivalent:@"?"];
  NSApplication.sharedApplication.delegate = delegate;
  return NSApplicationMain(argc, argv);
}
