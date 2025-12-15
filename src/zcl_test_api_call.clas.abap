CLASS zcl_test_api_call DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
    METHODS:
      get_field_mappings
        IMPORTING material TYPE /bmw/otd3037_wl
        RETURNING VALUE(mapped_data) TYPE cl_api_product_dpc_ext=>ty_s_product_struc,
      trigger_production_version_cre
        IMPORTING production_version TYPE r_productionversiontp.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_test_api_call IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    cl_http_client=>create_internal(
        IMPORTING
            client      = DATA(http_client)
        EXCEPTIONS
            OTHERS      = 1 ).

    " Check errors.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    SELECT SINGLE * FROM /bmw/otd3037_wl
    INTO @DATA(material).

    cl_http_utility=>set_request_uri(
      request = http_client->request
                uri     = |/sap/api_product_srv/A_Product?$expand=to_Plant| ).

*    http_client->append_field_url( name = 'product' value = conv #( material-matnr ) url = http_client-> ) ).

    http_client->request->set_header_field( name  = '~request_method'
                                            value = 'POST' ).

    http_client->request->set_header_field( name  = if_http_header_fields=>content_type
                                            value = 'application/json; charset=utf-8' ).

    DATA(json_message) = /ui2/cl_json=>serialize( data = get_field_mappings( material ) ).
    http_client->request->set_cdata( json_message ).

    http_client->send( ).

    http_client->receive(
      EXCEPTIONS
        http_communication_failure = 1
        http_invalid_state         = 2
        http_processing_failed     = 3
        OTHERS                     = 4 ).

    IF sy-subrc = 0.
      DATA(response) = http_client->response->get_cdata(  ).
      http_client->response->get_status( IMPORTING code   = DATA(code)
                                                   reason = DATA(reason) ).
    ENDIF.

        "oData v2 remote proxy
*        DATA(client_proxy) = /iwbep/cl_cp_client_proxy_fact=>create_v2_local_proxy(
*                                VALUE #( service_id = 'API_PRODUCT_SRV' service_version = '0001' ) ).
*
*        DATA(create_request) = client_proxy->create_resource_for_entity_set( 'A_Product' )->create_request_for_create( ).
*
**        DATA(json_message) = /ui2/cl_json=>serialize( data = material
**                                                      name_mappings = get_field_mappings(  ) ).
**        DATA(message) = NEW cl_api_product_dpc_ext=>ty_s_product_struc( get_mapped_data( material ) ).
**        DATA(query) = VALUE /iwbep/if_cp_runtime_types=>ty_t_custom_query_option( ( name = '$expand' value = 'to_Plant' ) ).
**        create_request = create_request->set_custom_query_options( query ).
*
*        DATA(data_response) = create_request->set_deep_business_data(
*                            is_business_data = message->*
*                            io_data_description = create_request->create_data_descripton_node( ) ).
*        DATA(call_response) = data_response->execute( ).
*
*        "Retrieve the business data
**        response->.
*
*      CATCH /iwbep/cx_cp_remote INTO DATA(ex_cp_remote).
*        " Error handling
**        ex_cp_remote->get_longtext( ) ).
*      CATCH /iwbep/cx_gateway INTO DATA(ex_gateway).
*        " Error Handling
**        ex_gateway->get_longtext( ) ).
*    ENDTRY.

   DATA: expand                 TYPE REF TO /iwbep/if_mgw_odata_expand ##NEEDED,
          request_context_struct TYPE /iwbep/if_mgw_core_srv_runtime=>ty_s_mgw_request_context.
    TRY.
        DATA(v2_service_info) = /iwbep/cl_mgw_med_provider=>get_med_provider( )->get_service_info(
                                iv_external_name          = 'API_PRODUCT_SRV'
                                iv_namespace              = ''
                                iv_version                = '0001'
                                iv_do_check_for_extension = abap_true ).

      CATCH /iwbep/cx_mgw_tech_exception INTO DATA(ex_v2_registry).
        RAISE EXCEPTION NEW /iwbep/cx_cp_local_v2( textid   = /iwbep/cx_cp_local_v2=>t_v2_runtime_error
                                                   previous = ex_v2_registry ).
    ENDTRY.

    DATA v2_context           TYPE REF TO /iwbep/if_mgw_context.
    v2_context = NEW /iwbep/cl_mgw_context(
        it_context           = request_context_struct-context_params
        is_system_alias_info = request_context_struct-system_alias_info ).

    v2_context->set_parameter( iv_name  = /iwbep/if_mgw_context=>gc_param_isn
                                  iv_value = v2_service_info-technical_name ).

    v2_context->set_parameter( iv_name  = /iwbep/if_mgw_context=>gc_param_isv
                                  iv_value = v2_service_info-version ).

    v2_context->set_parameter( iv_name  = /iwbep/if_mgw_context=>gc_param_dpc
                                  iv_value = v2_service_info-class_name ).

    DATA odata_service TYPE REF TO /iwbep/if_mgw_core_srv_runtime.
    CREATE OBJECT odata_service TYPE (v2_service_info-class_name).

    request_context_struct-technical_request-source_entity_type  = 'A_ProductType'.
    request_context_struct-technical_request-target_entity_type  = 'A_ProductType'.
    request_context_struct-technical_request-source_entity_set   = 'A_Product'.
    request_context_struct-technical_request-target_entity_set   = 'A_Product'.

    /iwbep/cl_mgw_med_utils=>normalize_technical_name(
  EXPORTING
    iv_technical_name = 'API_PRODUCT_SRV'
  IMPORTING
    ev_name           = request_context_struct-service_doc_name
    ev_namespace      = request_context_struct-namespace ).

    request_context_struct-parameters = VALUE #( ( name = '$expand' value = 'to_Plant' ) ).
    request_context_struct-technical_request-expand = 'to_Plant'.
    request_context_struct-source_entity = 'A_ProductType'.
    request_context_struct-source_entity_set = 'A_Product'.
    request_context_struct-target_entity = 'A_ProductType'.
    request_context_struct-target_entity_set = 'A_Product'.
    request_context_struct-operation = odata_service->gcs_operation-create.
