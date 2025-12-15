CLASS zcl_copy_objects_helper DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-METHODS: create_copy_of_class
      IMPORTING
        !data             TYPE if_adt_oo_types=>ty_abap_class
        !transport        TYPE trkorr
      RETURNING
        VALUE(successful) TYPE abap_bool,
      create_copy_of_program
        IMPORTING
          !data             TYPE cl_sedi_adt_res_source=>ty_prog_data
          !transport        TYPE trkorr
        RETURNING
          VALUE(successful) TYPE abap_bool,
      create_copy_of_table
        IMPORTING
                  !data             TYPE cl_blue_source_object_data=>ty_object_data-metadata
                  !transport        TYPE trkorr
        RETURNING VALUE(successful) TYPE abap_bool.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_copy_objects_helper IMPLEMENTATION.


  METHOD create_copy_of_class.
    DATA l_orig_clskey TYPE seoclskey.
    DATA l_new_clskey TYPE seoclskey.
    DATA l_trkorr TYPE trkorr.
    DATA l_new_devclass TYPE devclass.
    DATA resource_id TYPE string.
    DATA obj_oo_utility TYPE REF TO cl_oo_clif_utility.
    DATA l_uccheck TYPE uccheck.
    DATA obj_lang_vers            TYPE REF TO if_abap_language_version.
    DATA obj_exception            TYPE REF TO cx_abap_language_version.
    DATA is_lang_vers_allowed     TYPE abap_bool VALUE abap_false.

    resource_id = data-name.

*   fill needed variables for next steps
    l_orig_clskey-clsname = data-template-name.
    l_new_clskey-clsname = data-name.
    l_trkorr = transport.
    l_new_devclass = data-package_ref-name.
*    if me->cts_management->is_transport_disabled_for_pack( package = data-package_ref-name && '' ) = abap_true.
*      clear l_trkorr.
*    endif.

    DATA(mainprog_name) = cl_oo_classname_service=>get_classpool_name( clsname = to_upper( l_orig_clskey-clsname ) ).
    SELECT SINGLE uccheck FROM progdir INTO l_uccheck WHERE name = mainprog_name AND state = 'A'.

    TRY.
        obj_lang_vers  = cl_abap_language_version=>get_instance( ).

        obj_lang_vers->is_version_allowed(
          EXPORTING
            iv_object_type = seok_r3tr_class
            iv_package     = l_new_devclass
            iv_version     = l_uccheck
          RECEIVING
            rv_is_allowed  = is_lang_vers_allowed ).

        IF is_lang_vers_allowed = abap_false.  " not allowed, get the default for copy
          l_uccheck = obj_lang_vers->get_default_version(
            iv_object_type = seok_r3tr_class
            iv_package     = l_new_devclass ).
        ENDIF.

      CATCH cx_wb_obj_object_not_existent.
        RAISE EXCEPTION TYPE cx_adt_res_not_found
          EXPORTING
            resource_type = cl_oo_adt_res_class=>resource_type
            resource_id   = l_orig_clskey-clsname && ''.
      CATCH cx_abap_language_version INTO obj_exception.
        RAISE EXCEPTION TYPE cx_adt_res_creation_failure
          EXPORTING
            textid        = cx_adt_rest=>create_textid_from_msg_params( )
            previous      = obj_exception
            resource_type = cl_oo_adt_res_class=>resource_type
            resource_id   = resource_id.
    ENDTRY.

    CREATE OBJECT obj_oo_utility.

    TRY.
        DATA lifecycle_manager TYPE REF TO cl_adt_corr_insert_dark.
        CREATE OBJECT lifecycle_manager.
        lifecycle_manager->if_adt_lifecycle_manager~corrnr = l_trkorr.
        lifecycle_manager->if_adt_lifecycle_manager~devclass = l_new_devclass.

        CALL METHOD obj_oo_utility->copy_class
          EXPORTING
            original_class        = l_orig_clskey
            new_class             = l_new_clskey
            corrnr                = l_trkorr
            devclass              = l_new_devclass
            lifecycle_manager     = lifecycle_manager
            uccheck_for_duplicate = l_uccheck.

      CATCH cx_oo_clif_not_exists .
        RETURN.
*        RAISE EXCEPTION TYPE cx_adt_res_not_found
*          EXPORTING
*            resource_type = cl_oo_adt_res_class=>resource_type
*            resource_id   = l_orig_clskey-clsname && ''.
      CATCH cx_oo_clif_already_exists .
        RETURN.
*        RAISE EXCEPTION TYPE cx_adt_res_already_exists
*          EXPORTING
*            resource_type = cl_oo_adt_res_class=>resource_type
*            resource_id   = resource_id.
      CATCH cx_oo_clif_creation_failure .
        RETURN.
