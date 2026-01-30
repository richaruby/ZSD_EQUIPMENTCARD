    CLASS zcl_equipment_mstr_create DEFINITION
      PUBLIC
      FINAL
      CREATE PUBLIC .
      PUBLIC SECTION.
        INTERFACES : if_oo_adt_classrun ,
          if_apj_dt_exec_object,
          if_apj_rt_exec_object.
      PROTECTED SECTION.
      PRIVATE SECTION.
        METHODS: update_equipment.
    ENDCLASS.



    CLASS ZCL_EQUIPMENT_MSTR_CREATE IMPLEMENTATION.


      METHOD if_apj_dt_exec_object~get_parameters.


      ENDMETHOD.


      METHOD if_apj_rt_exec_object~execute.
*     " This is the method that will be called by the background job
        DATA: application_log           TYPE REF TO if_bali_log,
              application_log_free_text TYPE REF TO if_bali_free_text_setter.
        TRY.
            update_equipment( ).
            application_log = cl_bali_log=>create_with_header(
                                           header = cl_bali_header_setter=>create( object = 'XYZ' " Use your custom log object/subobject
                                                                                   subobject = 'INSERT' ) ).
            application_log_free_text = cl_bali_free_text_setter=>create(
                                            severity = if_bali_constants=>c_severity_information " Or c_severity_success
                                            text     = 'Sample data inserted successfully.' ).

            application_log->add_item( item = application_log_free_text ).
            cl_bali_log_db=>get_instance( )->save_log(
                log                        = application_log
                assign_to_current_appl_job = abap_true  ).

          CATCH cx_root INTO DATA(lx_error).

        ENDTRY.
      ENDMETHOD.


      METHOD  update_equipment.
        DATA : wa_equipment TYPE zdb_equipment_n,
               it_equipment TYPE TABLE OF zdb_equipment_n,
               vin_no       TYPE zdb_equipment_n-vin,
               batch        Type zdb_equipment_n-batch.

        DATA(lv_today) = cl_abap_context_info=>get_system_date( ).

        SELECT * FROM zdb_equipment_n
        INTO TABLE @DATA(it_equip_crd).

        SELECT a~billingdocument,
               a~creationdate,
               a~yy1_vin_bdh,
               a~yy1_vehicleno_bdh,
               b~billingdocumentitem,
               b~product,
               b~batch,
               b~salesdocument,
               c~customer,
               c~partnerfunction,
               d~AddressID,
               a~YY1_COLOR_BDH,
               a~YY1_ENGINE_NO1_BDH,
               a~YY1_FUEL_TYPE_BDH,
               a~YY1_TRANSMISSION_TYPE_BDH
               FROM i_billingdocument AS a
               JOIN i_billingdocumentitem AS b
               ON a~BillingDocument EQ b~BillingDocument
               JOIN i_salesdocumentpartner AS c
               ON c~SalesDocument EQ b~SalesDocument
               AND c~PartnerFunction EQ 'WE'
               JOIN i_customer AS d
               ON c~Customer EQ d~Customer
               WHERE a~creationdate EQ @lv_today
               INTO TABLE @DATA(it_billingdoc).

        IF it_billingdoc[] IS NOT INITIAL.
          SELECT  * FROM I_AddressPhoneNumber_2
          WITH PRIVILEGED ACCESS
          FOR ALL ENTRIES IN @it_billingdoc[]
          WHERE AddressID = @it_billingdoc-AddressID
          INTO TABLE @DATA(it_address).

          SELECT    materialdocumentyear,
                    companycode,
                    materialdocument,
                    materialdocumentitem,
                    batch,
                    yy1_vin_no_mmi
                    FROM i_materialdocumentitem_2
                    FOR ALL ENTRIES IN @it_billingdoc
                    WHERE batch = @it_billingdoc-batch
                    INTO TABLE @DATA(it_matdoc).
          DELETE it_matdoc WHERE   yy1_vin_no_mmi EQ '' .
          SORT it_billingdoc BY billingdocument billingdocumentitem .
