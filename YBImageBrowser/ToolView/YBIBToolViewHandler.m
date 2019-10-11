//
//  YBIBToolViewHandler.m
//  YBImageBrowserDemo
//
//  Created by 波儿菜 on 2019/7/7.
//  Copyright © 2019 杨波. All rights reserved.
//

#import "YBIBToolViewHandler.h"
#import "YBIBCopywriter.h"
#import "YBIBUtilities.h"

@interface YBIBToolViewHandler ()
@property (nonatomic, strong) YBIBSheetView *sheetView;
@property (nonatomic, strong) YBIBSheetAction *saveAction;
@property (nonatomic, strong) YBIBTopView *topView;
@property (nonatomic, strong) UIView *bottomView; //cpj
@end

@implementation YBIBToolViewHandler

#pragma mark - <YBIBToolViewHandler>

@synthesize yb_containerView = _yb_containerView;
@synthesize yb_containerSize = _yb_containerSize;
@synthesize yb_currentPage = _yb_currentPage;
@synthesize yb_totalPage = _yb_totalPage;
@synthesize yb_currentOrientation = _yb_currentOrientation;
@synthesize yb_currentData = _yb_currentData;

- (void)yb_containerViewIsReadied {
    [self.yb_containerView addSubview:self.topView];
    [self.yb_containerView addSubview:self.bottomView]; // cpj
    [self layoutWithExpectOrientation:self.yb_currentOrientation()];
    
    // cpj
    id<YBIBDataProtocol> data = self.yb_currentData();
    if([[data yb_projectiveView].superview.superview respondsToSelector:@selector(isBrowerShowBottomView)]) {
        BOOL isShowBottomView = [[data yb_projectiveView].superview.superview performSelector:@selector(isBrowerShowBottomView)];
        self.bottomView.hidden = !isShowBottomView;
    }else {
        self.bottomView.hidden = YES;
    }
}

- (void)yb_pageChanged {
    if (self.topView.operationType == YBIBTopViewOperationTypeSave) {
        self.topView.operationButton.hidden = [self currentDataShouldHideSaveButton];
    }
    [self.topView setPage:self.yb_currentPage() totalPage:self.yb_totalPage()];
}

- (void)yb_respondsToLongPress {
    [self showSheetView];
}

- (void)yb_hide:(BOOL)hide {
    self.topView.hidden = hide;
    [self.sheetView hideWithAnimation:NO];
}

- (void)yb_orientationWillChangeWithExpectOrientation:(UIDeviceOrientation)orientation {
    [self.sheetView hideWithAnimation:NO];
}

- (void)yb_orientationChangeAnimationWithExpectOrientation:(UIDeviceOrientation)orientation {
    [self layoutWithExpectOrientation:orientation];
}

#pragma mark - private

- (BOOL)currentDataShouldHideSaveButton {
    id<YBIBDataProtocol> data = self.yb_currentData();
    BOOL allow = [data respondsToSelector:@selector(yb_allowSaveToPhotoAlbum)] && [data yb_allowSaveToPhotoAlbum];
    BOOL can = [data respondsToSelector:@selector(yb_saveToPhotoAlbum)];
    return !(allow && can);
}

- (void)layoutWithExpectOrientation:(UIDeviceOrientation)orientation {
    CGSize containerSize = self.yb_containerSize(orientation);
    UIEdgeInsets padding = YBIBPaddingByBrowserOrientation(orientation);
    
    self.topView.frame = CGRectMake(padding.left, padding.top, containerSize.width - padding.left - padding.right, [YBIBTopView defaultHeight]);
    
    // cpj
    self.bottomView.frame = CGRectMake(padding.left, containerSize.height-padding.top-[YBIBTopView defaultHeight], containerSize.width - padding.left - padding.right, [YBIBTopView defaultHeight]);
    
    UIButton *shareBtn = [self.bottomView viewWithTag:1];
    UIButton *delBtn = [self.bottomView viewWithTag:2];
    shareBtn.frame = CGRectMake(0, 0, [YBIBTopView defaultHeight]*1.5, [YBIBTopView defaultHeight]);
    delBtn.frame = CGRectMake(containerSize.width - padding.left - padding.right-[YBIBTopView defaultHeight]*1.5, 0, [YBIBTopView defaultHeight]*1.5, [YBIBTopView defaultHeight]);
}

