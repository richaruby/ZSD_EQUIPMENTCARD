@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface for status'
@Metadata.ignorePropagatedAnnotations: true

define root view entity ZI_STATUS as select from zdb_status
{
    key id as Id,
    name as Name
}