*          SORT it_billingdoc BY yy1_vin_bdh customer .
          DELETE ADJACENT DUPLICATES FROM it_billingdoc COMPARING billingdocument billingdocumentitem .
          LOOP AT it_billingdoc ASSIGNING FIELD-SYMBOL(<fs_billingdoc>).
            READ TABLE it_address INTO DATA(wa_address) WITH KEY AddressID = <fs_billingdoc>-AddressID .
            READ TABLE it_matdoc INTO DATA(wa_matdoc) WITH KEY batch = <fs_billingdoc>-Batch .
            IF wa_matdoc-YY1_vin_no_MMI IS NOT INITIAL.
              vin_no = wa_matdoc-YY1_vin_no_MMI .
              batch = wa_matdoc-Batch.   """"
            ELSEIF <fs_billingdoc>-yy1_vin_bdh IS NOT INITIAL.
              vin_no = <fs_billingdoc>-yy1_vin_bdh  .
            ENDIF.

            CONDENSE vin_no .



            vin_no = |{  vin_no }|.
              wa_equipment-batch = <fs_billingdoc>-Batch.
               wa_equipment-color  = <fs_billingdoc>-YY1_COLOR_BDH.
                wa_equipment-engine = <fs_billingdoc>-YY1_Engine_No1_BDH.
                 wa_equipment-fuel   = <fs_billingdoc>-YY1_Fuel_Type_BDH.
                 wa_equipment-transmission = <fs_billingdoc>-YY1_Transmission_Type_BDH.

            READ TABLE it_equip_crd INTO DATA(wa_equip_crd) WITH KEY  vin = vin_no .
            IF sy-subrc IS INITIAL.
              READ TABLE it_equip_crd INTO DATA(wa_equip_crd2) WITH KEY vin = vin_no kunnr = wa_equip_crd-kunnr .
              IF sy-subrc IS NOT INITIAL.
                UPDATE zdb_equipment_n SET sold_flg = 'X'
*                  kunnr = @wa_equip_crd-kunnr
                WHERE    vin   = @vin_no.
                IF sy-subrc IS INITIAL.
                  COMMIT WORK.
                  SELECT SINGLE equipment FROM zdb_equipment_n WHERE
                  vin   = @vin_no
                  AND sold_flg = 'X'
                  INTO @DATA(lv_equip).
*                  SELECT COUNT(*) FROM zdb_equipment_n INTO @DATA(lv_count1).
*                  lv_count1 += 1.

                  wa_equipment-equipment = lv_equip .
                  wa_equipment-kunnr = <fs_billingdoc>-Customer.
                  wa_equipment-vin   = vin_no .
                  IF wa_address-PhoneAreaCodeSubscriberNumber IS NOT INITIAL.
                    wa_equipment-tele_no = wa_address-PhoneAreaCodeSubscriberNumber.
                  ELSEIF wa_address-InternationalPhoneNumber IS NOT INITIAL.
                    wa_equipment-tele_no = wa_address-InternationalPhoneNumber.
                  ENDIF.

                  wa_equipment-vehcile_no = <fs_billingdoc>-YY1_VehicleNo_BDH .
                  wa_equipment-matnr   = <fs_billingdoc>-Product .
                  wa_equipment-created_at = lv_today .
                  wa_equipment-created_by = sy-uname .
                  APPEND wa_equipment TO it_equipment .
                  MODIFY zdb_equipment_n FROM @wa_equipment .
                  IF sy-subrc IS INITIAL.
                    COMMIT WORK.
                  ENDIF.
                  CLEAR  : lv_equip .
                ENDIF.
              ENDIF.

            ELSE.
              IF vin_no IS NOT INITIAL.
                SELECT COUNT(*) FROM zdb_equipment_n INTO @DATA(lv_count).
                lv_count += 1.
                wa_equipment-equipment = lv_count .
                wa_equipment-kunnr = <fs_billingdoc>-Customer.
                wa_equipment-vin   = vin_no .
                IF wa_address-PhoneAreaCodeSubscriberNumber IS NOT INITIAL.
                  wa_equipment-tele_no = wa_address-PhoneAreaCodeSubscriberNumber.
                ELSEIF wa_address-InternationalPhoneNumber IS NOT INITIAL.
                  wa_equipment-tele_no = wa_address-InternationalPhoneNumber.
                ENDIF.
                wa_equipment-vehcile_no = <fs_billingdoc>-YY1_VehicleNo_BDH .
                wa_equipment-matnr   = <fs_billingdoc>-Product .
                wa_equipment-created_at = lv_today .
                wa_equipment-created_by = sy-uname .
                APPEND wa_equipment TO it_equipment .
                MODIFY zdb_equipment_n FROM @wa_equipment .
                CLEAR  : lv_count .
                IF sy-subrc IS INITIAL.
                  COMMIT WORK.

                ENDIF.
              ENDIF.
            ENDIF.
            CLEAR : wa_equipment, vin_no , wa_address.
          ENDLOOP.


        ENDIF.

      ENDMETHOD.


      METHOD if_oo_adt_classrun~main.
        DATA : wa_equipment TYPE zdb_equipment_n,
               it_equipment TYPE TABLE OF zdb_equipment_n,
               vin_no       TYPE zdb_equipment_n-vin.

        DATA(lv_today) = cl_abap_context_info=>get_system_date( ).

        SELECT * FROM zdb_equipment_n
        INTO TABLE @DATA(it_equip_crd).

        SELECT a~billingdocument,
               a~creationdate,
               a~yy1_vin_bdh,
               a~yy1_vehicleno_bdh,
               b~billingdocumentitem,
               b~product,
               b~batch,
               b~salesdocument,
               c~customer,
               c~partnerfunction,
               d~AddressID,
               a~YY1_COLOR_BDH,
               a~YY1_ENGINE_NO1_BDH,
               a~YY1_FUEL_TYPE_BDH,
               a~YY1_TRANSMISSION_TYPE_BDH
               FROM i_billingdocument AS a
               JOIN i_billingdocumentitem AS b
               ON a~BillingDocument EQ b~BillingDocument
               JOIN i_salesdocumentpartner AS c
               ON c~SalesDocument EQ b~SalesDocument
               AND c~PartnerFunction EQ 'WE'
               JOIN i_customer AS d
               ON c~Customer EQ d~Customer
               WHERE a~creationdate EQ @lv_today
               INTO TABLE @DATA(it_billingdoc).

        IF it_billingdoc[] IS NOT INITIAL.
          SELECT  * FROM I_AddressPhoneNumber_2
          WITH PRIVILEGED ACCESS
          FOR ALL ENTRIES IN @it_billingdoc[]
          WHERE AddressID = @it_billingdoc-AddressID
          INTO TABLE @DATA(it_address).

          SELECT    materialdocumentyear,
                    companycode,
                    materialdocument,
                    materialdocumentitem,
                    batch,
                    yy1_vin_no_mmi
                    FROM i_materialdocumentitem_2
                    FOR ALL ENTRIES IN @it_billingdoc
                    WHERE batch = @it_billingdoc-batch
                    INTO TABLE @DATA(it_matdoc).
          DELETE it_matdoc WHERE   yy1_vin_no_mmi EQ '' .
          SORT it_billingdoc BY billingdocument billingdocumentitem .
*          SORT it_billingdoc BY yy1_vin_bdh customer .
          DELETE ADJACENT DUPLICATES FROM it_billingdoc COMPARING billingdocument billingdocumentitem .
          LOOP AT it_billingdoc ASSIGNING FIELD-SYMBOL(<fs_billingdoc>).
            READ TABLE it_address INTO DATA(wa_address) WITH KEY AddressID = <fs_billingdoc>-AddressID .
            READ TABLE it_matdoc INTO DATA(wa_matdoc) WITH KEY batch = <fs_billingdoc>-Batch .
            IF wa_matdoc-YY1_vin_no_MMI IS NOT INITIAL.
              vin_no = wa_matdoc-YY1_vin_no_MMI .
            ELSEIF <fs_billingdoc>-yy1_vin_bdh IS NOT INITIAL.
              vin_no = <fs_billingdoc>-yy1_vin_bdh  .
            ENDIF.

            CONDENSE vin_no .
            vin_no = |{  vin_no }|.
              wa_equipment-batch = <fs_billingdoc>-Batch.
               wa_equipment-color  = <fs_billingdoc>-YY1_COLOR_BDH.
                wa_equipment-engine = <fs_billingdoc>-YY1_Engine_No1_BDH.
                 wa_equipment-fuel   = <fs_billingdoc>-YY1_Fuel_Type_BDH.
                 wa_equipment-transmission = <fs_billingdoc>-YY1_Transmission_Type_BDH.
            READ TABLE it_equip_crd INTO DATA(wa_equip_crd) WITH KEY  vin = vin_no .
            IF sy-subrc IS INITIAL.
              READ TABLE it_equip_crd INTO DATA(wa_equip_crd2) WITH KEY vin = vin_no kunnr = wa_equip_crd-kunnr .
              IF sy-subrc IS NOT INITIAL.
                UPDATE zdb_equipment_n SET sold_flg = 'X'
*                  kunnr = @wa_equip_crd-kunnr
                WHERE    vin   = @vin_no.
                IF sy-subrc IS INITIAL.
                  COMMIT WORK.
                  SELECT SINGLE equipment FROM zdb_equipment_n WHERE
                  vin   = @vin_no
                  AND sold_flg = 'X'
                  INTO @DATA(lv_equip).
*                  SELECT COUNT(*) FROM zdb_equipment_n INTO @DATA(lv_count1).
*                  lv_count1 += 1.

                  wa_equipment-equipment = lv_equip .
                  wa_equipment-kunnr = <fs_billingdoc>-Customer.
                  wa_equipment-vin   = vin_no .
                  IF wa_address-PhoneAreaCodeSubscriberNumber IS NOT INITIAL.
                    wa_equipment-tele_no = wa_address-PhoneAreaCodeSubscriberNumber.
                  ELSEIF wa_address-InternationalPhoneNumber IS NOT INITIAL.
                    wa_equipment-tele_no = wa_address-InternationalPhoneNumber.
                  ENDIF.

                  wa_equipment-vehcile_no = <fs_billingdoc>-YY1_VehicleNo_BDH .
                  wa_equipment-matnr   = <fs_billingdoc>-Product .
                  wa_equipment-created_at = lv_today .
                  wa_equipment-created_by = sy-uname .
                  APPEND wa_equipment TO it_equipment .
                  MODIFY zdb_equipment_n FROM @wa_equipment .
                  IF sy-subrc IS INITIAL.
                    COMMIT WORK.
                  ENDIF.
                  CLEAR  : lv_equip .
                ENDIF.
              ENDIF.

            ELSE.
              IF vin_no IS NOT INITIAL.
                SELECT COUNT(*) FROM zdb_equipment_n INTO @DATA(lv_count).
                lv_count += 1.
                wa_equipment-equipment = lv_count .
                wa_equipment-kunnr = <fs_billingdoc>-Customer.
                wa_equipment-vin   = vin_no .
                IF wa_address-PhoneAreaCodeSubscriberNumber IS NOT INITIAL.
                  wa_equipment-tele_no = wa_address-PhoneAreaCodeSubscriberNumber.
                ELSEIF wa_address-InternationalPhoneNumber IS NOT INITIAL.
                  wa_equipment-tele_no = wa_address-InternationalPhoneNumber.
                ENDIF.
                wa_equipment-vehcile_no = <fs_billingdoc>-YY1_VehicleNo_BDH .
                wa_equipment-matnr   = <fs_billingdoc>-Product .
                wa_equipment-created_at = lv_today .
                wa_equipment-created_by = sy-uname .
                APPEND wa_equipment TO it_equipment .
                MODIFY zdb_equipment_n FROM @wa_equipment .
                CLEAR  : lv_count .
                IF sy-subrc IS INITIAL.
                  COMMIT WORK.

                ENDIF.
              ENDIF.
            ENDIF.
            CLEAR : wa_equipment, vin_no , wa_address.
          ENDLOOP.


        ENDIF.

      ENDMETHOD.
    ENDCLASS.
