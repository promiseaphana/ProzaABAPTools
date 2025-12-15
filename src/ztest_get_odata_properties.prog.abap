*&---------------------------------------------------------------------*
*& Report ztest_get_odata_properties
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ztest_get_odata_properties.

CLASS odata_entity_reader DEFINITION.
  PUBLIC SECTION.
    METHODS main.
  PRIVATE SECTION.
    METHODS init_dp_for_unit_test
      IMPORTING
                request_context_data   TYPE REF TO /iwbep/cl_mgw_request_unittst=>ty_s_mgw_request_context_unit
                data_provider          TYPE REF TO /iwbep/if_mgw_core_srv_runtime
                odata_model            TYPE REF TO /iwbep/if_mgw_odata_fw_model
      RETURNING VALUE(request_context) TYPE REF TO /iwbep/cl_mgw_request_unittst.
ENDCLASS.

CLASS odata_entity_reader IMPLEMENTATION.
  METHOD main.
    DATA(odata_service) = NEW cl_fin_user_defaultpar_dpc_ext( ).

    DATA: request_context_struct TYPE /iwbep/cl_mgw_request_unittst=>ty_s_mgw_request_context_unit,
          request_context_object TYPE REF TO /iwbep/cl_mgw_request_unittst.

    request_context_struct-technical_request-source_entity_type  = |{ cl_fin_user_defaultpar_mpc=>gc_defaultparameter }|.
    request_context_struct-technical_request-target_entity_type  = |{ cl_fin_user_defaultpar_mpc=>gc_defaultparameter }|.
    request_context_struct-technical_request-source_entity_set   = |{ cl_fin_user_defaultpar_mpc=>gc_defaultparameter }Set|.
    request_context_struct-technical_request-target_entity_set   = |{ cl_fin_user_defaultpar_mpc=>gc_defaultparameter }Set|.

    DATA(odata_model) = NEW /iwbep/cl_mgw_odata_model( ).

    odata_model->/iwbep/if_mgw_odata_model_conv~use_model(
      iv_version        = '0001'
      iv_technical_name = 'FIN_USER_DEFAULTPARAMETER_MDL' ).

*    request_context_object = odata_service->/iwbep/if_mgw_conv_srv_runtime~init_dp_for_unit_test( is_request_context = request_context_struct ).
    request_context_object = init_dp_for_unit_test( request_context_data = REF #( request_context_struct )
                                                  data_provider        = odata_service
                                                  odata_model          = odata_model ).

    DATA facade TYPE REF TO /iwbep/if_mgw_dp_int_facade.

    facade  ?= odata_service->/iwbep/if_mgw_conv_srv_runtime~get_dp_facade( ).

    DATA(model) = facade->get_model( ).

    DATA(entity_type) = model->get_entity_type( 'Defaultparameter' ).


    WRITE 'hello'.
  ENDMETHOD.

  METHOD init_dp_for_unit_test.
    DATA: headers   TYPE    tihttpnvp.
    request_context = NEW #( it_headers = headers
                             io_model   = odata_model ).

    request_context->set_request_context( request_context_data ).

    DATA(logger) = /iwbep/cl_cos_logger=>get_logger( ).
    DATA(msg_container) = /iwbep/cl_mgw_msg_container=>get_mgw_msg_container( ).
    DATA: msg_container_fw TYPE REF TO /iwbep/cl_mgw_msg_container.
    TRY.
        msg_container_fw ?= msg_container.
        msg_container_fw->reset( ).
      CATCH cx_sy_move_cast_error.
        RETURN.
    ENDTRY.

    DATA: context   TYPE REF TO /iwbep/if_mgw_context.
    context = NEW /iwbep/cl_mgw_context( ).

    context->set_parameter(
      EXPORTING
        iv_name  = /iwbep/if_mgw_context=>gc_param_msg_container
        iv_value = msg_container ).

    context->set_parameter(
      EXPORTING
        iv_name  = /iwbep/if_mgw_context=>gc_param_logger
        iv_value = logger ).

    data_provider->set_context( context ).
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  NEW odata_entity_reader( )->main( ).
*  DATA lo_metadata_provider TYPE REF TO /iwbep/if_mgw_med_provider.

  DATA(metadata_provider) = /iwbep/cl_mgw_med_provider=>get_med_provider( ).

  metadata_provider->initialize(
    EXPORTING
      is_default_system_alias_info = VALUE #(  )
      iv_is_busi_data_request      = abap_true
  ).

*  CALL FUNCTION '/IWBEP/FM_MGW_MODEL_LOAD_SET'.

  DATA model TYPE REF TO /iwbep/if_mgw_odata_fw_model.
  model ?= metadata_provider->get_service_metadata(
                iv_internal_service_name    = 'FIN_USER_DEFAULTPARAMETER_SRV'
                iv_internal_service_version = '0001'
              ).

*  CALL FUNCTION '/IWBEP/FM_MGW_MODEL_LOAD_RESET'.

  DATA(properties) = model->get_entity_type( 'Defaultparameter' )->get_properties( ).
  cl_demo_output=>display( properties ).
