//
//  HYPFormsCollectionViewDataSource.m

//
//  Created by Elvis Nunez on 10/6/14.
//  Copyright (c) 2014 Hyper. All rights reserved.
//

#import "HYPFormsCollectionViewDataSource.h"

#import "HYPFormBackgroundView.h"
#import "HYPFormsLayout.h"

#import "HYPTextFormFieldCell.h"
#import "HYPDropdownFormFieldCell.h"
#import "HYPDateFormFieldCell.h"
#import "HYPBlankFormFieldCell.h"

#import "UIColor+ANDYHex.h"
#import "UIScreen+HYPLiveBounds.h"
#import "NSString+ZENInflections.h"

@interface HYPFormsCollectionViewDataSource ()

@property (nonatomic, strong) NSMutableDictionary *resultsDictionary;
@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) NSMutableArray *deletedIndexPaths;

@end

@implementation HYPFormsCollectionViewDataSource

#pragma mark - Initializers

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView
{
    self = [self initWithCollectionView:collectionView andDictionary:nil];
    if (!self) return nil;

    return self;
}

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView andDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (!self) return nil;

    if (dictionary) {
        _resultsDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    }

    _collectionView = collectionView;
    collectionView.dataSource = self;

    [collectionView registerClass:[HYPBlankFormFieldCell class]
       forCellWithReuseIdentifier:HYPBlankFormFieldCellIdentifier];

    [collectionView registerClass:[HYPTextFormFieldCell class]
       forCellWithReuseIdentifier:HYPTextFormFieldCellIdentifier];

    [collectionView registerClass:[HYPDropdownFormFieldCell class]
       forCellWithReuseIdentifier:HYPDropdownFormFieldCellIdentifier];

    [collectionView registerClass:[HYPDateFormFieldCell class]
       forCellWithReuseIdentifier:HYPDateFormFieldCellIdentifier];

    [collectionView registerClass:[HYPFormHeaderView class]
       forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
              withReuseIdentifier:HYPFormHeaderReuseIdentifier];

    return self;
}

#pragma mark - Getters

- (NSMutableArray *)forms
{
    if (_forms) return _forms;

    if (self.resultsDictionary) {
        _forms = [HYPForm formsUsingInitialValuesFromDictionary:self.resultsDictionary];
    } else {
        _forms = [HYPForm forms];
    }

    return _forms;
}

- (NSMutableArray *)collapsedForms
{
    if (_collapsedForms) return _collapsedForms;

    _collapsedForms = [NSMutableArray array];

    return _collapsedForms;
}

- (NSMutableArray *)deletedFields
{
    if (_deletedFields) return _deletedFields;

    _deletedFields = [NSMutableArray array];

    return _deletedFields;
}

- (NSMutableArray *)deletedIndexPaths
{
    if (_deletedIndexPaths) return _deletedIndexPaths;

    _deletedIndexPaths = [NSMutableArray array];

    return _deletedIndexPaths;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.forms.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    HYPForm *form = self.forms[section];
    if ([self.collapsedForms containsObject:@(section)]) {
        return 0;
    }

    return [form numberOfFields];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    HYPForm *form = self.forms[indexPath.section];
    NSArray *fields = form.fields;
    HYPFormField *field = fields[indexPath.row];

    NSString *identifier;

    switch (field.type) {
        case HYPFormFieldTypeDate:
            identifier = HYPDateFormFieldCellIdentifier;
            break;
        case HYPFormFieldTypeSelect:
            identifier = HYPDropdownFormFieldCellIdentifier;
            break;

        case HYPFormFieldTypeDefault:
        case HYPFormFieldTypeFloat:
        case HYPFormFieldTypeNumber:
        case HYPFormFieldTypePicture:
            identifier = HYPTextFormFieldCellIdentifier;
            break;

        case HYPFormFieldTypeNone:
        case HYPFormFieldTypeBlank:
            identifier = HYPBlankFormFieldCellIdentifier;
            break;
    }

    id cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier
                                                        forIndexPath:indexPath];

    if (self.configureCellBlock) {
        self.configureCellBlock(cell, indexPath, field);
    }

    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if (kind == UICollectionElementKindSectionHeader) {
        HYPFormHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                                  withReuseIdentifier:HYPFormHeaderReuseIdentifier
                                                                                         forIndexPath:indexPath];

        HYPForm *form = self.forms[indexPath.section];
        headerView.section = indexPath.section;

        if (self.configureHeaderViewBlock) {
            self.configureHeaderViewBlock(headerView, kind, indexPath, form);
        }

        return headerView;
    }

    HYPFormBackgroundView *backgroundView = [collectionView dequeueReusableSupplementaryViewOfKind:HYPFormBackgroundKind
                                                                                   withReuseIdentifier:HYPFormBackgroundReuseIdentifier
                                                                                          forIndexPath:indexPath];

    return backgroundView;
}