- (void)showSheetView {
    if ([self currentDataShouldHideSaveButton]) {
        [self.sheetView.actions removeObject:self.saveAction];
    } else {
        if (![self.sheetView.actions containsObject:self.saveAction]) {
            [self.sheetView.actions addObject:self.saveAction];
        }
    }
    [self.sheetView showToView:self.yb_containerView orientation:self.yb_currentOrientation()];
}

#pragma mark - getters

- (YBIBSheetView *)sheetView {
    if (!_sheetView) {
        _sheetView = [YBIBSheetView new];
        __weak typeof(self) wSelf = self;
        [_sheetView setCurrentdata:^id<YBIBDataProtocol>{
            __strong typeof(wSelf) self = wSelf;
            if (!self) return nil;
            return self.yb_currentData();
        }];
    }
    return _sheetView;
}

- (YBIBSheetAction *)saveAction {
    if (!_saveAction) {
        __weak typeof(self) wSelf = self;
        _saveAction = [YBIBSheetAction actionWithName:[YBIBCopywriter sharedCopywriter].saveToPhotoAlbum action:^(id<YBIBDataProtocol> data) {
            __strong typeof(wSelf) self = wSelf;
            if (!self) return;
            if ([data respondsToSelector:@selector(yb_saveToPhotoAlbum)]) {
                [data yb_saveToPhotoAlbum];
            }
            [self.sheetView hideWithAnimation:YES];
        }];
    }
    return _saveAction;
}

- (YBIBTopView *)topView {
    if (!_topView) {
        _topView = [YBIBTopView new];
        _topView.operationType = YBIBTopViewOperationTypeMore;
        __weak typeof(self) wSelf = self;
        [_topView setClickOperation:^(YBIBTopViewOperationType type) {
            __strong typeof(wSelf) self = wSelf;
            if (!self) return;
            switch (type) {
                case YBIBTopViewOperationTypeSave: {
                    id<YBIBDataProtocol> data = self.yb_currentData();
                    if ([data respondsToSelector:@selector(yb_saveToPhotoAlbum)]) {
                        [data yb_saveToPhotoAlbum];
                    }
                }
                    break;
                case YBIBTopViewOperationTypeMore: {
                    [self showSheetView];
                }
                    break;
                default:
                    break;
            }
        }];
    }
    return _topView;
}

#pragma mark - cpj
- (UIView *)bottomView{
    if (!_bottomView) {
        _bottomView = [UIView new];
        UIButton* shareBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        shareBtn.tag = 1;
        shareBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        [shareBtn setTitle:@"分享" forState:UIControlStateNormal];
        [shareBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [shareBtn addTarget:self action:@selector(clickShareBtn:) forControlEvents:UIControlEventTouchUpInside];
 
        UIButton* delBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        delBtn.tag = 2;
        delBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        [delBtn setTitle:@"删除" forState:UIControlStateNormal];
        [delBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [delBtn addTarget:self action:@selector(clickDelBtn:) forControlEvents:UIControlEventTouchUpInside];
        
        [_bottomView addSubview:shareBtn];
        [_bottomView addSubview:delBtn];
    }
    return _bottomView;
}

- (void)clickShareBtn:(UIButton*)btn {
    NSLog(@"clickShareBtn:");
    id<YBIBDataProtocol> data = self.yb_currentData();
    if([[data yb_projectiveView].superview.superview respondsToSelector:@selector(cell_shareImage:)]) {
        [[data yb_projectiveView].superview.superview performSelector:@selector(cell_shareImage:) withObject:btn];
    }else {
        NSLog(@"yb_projectiveView 未添加 yb_shareImage:");
    }
}

- (void)clickDelBtn:(UIButton*)btn {
    NSLog(@"clickDelBtn:");
    id<YBIBDataProtocol> data = self.yb_currentData();
    if([[data yb_projectiveView].superview.superview respondsToSelector:@selector(cell_delImage:)]) {
        [[data yb_projectiveView].superview.superview performSelector:@selector(cell_delImage:) withObject:btn];
    }else {
        NSLog(@"yb_projectiveView 未添加 yb_delImage:");
    }
}

@end
