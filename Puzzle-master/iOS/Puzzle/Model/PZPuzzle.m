//
//  PZPuzzle.m
//  Puzzle

////////////////////////////////////////////////////////////////////////////////
#import "PZPuzzle.h"
#import "PZTileImpl.h"
@import UIKit;

////////////////////////////////////////////////////////////////////////////////
@interface PZPuzzle()

@property (nonatomic, strong) NSMutableArray *mutableTiles;
@property (nonatomic, assign) PZTileLocation emptyTileLocation;
@property (nonatomic, assign) BOOL previousRandomMoveWasHorizontal;

@end

////////////////////////////////////////////////////////////////////////////////
@implementation PZPuzzle

static NSString *const kTilesState = @"PZTilesState";
static NSString *const kEmptyTileLocationState = @"PZEmptyTileLocationState";
static NSString *const kMovesCountState = @"PZMovesCountState";

#pragma mark -
#pragma mark Interface

- (instancetype)initWithImage:(UIImage *)anImage
                         size:(NSUInteger)aSize
                        state:(NSDictionary *)aState {
    if (nil != (self = [super init])) {
        _mutableTiles = [[self class] newTilesWithImage:anImage size:aSize];
        _emptyTileLocation = PZTileLocationMake(aSize - 1, aSize - 1);
        _size = aSize;
        _movesCount = 0;
        
        [self setStatePrivate:aState];
    }
    return self;
}

- (instancetype)init {
    [[NSException exceptionWithName:NSInternalInconsistencyException
                             reason:@"Use designated initializer"
                             userInfo:nil] raise];
    return nil;
}

- (BOOL)isWin {
    for (NSUInteger tileIndex = 0; tileIndex < self.mutableTiles.count; tileIndex++) {
        PZTileImpl *tile = self.mutableTiles[tileIndex];
        if (!PZTileLocationEqualToLocation([self locationForTileAtIndex:tileIndex],
                                           tile.winLocation)) {
            return NO;
        }
    }
    return YES;
}

- (id<IPZTile>)tileAtLocation:(PZTileLocation)aLocation {
    if (PZTileLocationEqualToLocation(self.emptyTileLocation, aLocation)) {
        return nil;
    }
    return self.mutableTiles[[self indexOfTileAtLocation:aLocation]];
}

- (NSArray *)tilesAtLocations:(NSArray *)aLocations {
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:aLocations.count];
    
    for (NSValue *location in aLocations) {
        id tile = [self tileAtLocation:[location tileLocation]];
        [result addObject:tile ? tile : [NSNull null]];    
    }
    
    return [[NSArray alloc] initWithArray:result];
}

- (NSArray *)allTiles {
    return [[NSArray alloc] initWithArray:self.mutableTiles];
}

- (PZMoveDirection)allowedMoveDirectionForTileAtLocation:(PZTileLocation)aLocation {
    if (PZTileLocationEqualToLocation(aLocation, self.emptyTileLocation)) {
        // no moves for empty location
        return kNoneDirection;
    }
    if (PZTileLocationInSameColumnAsLocation(aLocation, self.emptyTileLocation)) {
        // vertical move allowed
        return (aLocation.y < self.emptyTileLocation.y) ? kDownDirection : kUpDirection;
    }
    if (PZTileLocationInSameRowAsLocation(aLocation, self.emptyTileLocation)) {
        // horizontal move allowed
        return (aLocation.x < self.emptyTileLocation.x) ? kRightDirection : kLeftDirection;
    }
    return kNoneDirection;
}

- (NSArray *)affectedTilesByTileMoveAtLocation:(PZTileLocation)aLocation {
    return [self tilesAtLocations:[self affectedTilesLocationsByTileMoveAtLocation:aLocation]];
}