*        RAISE EXCEPTION TYPE cx_adt_res_creation_failure
*          EXPORTING
*            textid        = cx_adt_rest=>create_textid_from_msg_params( )
*            resource_type = cl_oo_adt_res_class=>resource_type
*            resource_id   = resource_id.
      CATCH cx_oo_source_save_failure .
        RETURN.
*        RAISE EXCEPTION TYPE cx_adt_res_save_failure
*          EXPORTING
*            textid        = cx_adt_rest=>create_textid_from_msg_params( )
*            resource_type = cl_oo_adt_res_class=>resource_type
*            resource_id   = resource_id.
      CATCH cx_oo_access_permission .
        RETURN.
*        IF sy-msgid IS NOT INITIAL AND sy-msgno IS NOT INITIAL.
*          RAISE EXCEPTION TYPE cx_adt_res_no_access
*            EXPORTING
*              textid        = cx_adt_rest=>create_textid_from_msg_params( )
*              resource_type = cl_oo_adt_res_class=>resource_type
*              resource_id   = resource_id.
*        ELSE.
*          RAISE EXCEPTION TYPE cx_adt_res_no_access
*            EXPORTING
*              resource_type = cl_oo_adt_res_class=>resource_type
*              resource_id   = resource_id.
*        ENDIF.
    ENDTRY.

    COMMIT WORK.
  ENDMETHOD.


  METHOD create_copy_of_program.
    DATA:
      l_orig_reps   TYPE progname,
      l_new_reps    TYPE progname,
      l_resource_id TYPE string,
      l_lock_handle TYPE REF TO if_adt_lock_handle,
      l_props       TYPE REF TO if_adt_exception_properties.
    DATA l_trkorr TYPE trkorr.
    DATA l_new_devclass TYPE devclass.

    l_resource_id  = data-name.           " target
    l_orig_reps    = data-template-name.  " source to copy
    l_new_reps     = data-name.
    l_trkorr       = transport.
    l_new_devclass = data-package_ref-name.

    l_lock_handle = cl_adt_lock_handle=>get_instance( cl_sedi_adt_res_source=>co_wb_type_program(4) ).

*   authority-check (also locks the target object)
    TEST-SEAM authority_check_copy_reps.
*      CALL FUNCTION 'RS_ACCESS_PERMISSION'
*        EXPORTING
*          authority_check                = abap_true
*          global_lock                    = abap_true "abap_false don't work
*          mode                           = 'INSERT'
*          object                         = l_resource_id
*          object_class                   = 'ABAP'
*          suppress_corr_check            = abap_true
*          suppress_corr_check_altogether = abap_true
*          suppress_language_check        = abap_true
*          suppress_editor_lock_check     = abap_false
*          suppress_extend_dialog         = abap_true
*          lock_handle                    = l_lock_handle
*        EXCEPTIONS
*          canceled_in_corr               = 01
*          enqueued_by_user               = 02
*          enqueue_system_failure         = 03
*          illegal_parameter_values       = 04
*          locked_by_author               = 05
*          no_modify_permission           = 06
*          no_show_permission             = 07
*          permission_failure             = 12.
    END-TEST-SEAM.
    IF sy-subrc <> 0.
      l_props = cx_adt_rest=>create_properties( ).
*      l_props->add_property( key = co_longtext value = cx_adt_rest=>get_longtext_from_msg_params( ) ).
      RAISE EXCEPTION TYPE cx_adt_res_no_access
        EXPORTING
          textid      = cx_adt_rest=>create_textid_from_msg_params( )
          resource_id = l_resource_id
*         resource_type = resource_type_include
          properties  = l_props.
    ENDIF.

