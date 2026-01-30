@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption View for Equipment Card'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

define root view entity ZC_EQUIPMENTCARD
  provider contract transactional_query
  as projection on ZI_EQUIPMENTCARD
{

      /* ===================== */
      /* UI FACET (Header)     */
      /* ===================== */
      @UI.facet: [
        {
          id       : 'Header',
          purpose  : #STANDARD,
          type     : #IDENTIFICATION_REFERENCE,
          label    : 'Equipment Card',
          position : 10
        }
      ]

      /* ===================== */
      /* KEY FIELDS            */
      /* ===================== */



      @UI: { lineItem:[{ position: 20 }],
             identification:[{ position: 20 }],
             selectionField:[{ position: 20 }] } //2
  key kunnr,

      @UI: { lineItem:[{ position: 50 }],
             identification:[{ position: 50 }],
             selectionField:[{ position: 50 }] }
   key vin,

      /* ===================== */
      /* BUSINESS FIELDS       */
      /* ===================== */
      @UI: { lineItem:[{ position: 10 }],
           identification:[{ position: 10 }],
           selectionField:[{ position: 10 }] }     //1
      equipment,


      //
      //      @UI: { lineItem:[{ position: 40 }],
      //             identification:[{ position: 40 }] }
      //      matnr,

      @EndUserText.label: 'Material'
      @Search.defaultSearchElement: true
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_ProductStdVH', element: 'Product' } }]
        @UI: { lineItem:[{ position: 30 }],
           identification:[{ position: 30 }],
           selectionField:[{ position: 30 }] }    //3
      matnr,


      @UI: { lineItem:[{ position: 110 }],
             identification:[{ position: 110 }] }
      vehcile_no,

      @UI: { lineItem:[{ position: 60 }],
             identification:[{ position: 60 }] }
      tele_no,

      /* ===================== */
      /* CHECKBOX FIELD        */
      /* ===================== */

      @UI: { lineItem:[{ position: 130 , label : 'IS Sold' }],
             identification:[{ position: 130 , label : 'IS Sold'}]}
      //             selectionField:[{ position: 70 }] }
      sold_flg,

      @UI: { lineItem:[{ position: 120 }],
             identification:[{ position: 120 }],
             selectionField:[{ position: 120 }] }
      @Consumption.valueHelpDefinition: [{entity: {name: 'ZC_STATUS',element: 'Name'},  useForValidation: true}]
      @UI.textArrangement: #TEXT_ONLY
      status,
      
      
      @UI: { lineItem:[{ position: 70 , label : 'Color' }],
             identification:[{ position: 70 , label : 'Color' }],
             selectionField:[{ position: 70 }] }
      color,
      
      
      @UI: { lineItem:[{ position: 80 , label : 'Engine' }],
             identification:[{ position: 80 , label : 'Engine'}],
             selectionField:[{ position: 80 }] }
      engine,
      
      
      @UI: { lineItem:[{ position: 90 , label : 'Fuel_Type'}],
             identification:[{ position: 90 , label : 'Fuel_Type'}],
             selectionField:[{ position: 90 }] }
     fuel,
     
     @UI: { lineItem:[{ position: 100 , label : 'Transmission Type'}],
             identification:[{ position: 100 , label : 'Transmission Type' }],
             selectionField:[{ position: 100 }] }
     transmission,
     
     
     @UI: { lineItem:[{ position: 40 ,  label : 'Batch'}],
             identification:[{ position: 40 , label : 'Batch'}],
             selectionField:[{ position: 40 }] }
             batch,
     
      /* ===================== */
      /* AUDIT FIELDS          */
      /* ===================== */

      @UI.hidden: true
      @Consumption.hidden: true

      created_by,

      @UI.hidden: true
      @Consumption.hidden: true
      created_at,

      @UI.hidden: true
      @Consumption.hidden: true
      last_changed_by,

      @UI.hidden: true
      @Consumption.hidden: true
      last_changed_at

}