- (NSArray *)affectedTilesLocationsByTileMoveAtLocation:(PZTileLocation)aLocation {
    NSMutableArray *result = [NSMutableArray new];
    void(^addTileLocation)(NSUInteger, NSUInteger) = ^(NSUInteger x, NSUInteger y) {
        [result addObject:[[NSValue alloc] initWithTileLocation:PZTileLocationMake(x, y)]];    
    };
    
    switch ([self allowedMoveDirectionForTileAtLocation:aLocation]) {
        case kNoneDirection:
            break;
        case kLeftDirection:          
            for (NSUInteger x = aLocation.x; self.emptyTileLocation.x < x; x--) {
                addTileLocation(x, aLocation.y);
            }
            break;
        case kRightDirection:          
            for (NSUInteger x = aLocation.x; x < self.emptyTileLocation.x; x++) {
                addTileLocation(x, aLocation.y);
            }
            break;
        case kUpDirection:          
            for (NSUInteger y = aLocation.y; self.emptyTileLocation.y < y; y--) {
                addTileLocation(aLocation.x, y);
            }
            break;
        case kDownDirection:
            for (NSUInteger y = aLocation.y; y < self.emptyTileLocation.y; y++) {
                addTileLocation(aLocation.x, y);
            }
            break;
    }
    return [[NSArray alloc] initWithArray:result];
}

- (BOOL)moveTileAtLocation:(PZTileLocation)aLocation {
    __block PZTileLocation previousLocation = self.emptyTileLocation;
    NSArray *locations = [self affectedTilesLocationsByTileMoveAtLocation:aLocation];
    
    // move all affected tiles
    [locations enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id aTileLocation, NSUInteger anIndex, BOOL *aStopFlag) {
        PZTileLocation location = [aTileLocation tileLocation];
        [self exchangeTileAtLocation:previousLocation withTileAtLocation:location];
        previousLocation = location;
    }];
    
    BOOL result = (0 < locations.count);
    if (result) {
        ++self.movesCount;
        self.emptyTileLocation = aLocation;
    }
    return result;
}

- (void)moveTileToRandomLocationWithCompletionHandler:
    (void (^)(NSArray *tiles, PZMoveDirection direction))aHandler {
    // we have alternate horizontal and vertical moves to have good random moves
    PZTileLocation newLocation = self.previousRandomMoveWasHorizontal ?
        [self randomVerticalMovableTileLocation] :
        [self randomHorizontalMovableTileLocation];
    
    // remember tiles and direction to pass them to block
    NSArray *tiles = [self affectedTilesByTileMoveAtLocation:newLocation];
    PZMoveDirection direction = [self allowedMoveDirectionForTileAtLocation:newLocation];
    
    // do move
    [self moveTileAtLocation:newLocation];
    self.movesCount = 0;
    self.previousRandomMoveWasHorizontal = kLeftDirection == direction ||
                                           kRightDirection == direction;    
    // notify about move completion
    if (nil != aHandler) {
        aHandler(tiles, direction);
    }
}

#pragma mark -
#pragma mark Implementation

+ (NSMutableArray *)newTilesWithImage:(UIImage *)anImage
                                 size:(NSUInteger)aSize {
    CGFloat tileWidth = (anImage.size.width / aSize);
    CGFloat tileHeight = (anImage.size.height / aSize);

    NSUInteger tilesCount = aSize * aSize;
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:tilesCount];
    for (NSUInteger tileIndex = 0; tileIndex < tilesCount; tileIndex++) {
        PZTileLocation location = [self locationForTileAtIndex:tileIndex size:aSize];
        CGRect rectInMasterImage = CGRectMake(location.x * tileWidth,
                                              location.y * tileHeight,
                                              tileWidth, tileHeight);
        CGImageRef CGImage = CGImageCreateWithImageInRect([anImage CGImage],
                                                          rectInMasterImage);

        id tile = [[PZTileImpl alloc] initWithImage:[[UIImage alloc] initWithCGImage:CGImage]
                                    currentLocation:location winLocation:location];

        CGImageRelease(CGImage);
        [result addObject:tile];
    }

    return result;
}

- (void)exchangeTileAtLocation:(PZTileLocation)aLocation1
            withTileAtLocation:(PZTileLocation)aLocation2 {
    NSUInteger tile1Index = [self indexOfTileAtLocation:aLocation1];
    NSUInteger tile2Index = [self indexOfTileAtLocation:aLocation2];

    // exchange
    [self.mutableTiles exchangeObjectAtIndex:tile1Index withObjectAtIndex:tile2Index];
    
    // update locations
    [self.mutableTiles[tile1Index] setCurrentLocation:aLocation1];
    [self.mutableTiles[tile2Index] setCurrentLocation:aLocation2];
}

- (PZTileLocation)randomHorizontalMovableTileLocation {
    u_int32_t randomLocation = arc4random() % (self.size - 1);
    if (self.emptyTileLocation.x <= randomLocation) {
        // we must take into account empty tile and skip it
        ++randomLocation;
    }
    return PZTileLocationMake(randomLocation, self.emptyTileLocation.y);
}

