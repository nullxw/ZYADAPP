//
//  IAInfiniteGridView.m
//  Infinite
//
//  Created by Ikhsan Assaat on 10/1/12.
//  Copyright (c) 2012 3kunci. All rights reserved.
//

#import "IAInfiniteGridView.h"

@interface IAInfiniteGridView(){
    NSTimer *mytimer;
    NSTimer *temptimer;
}

//@property (nonatomic) NSInteger currentIndex;
@property (strong, nonatomic) NSMutableArray *visibleGrids;
@property (strong, nonatomic) NSMutableArray *gridReusableQueue;
@property (strong, nonatomic) UIView *containerView;
@property (strong, nonatomic) UIScrollView *curScrollView;

- (void)tileGridsFromMinX:(CGFloat)minimumVisibleX toMaxX:(CGFloat)maximumVisibleX;

@end

@implementation IAInfiniteGridView

- (void)initialization {
    self.visibleGrids = [[NSMutableArray alloc] init];
    self.gridReusableQueue = [[NSMutableArray alloc] init];
    self.containerView = [[UIView alloc] init];
    self.circular = NO;
    self.currentIndex = 0;
    self.delegate = self;
    [self addSubview:self.containerView];
    
    [self setShowsHorizontalScrollIndicator:NO];
    self.curScrollView = self;
    [self setAutoScroll];
}

- (void)setAutoScroll{
    mytimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(goNextPage) userInfo:nil repeats:YES];
}

- (void)stopAutoScroll{
    [mytimer setFireDate:[NSDate distantFuture]];
}

- (void)startAutoScroll{
    [temptimer invalidate];
    NSLog(@"%@",@"temptimer stopped!");
    [mytimer setFireDate:[NSDate distantPast]];
}

-(void)goNextPage{
    [self goToNextIndex];
    
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self initialization];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        [self initialization];
    }
    return self;
}

- (void)awakeFromNib {
    CGSize gridSize = [self.dataSource infiniteGridSize];
    NSUInteger totalGrids = [self.dataSource numberOfInfiniteGrids];
    self.contentSize = CGSizeMake(50 * totalGrids * gridSize.width, gridSize.height);
    
    self.containerView.frame = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height);
    
    [self.containerView setBackgroundColor:[UIColor blackColor]];
}

- (void)jumpToIndex:(NSInteger)gridIndex {
    if (self.isCircular && gridIndex < 0) return;
    [self setContentOffset:CGPointMake(0, self.contentOffset.y) animated:NO];
    
    CGRect visibleBounds = [self convertRect:self.bounds toView:self.containerView];
    CGFloat minimumVisibleX = CGRectGetMinX(visibleBounds);
    CGFloat maximumVisibleX = CGRectGetMaxX(visibleBounds);
    
    [self.visibleGrids removeAllObjects];
    self.currentIndex = gridIndex;
    
    [self tileGridsFromMinX:minimumVisibleX toMaxX:maximumVisibleX];
}

-(void)goToNextIndex{
    if (self.isPaging) {
        UIView *grid = [self gridViewAtPoint:self.curScrollView.contentOffset];
        //        CGPoint localPoint = [self.curScrollView convertPoint:self.curScrollView.contentOffset toView:grid];
        
        CGPoint destinationPoint;
        destinationPoint = [grid convertPoint:CGPointMake(grid.bounds.size.width, 0.0) toView:self.curScrollView];
        NSLog(@"%f",destinationPoint.x);
        if (destinationPoint.x < 60000.000000) {
            [UIView animateWithDuration:.5 delay:0.9 options:UIViewAnimationOptionCurveEaseOut animations:^{self.curScrollView.contentOffset = destinationPoint;} completion:nil];
        }else{
            [self.curScrollView setContentOffset:destinationPoint];
        }
    }
}

- (id)dequeueReusableGrid {
    id grid = [self.gridReusableQueue lastObject];
    [self.gridReusableQueue removeObject:grid];
    return grid;
}

#pragma mark - Layout

// recenter content periodically
- (void)recenterIfNecessary {
    CGPoint currentOffset = self.contentOffset;
    CGFloat contentWidth = self.contentSize.width;
    CGFloat centerOffsetX = (contentWidth - self.bounds.size.width) / 2.0;
    CGFloat distanceFromCenter = fabs(currentOffset.x - centerOffsetX);
    
    if (distanceFromCenter > (contentWidth / 4.0)) {
        self.contentOffset = CGPointMake(centerOffsetX, currentOffset.y);
        
        for (UIView *grid in self.visibleGrids) {
            CGPoint center = [self.containerView convertPoint:grid.center toView:self];
            center.x += (centerOffsetX - currentOffset.x);
            grid.center = [self convertPoint:center toView:self.containerView];
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self recenterIfNecessary];
    
    // tile content in visible bounds
    CGRect visibleBounds = [self convertRect:self.bounds toView:self.containerView];
    CGFloat minimumVisibleX = CGRectGetMinX(visibleBounds);
    CGFloat maximumVisibleX = CGRectGetMaxX(visibleBounds);
    
    [self tileGridsFromMinX:minimumVisibleX toMaxX:maximumVisibleX];
}

#pragma mark - Grid Tiling

- (UIView *)insertGridWithIndex:(NSInteger)index {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(infiniteGridView:forIndex:)]) {
        UIView *viewFromDelegate = [self.dataSource infiniteGridView:self forIndex:index];
        viewFromDelegate.tag = index;
        [self.containerView addSubview:viewFromDelegate];
        
        return viewFromDelegate;
    }
    
    return nil;
}