#pragma mark - Public methods

- (void)collapseFieldsInSection:(NSInteger)section collectionView:(UICollectionView *)collectionView
{
    BOOL headerIsCollapsed = ([self.collapsedForms containsObject:@(section)]);

    NSMutableArray *indexPaths = [NSMutableArray array];
    HYPForm *form = self.forms[section];

    for (NSInteger i = 0; i < form.fields.count; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:section];
        [indexPaths addObject:indexPath];
    }

    if (headerIsCollapsed) {
        [self.collapsedForms removeObject:@(section)];
        [collectionView insertItemsAtIndexPaths:indexPaths];
        [collectionView.collectionViewLayout invalidateLayout];
    } else {
        [self.collapsedForms addObject:@(section)];
        [collectionView deleteItemsAtIndexPaths:indexPaths];
        [collectionView.collectionViewLayout invalidateLayout];
    }
}

- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    HYPForm *form = self.forms[indexPath.section];

    NSArray *fields = form.fields;

    CGRect bounds = [[UIScreen mainScreen] hyp_liveBounds];
    CGFloat deviceWidth = CGRectGetWidth(bounds) - (HYPFormMarginHorizontal * 2);
    CGFloat width = 0.0f;
    CGFloat height = 0.0f;

    HYPFormField *field = fields[indexPath.row];
    if (field.sectionSeparator) {
        width = deviceWidth;
        height = HYPFieldCellItemSmallHeight;
    } else {
        width = floor(deviceWidth * ([field.size floatValue] / 100.0f));
        height = HYPFieldCellItemHeight;
    }

    return CGSizeMake(width, height);
}

- (void)validateForms
{
    NSArray *cells = [self.collectionView visibleCells];
    for (HYPBaseFormFieldCell *cell in cells) {
        [cell validate];
    }
}

- (BOOL)formFieldsAreValid
{
    for (HYPForm *form in self.forms) {
        for (HYPFormField *field in form.fields) {
            if (![field isValid]) {
                return NO;
            }
        }
    }

    return YES;
}

- (void)resetForms
{
    self.forms = nil;
    [self.collectionView reloadData];
}

- (void)showFieldsWithIDs:(NSArray *)fieldIDs
{
    NSMutableArray *array = [self.deletedFields copy];

    [fieldIDs enumerateObjectsUsingBlock:^(NSString *fieldID, NSUInteger idx, BOOL *stop) {
        for (HYPFormField *field in array) {
            if ([fieldID isEqualToString:[field.id zen_rubyCase]]) {
                HYPForm *form = self.forms[[field.section.form.position integerValue]];
                HYPFormSection *section = form.sections[[field.section.position integerValue]];
                [section.fields insertObject:field atIndex:[field.position integerValue]];
                [self.deletedFields removeObject:field];
            }
        }
    }];

    [self.collectionView insertItemsAtIndexPaths:self.deletedIndexPaths];
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)deleteFieldsWithIDs:(NSArray *)fieldIDs
{
    [fieldIDs enumerateObjectsUsingBlock:^(NSString *fieldID, NSUInteger idx, BOOL *stop) {

        NSInteger section = 0;
        NSInteger row = 0;

        for (HYPForm *form in self.forms) {
            for (HYPFormField *field in form.fields) {
                if ([[field.id zen_rubyCase] isEqualToString:fieldID]) {
                    [self.deletedFields addObject:field];
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                    [self.deletedIndexPaths addObject:indexPath];
                }
                row++;
            }
            section++;
        }
    }];

    for (HYPFormField *field in self.deletedFields) {
        HYPForm *form = self.forms[[field.section.form.position integerValue]];
        HYPFormSection *section = form.sections[[field.section.position integerValue]];
        [section.fields removeObjectAtIndex:[field.position integerValue]];
    }

    [self.collectionView deleteItemsAtIndexPaths:self.deletedIndexPaths];
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)enableFieldsWithIDs:(NSArray *)fieldIDs
{
    // look for the fields
    // get their index paths
    // enable them
}

- (void)disableFieldsWithIDs:(NSArray *)fieldIDs
{
    // look for the fields
    // get their index paths
    // disable them
}

@end
