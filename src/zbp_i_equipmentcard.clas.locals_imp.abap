CLASS lhc_ZI_EQUIPMENTCARD DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zi_equipmentcard RESULT result.

    METHODS get_equipment FOR DETERMINE on save
      IMPORTING keys FOR zi_equipmentcard~get_equipment.

  METHODS validate_customer_vin FOR  vaLIDATE ON SAVE
  IMPORTING keys for zi_equipmentcard~validate_customer_vin.

 METHODS derive_telephone FOR DETERMINE ON SAVE
  IMPORTING keys FOR zi_equipmentcard~derive_telephone.


ENDCLASS.

CLASS lhc_ZI_EQUIPMENTCARD IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.





METHOD derive_telephone.

  READ ENTITIES OF zi_equipmentcard IN LOCAL MODE
    ENTITY eqp_dev
    FIELDS ( kunnr tele_no )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_equipment).

  IF lt_equipment IS INITIAL.
    RETURN.
  ENDIF.


  SELECT customer, TelephoneNumber1
    FROM i_customer
    WITH PRIVILEGED ACCESS
    FOR ALL ENTRIES IN @lt_equipment
    WHERE customer = @lt_equipment-kunnr
    INTO TABLE @DATA(lt_customer).

  DATA lt_update TYPE TABLE FOR UPDATE zi_equipmentcard.

  LOOP AT lt_equipment ASSIGNING FIELD-SYMBOL(<fs_eqp>).

    IF <fs_eqp>-tele_no IS NOT INITIAL.
      CONTINUE.
    ENDIF.

    READ TABLE lt_customer ASSIGNING FIELD-SYMBOL(<fs_cust>)
      WITH KEY customer = <fs_eqp>-kunnr.

    IF sy-subrc = 0
       AND <fs_cust>-TelephoneNumber1 IS NOT INITIAL.

      APPEND VALUE #(
        %tky                 = <fs_eqp>-%tky
        tele_no              = <fs_cust>-TelephoneNumber1
        %control-tele_no     = if_abap_behv=>mk-on
      ) TO lt_update.

    ENDIF.

  ENDLOOP.

  IF lt_update IS NOT INITIAL.
    MODIFY ENTITIES OF zi_equipmentcard IN LOCAL MODE
      ENTITY eqp_dev
      UPDATE FIELDS ( tele_no )
      WITH lt_update.
  ENDIF.

ENDMETHOD.

METHOD validate_customer_vin.

  READ ENTITIES OF zi_equipmentcard IN LOCAL MODE
    ENTITY eqp_dev
    FIELDS ( equipment vin sold_flg )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_data).

  IF lt_data IS INITIAL.
    RETURN.
  ENDIF.

DATA(ls_data) = lt_data[ 1 ].

  IF ls_data-kunnr IS INITIAL.

    APPEND VALUE #(
      %tky = ls_data-%tky
      %msg = new_message_with_text(
               severity = if_abap_behv_message=>severity-error
               text     = 'Customer is mandatory'
             )
    ) TO reported-eqp_dev.

    RETURN.
  ENDIF.



  DATA(lv_equipment) = lt_data[ 1 ]-equipment.
  DATA(lv_vin)       = lt_data[ 1 ]-vin.
  DATA(lv_curr_sold) = lt_data[ 1 ]-sold_flg.


    IF lv_vin IS INITIAL.
    RETURN.
  ENDIF.


  IF lv_curr_sold = 'X'.
    RETURN.
  ENDIF.


  SELECT equipment, sold_flg
    FROM zdb_equipment_n
    WHERE vin = @lv_vin
    INTO TABLE @DATA(lt_prev).


  LOOP AT lt_prev ASSIGNING FIELD-SYMBOL(<fs_prev>).

    IF <fs_prev>-equipment = lv_equipment.
      CONTINUE.
    ENDIF.

    IF <fs_prev>-sold_flg <> 'X'.

      APPEND VALUE #(
        %tky = lt_data[ 1 ]-%tky
        %msg = new_message_with_text(
                 severity = if_abap_behv_message=>severity-error
                 text     = 'VIN already exists and is not sold'
               )
      ) TO reported-eqp_dev.

      EXIT.
    ENDIF.

  ENDLOOP.

ENDMETHOD.

METHOD get_equipment.

  READ ENTITIES OF zi_equipmentcard IN LOCAL MODE
    ENTITY eqp_dev FIELDS ( equipment )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_onsave).

   SORT lt_onsave BY %tky.

  SELECT SINGLE MAX( equipment )
    FROM zdb_equipment_n
    INTO @DATA(lv_systemno).

  IF lv_systemno IS INITIAL.
    lv_systemno = 0.
  ENDIF.

  LOOP AT lt_onsave ASSIGNING FIELD-SYMBOL(<fs>).

    IF <fs>-equipment IS INITIAL.
      lv_systemno += 1.
      <fs>-equipment = lv_systemno.
    ENDIF.

  ENDLOOP.

  MODIFY ENTITIES OF zi_equipmentcard IN LOCAL MODE
    ENTITY eqp_dev
    UPDATE FIELDS ( equipment )
    WITH VALUE #(
      FOR ls IN lt_onsave (
        %tky      = ls-%tky
        equipment = ls-equipment
      )
    ).

  " ✅ Success message (shown once)
  IF lt_onsave IS NOT INITIAL.
    APPEND VALUE #(
      %tky = lt_onsave[ 1 ]-%tky
      %msg = new_message_with_text(
               severity = if_abap_behv_message=>severity-success
               text     = 'Equipment No. Created Successfully'
             )
    ) TO reported-eqp_dev.
  ENDIF.

ENDMETHOD.

ENDCLASS.