- (CGFloat)placeNewGridOnRight:(CGFloat)rightEdge {
    if ([self.visibleGrids count] > 0) {
        UIView *lastGrid = [self.visibleGrids lastObject];
        NSInteger nextIndex = lastGrid.tag + 1;
        if ([self isCircular])
            //nextIndex = (nextIndex >= [self.dataSource numberOfInfiniteGrids]) ? 0 : nextIndex;
        {
            NSInteger count = [self.dataSource numberOfInfiniteGrids];
            if (nextIndex >= count)
                nextIndex = 0;
            else
                nextIndex = nextIndex;
        }
        self.currentIndex = nextIndex;
    }
    
    UIView *grid = [self insertGridWithIndex:self.currentIndex];
    [self.visibleGrids addObject:grid];
    
    CGRect frame = grid.frame;
    frame.origin.x = rightEdge;
    frame.origin.y = self.containerView.bounds.size.height - frame.size.height;
    grid.frame = frame;
    
    return CGRectGetMaxX(frame);
}

- (CGFloat)placeNewLabelOnLeft:(CGFloat)leftEdge {
    UIView *firstGrid = [self.visibleGrids objectAtIndex:0];
    NSInteger previousIndex = firstGrid.tag - 1;
    if ([self isCircular])
        previousIndex = (previousIndex < 0) ? [self.dataSource numberOfInfiniteGrids]-1 : previousIndex;
    self.currentIndex = previousIndex;
    
    UIView *grid = [self insertGridWithIndex:self.currentIndex];
    [self.visibleGrids insertObject:grid atIndex:0];
    
    CGRect frame = grid.frame;
    frame.origin.x = leftEdge - frame.size.width;
    frame.origin.y = self.containerView.bounds.size.height - frame.size.height;
    grid.frame = frame;
    
    return CGRectGetMinX(frame);
}

- (void)tileGridsFromMinX:(CGFloat)minimumVisibleX toMaxX:(CGFloat)maximumVisibleX {
    if ([self.visibleGrids count] == 0) {
        [self placeNewGridOnRight:minimumVisibleX];
    }
    
    UIView *lastGrid = [self.visibleGrids lastObject];
    CGFloat rightEdge = CGRectGetMaxX(lastGrid.frame);
    while (rightEdge < maximumVisibleX) {
        rightEdge = [self placeNewGridOnRight:rightEdge];
    }
    
    UIView *firstGrid = [self.visibleGrids objectAtIndex:0];
    CGFloat leftEdge = CGRectGetMinX(firstGrid.frame);
    while (leftEdge > minimumVisibleX) {
        leftEdge = [self placeNewLabelOnLeft:leftEdge];
    }
    
    lastGrid = [self.visibleGrids lastObject];
    while (lastGrid.frame.origin.x > maximumVisibleX) {
        [lastGrid removeFromSuperview];
        [self.visibleGrids removeLastObject];
        [self.gridReusableQueue addObject:lastGrid];
        
        lastGrid = [self.visibleGrids lastObject];
    }
    
    firstGrid = [self.visibleGrids objectAtIndex:0];
    while (CGRectGetMaxX(firstGrid.frame) < minimumVisibleX) {
        [firstGrid removeFromSuperview];
        [self.visibleGrids removeObjectAtIndex:0];
        [self.gridReusableQueue addObject:firstGrid];
        
        firstGrid = [self.visibleGrids objectAtIndex:0];
    }
}

- (UIView *)gridViewAtPoint:(CGPoint)point {
    __block UIView *gridView = nil;
    [self.visibleGrids enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIView *visibleGridView = (UIView *)obj;
        
        if (CGRectContainsPoint(visibleGridView.frame, point)) {
            gridView = visibleGridView;
            *stop = YES;
        }
    }];
    
    return gridView;
}

#pragma mark - Scroll View Delegate Methods

// custom paging
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    self.curScrollView = scrollView;
    if (self.isPaging) {
        CGPoint velocity = [scrollView.panGestureRecognizer velocityInView:[self superview]];
        
        UIView *grid = [self gridViewAtPoint:scrollView.contentOffset];
        
        CGPoint destinationPoint;
        if (velocity.x > 0) {
            destinationPoint = [grid convertPoint:CGPointMake(0, 0.0) toView:scrollView];
        } else {
            destinationPoint = [grid convertPoint:CGPointMake(grid.bounds.size.width, 0.0) toView:scrollView];
        }
        
        [scrollView setContentOffset:destinationPoint animated:YES];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    [self stopAutoScroll];
    [temptimer invalidate];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView{
    temptimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(startAutoScroll) userInfo:nil repeats:NO];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (self.isPaging) {
        if (!decelerate) {
            UIView *grid = [self gridViewAtPoint:scrollView.contentOffset];
            CGPoint localPoint = [scrollView convertPoint:scrollView.contentOffset toView:grid];
            
            CGPoint destinationPoint;
            if (localPoint.x > (grid.bounds.size.width / 2)) {
                destinationPoint = [grid convertPoint:CGPointMake(grid.bounds.size.width, 0.0) toView:scrollView];
            } else {
                destinationPoint = [grid convertPoint:CGPointMake(0.0, 0.0) toView:scrollView];
            }
            [UIView animateWithDuration:.15 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{scrollView.contentOffset = destinationPoint;} completion:nil];
        }
    }
}

@end