*    IF cl_adt_cts_management=>is_transport_disabled_for_pack( CONV #( data-package_ref-name ) ) = abap_true.
*      CLEAR l_trkorr.
*    ENDIF.
    DATA lifecycle_manager TYPE REF TO cl_adt_corr_insert_dark.
    CREATE OBJECT lifecycle_manager.
    lifecycle_manager->if_adt_lifecycle_manager~corrnr = l_trkorr.
    lifecycle_manager->if_adt_lifecycle_manager~devclass = l_new_devclass.

    CALL FUNCTION 'RS_COPY_PROGRAM'
      EXPORTING
        corrnumber         = l_trkorr
        devclass           = l_new_devclass
        program            = l_new_reps
        source_program     = l_orig_reps
        lock_handle        = l_lock_handle
*       suppress_checks    = abap_true
        suppress_popup     = abap_true
        suppress_screen    = abap_true
        with_cua           = abap_true
        with_documentation = abap_true
        with_dynpro        = abap_true
        with_includes      = abap_false "deep copy for programs with includes is not supported
        with_textpool      = abap_true
        with_variants      = abap_true
        skip_progress_ind  = abap_true
        lifecycle_manager  = lifecycle_manager
      EXCEPTIONS
        enqueue_lock       = 01
        object_not_found   = 02
        permission_failure = 03
        reject_copy        = 04.

    CASE sy-subrc.
      WHEN 0.
        " continue below
      WHEN 1 OR 3.
        RETURN.
*        RAISE EXCEPTION TYPE cx_adt_res_no_access
*          EXPORTING
*            textid        = cx_adt_rest=>create_textid_from_msg_params( )
**            resource_type = cl_sedi_adt_res_source=>resource_type
*            resource_id   = l_resource_id.
      WHEN 2.
        RETURN.
*        RAISE EXCEPTION TYPE cx_adt_res_not_found
*          EXPORTING
*            textid        = cx_adt_rest=>create_textid_from_msg_params( )
**            resource_type = cl_sedi_adt_res_source=>resource_type
*            resource_id   = l_resource_id.
      WHEN OTHERS.
        RETURN.
*        RAISE EXCEPTION TYPE cx_adt_res_creation_failure
*          EXPORTING
*            textid        = cx_adt_rest=>create_textid_from_msg_params( )
**            resource_type = cl_sedi_adt_res_source=>resource_type
*            resource_id   = l_resource_id.
    ENDCASE.

    " explicitly unlock target (do not rely on an implicit unlock when the ABAP session terminates)
    CALL FUNCTION 'RS_ACCESS_PERMISSION'
      EXPORTING
        authority_check = space
        global_lock     = space
        mode            = 'FREE'
        object          = l_resource_id
        object_class    = 'ABAP'
        lock_handle     = l_lock_handle.
  ENDMETHOD.


  METHOD create_copy_of_table.
    DATA: lv_source_name TYPE ddobjname,
          lv_target_name TYPE ddobjname.

    IF data-adt_template-name IS NOT INITIAL.
      "current version stores the template structure in adt_template since May 2015
      lv_source_name = data-adt_template-name.
    ELSE.
      "compatible fallback for initial version of the structure editor
      lv_source_name = data-template-name.
    ENDIF.

    lv_target_name = data-name.

    TEST-SEAM object_copy.
      CALL FUNCTION 'DDUT_OBJECT_COPY'
        EXPORTING
          type            = 'TABL'
          src_name        = lv_source_name
          dst_name        = lv_target_name
          with_docu       = abap_true
          with_subobjects = abap_true
          state           = 'M'
        EXCEPTIONS
          OTHERS          = 42.

      IF sy-subrc <> 0.
        RAISE EXCEPTION TYPE cx_swb_exception.
      ENDIF.

      CALL FUNCTION 'DD_TABL_ACT'
        EXPORTING
          tabname           = lv_target_name
*         prid              = lv_log_id
*      IMPORTING
*         act_result        = lv_res
*         act_tabl_res_info = lt_act_tabl_res_info
*      TABLES
*         act_res_tab       = lt_act_res_tab
        EXCEPTIONS
          actok_failure     = 1
          dbchange_failure  = 2
          lockact_failure   = 3
          ntab_gen_failure  = 4
          put_failure       = 5
          read_failure      = 6
          unlockact_failure = 7
          access_failure    = 8.

      IF sy-subrc = 0.
        DATA(object_name) = NEW trobj_name( |TABL{ lv_target_name }| ).
        DATA(devclass) = NEW devclass( data-package_ref-name  ).
        CALL FUNCTION 'RS_CORR_INSERT'
          EXPORTING
            object          = object_name->*
            object_class    = 'DICT'
            mode            = 'I'
            global_lock     = abap_true
            devclass        = devclass->*
            korrnum         = transport
            master_language = sy-langu.

      ENDIF.
*
*    master_language = NEW CL_SBD_STRUCTURE_PERSIST( )->get_master_language( lv_target_name ).
*
*    CALL FUNCTION 'DDIF_TABL_GET'
*      EXPORTING
*        name     = lv_target_name
*        state    = 'M'
*        langu    = master_language
*      IMPORTING
*        dd02v_wa = dd02v_wa.
*
*    IF dd02v_wa-proxytype = 'X'.
*
*      UPDATE dd02l
*      SET proxytype = ' '
*      WHERE tabname = lv_target_name
*      AND   as4local  <> 'A'
*      AND   proxytype = 'X'.
*
*      description = |{ TEXT-001 } { lv_source_name }|.
*
*      UPDATE dd02t
*      SET ddtext = description
*      WHERE tabname = lv_target_name
*      AND   as4local  <> 'A'
*      AND   ddlanguage = master_language.
*
*    ENDIF.

    END-TEST-SEAM.
  ENDMETHOD.
ENDCLASS.