*    v2_context->get_parameters( IMPORTING et_parameter = request_context_struct-context_params ).

    TRY.
        odata_service->init(
            iv_service_document_name = request_context_struct-service_doc_name
            iv_namespace             = request_context_struct-namespace
            iv_version               = request_context_struct-version
            io_context               = v2_context ).

      CATCH /iwbep/cx_mgw_base_exception INTO DATA(ex_v2_dpc_initialize).
        RAISE EXCEPTION NEW /iwbep/cx_cp_local_v2( textid   = /iwbep/cx_cp_local_v2=>t_v2_runtime_error
                                                   previous = ex_v2_dpc_initialize ).
    ENDTRY.

*    SELECT SINGLE * FROM /bmw/otd3037_wl
*    INTO @DATA(material).

    TRY.
        DATA: headers TYPE tihttpnvp,
              entity  TYPE REF TO data.

        odata_service->create_entity(
        EXPORTING
        iv_entity_name          = 'A_ProductType'
        iv_source_name      = 'A_ProductType'
            io_data_provider        = NEW /iwbep/cl_cp_v2_entry_provider( NEW cl_api_product_dpc_ext=>ty_s_product_struc( get_field_mappings( material ) ) )
            is_request_details = request_context_struct
          CHANGING
            ct_headers         = headers
            cr_entity          = entity
        ).
      CATCH /iwbep/cx_mgw_busi_exception.
      CATCH /iwbep/cx_mgw_tech_exception.
    ENDTRY.

    DATA(client_proxy) = /iwbep/cl_cp_client_proxy_fact=>create_v2_local_proxy(
                            VALUE #( service_id = 'API_PRODUCT_SRV' service_version = '0001' ) ).
  ENDMETHOD.

  METHOD get_field_mappings.
    DATA(mappings) = VALUE /ui2/cl_json=>name_mappings( ( abap = 'MATNR' json = 'Product' )
*                                                        ( abap = 'WERKS' json = 'Plant' )
                                                        ( abap = 'MTART' json = 'ProductType' )
                                                        ( abap = 'MATKL' json = 'ProductGroup' )
                                                        ( abap = 'MEINS' json = 'BaseUnit' )
                                                        ( abap = 'SPART' json = 'Division' )
                                                        ( abap = 'BEGRU' json = 'AuthorizationGroup' )
                                                        ( abap = 'MTPOS_MARA' json = 'ItemCategoryGroup' ) ).

    LOOP AT mappings INTO DATA(mapping).
      ASSIGN COMPONENT mapping-abap OF STRUCTURE material TO FIELD-SYMBOL(<material>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      ASSIGN COMPONENT mapping-json OF STRUCTURE mapped_data TO FIELD-SYMBOL(<mapped_data>).
      <mapped_data> = <material>.
    ENDLOOP.
  ENDMETHOD.
  METHOD trigger_production_version_cre.
    CHECK production_version IS NOT INITIAL.

    TRY.
        "oData v4 remote proxy
        DATA(client_proxy) = /iwbep/cl_cp_client_proxy_fact=>create_v4_local_proxy(
                                VALUE #( service_id = 'API_PRODUCTIONVERSION' repository_id = 'SRVD_A2X' service_version = '0001' ) ).

        DATA(create_request) = client_proxy->create_resource_for_entity_set( 'PRODUCTIONVERSION' )->create_request_for_create( ).

        DATA(data_response) = create_request->set_deep_business_data(
                            is_business_data = production_version
                            io_data_description = create_request->create_data_descripton_node( ) ).
        DATA(call_response) = data_response->execute( ).

      CATCH /iwbep/cx_cp_remote INTO DATA(ex_cp_remote).
        " Error handling
*        ex_cp_remote->get_longtext( ) ).
      CATCH /iwbep/cx_gateway INTO DATA(ex_gateway).
        " Error Handling
*        ex_gateway->get_longtext( ) ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
