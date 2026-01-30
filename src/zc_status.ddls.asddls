@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption for status'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.resultSet.sizeCategory: #XS
define root view entity ZC_STATUS as projection on ZI_STATUS
{
 @ObjectModel.text.element: ['Name']
 @UI.textArrangement: #TEXT_ONLY
    key Id,
 @Semantics.text: true
    Name
}