- (PZTileLocation)randomVerticalMovableTileLocation {
    u_int32_t randomLocation = arc4random() % (self.size - 1);
    if (self.emptyTileLocation.y <= randomLocation) {
        // we must take into account empty tile and skip it
        ++randomLocation;
    }
    return PZTileLocationMake(self.emptyTileLocation.x, randomLocation);
}

- (PZTileLocation)locationForTileAtIndex:(NSUInteger)anIndex {
    return [[self class] locationForTileAtIndex:anIndex size:self.size];
}

+ (PZTileLocation)locationForTileAtIndex:(NSUInteger)anIndex
                                    size:(NSUInteger)aSize {
    NSUInteger y = anIndex / aSize;
    NSUInteger x = anIndex - y * aSize;
    
    return PZTileLocationMake(x, y);
}

- (NSUInteger)indexOfTileAtLocation:(PZTileLocation)aLocation {
    return aLocation.y * self.size + aLocation.x;
}

- (NSDictionary *)state
{
    NSMutableArray *tiles = [[NSMutableArray alloc] initWithCapacity:self.mutableTiles.count];
    for (PZTileImpl *tile in self.mutableTiles) {
        PZTileLocation location = tile.winLocation;        
        [tiles addObject:[[NSData alloc] initWithBytes:&location
                                                length:sizeof(location)]];
    }
    PZTileLocation emptyLocation = self.emptyTileLocation;
    return @{kTilesState: [NSArray arrayWithArray:tiles], 
             kEmptyTileLocationState: [[NSData alloc] initWithBytes:&emptyLocation
                                                             length:sizeof(emptyLocation)],
             kMovesCountState: @(self.movesCount)};
}

- (void)setStatePrivate:(NSDictionary *)aState
{
    if (nil == aState) {
        return;
    }
    
    NSArray *tiles = aState[kTilesState];
    NSMutableArray *newTiles = [[NSMutableArray alloc] initWithCapacity:tiles.count];
    [tiles enumerateObjectsUsingBlock:^(NSData *tileData, NSUInteger index, BOOL *stop) {
        PZTileLocation location;
        [tileData getBytes:&location length:sizeof(location)];
        PZTileImpl *tile = self.mutableTiles[[self indexOfTileAtLocation:location]];
        tile.currentLocation = [self locationForTileAtIndex:index];
        [newTiles addObject:tile];
    }];
    _mutableTiles = newTiles;
    
    PZTileLocation emptyLocation;
    [aState[kEmptyTileLocationState] getBytes:&emptyLocation
                                       length:sizeof(emptyLocation)];
    // This method is called from initializer, where using properties may be
    // error prone.
    _emptyTileLocation = emptyLocation;
    _movesCount = [aState[kMovesCountState] unsignedIntegerValue];
}

- (void)solveInstantly {
    
    for (PZTileImpl *tile in self.mutableTiles) {
        tile.currentLocation = tile.winLocation;
    }
    
    self.emptyTileLocation = PZTileLocationMake(self.size - 1, self.size - 1);
    self.movesCount = 0;
    
    [self.mutableTiles sortUsingComparator:^NSComparisonResult(id<IPZTile> obj1, id<IPZTile> obj2) {
        return [@([self indexOfTileAtLocation:obj1.currentLocation]) compare:@([self indexOfTileAtLocation:obj2.currentLocation])];
    }];
}

- (NSString *)description {
    NSMutableString *result = [NSMutableString new];
    
    [result appendString:@"\n"];

    
    [self.mutableTiles enumerateObjectsUsingBlock:^(PZTileImpl *tile, NSUInteger currentIndex, BOOL *stop) {
        NSUInteger winIndex = [self indexOfTileAtLocation:tile.winLocation];
        if (winIndex == self.size * self.size - 1) {
            // empty tile
            [result appendString:@"--"];
        }
        else {
            [result appendFormat:@"%02lu", (unsigned long)(winIndex + 1)];
        }
        [result appendString:(0 == ((currentIndex + 1) % self.size)) ? @"\n" : @" "];
    }];
    
    [result appendFormat:@"\nempty tile: %lu-%lu\n",
        (unsigned long)self.emptyTileLocation.x,
        (unsigned long)self.emptyTileLocation.y];

    return [NSString stringWithString:result];
}

@end
