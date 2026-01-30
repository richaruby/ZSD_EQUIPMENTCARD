@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Equipment card'
define root view entity ZI_EQUIPMENTCARD
  as select from zdb_equipment_n
{

  key kunnr,
   key vin,
      matnr,
      vehcile_no,
      tele_no,
      sold_flg,
      status,
      created_by,
      created_at,
      last_changed_by,
      last_changed_at,
       equipment,
       color ,         
  engine ,        
  fuel  ,          
  transmission ,   
  batch           


}
