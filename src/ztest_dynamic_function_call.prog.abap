*&---------------------------------------------------------------------*
*& Report ZTEST_DYNAMIC_FUNCTION_CALL
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ztest_dynamic_function_call.

TABLES: tfdir.
SELECT-OPTIONS: s_fname FOR tfdir-funcname.
PARAMETERS: threads TYPE i.

CLASS execute_fm DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS: process_fm IMPORTING function_name TYPE funcname.

ENDCLASS.

CLASS execute_fm IMPLEMENTATION.

  METHOD process_fm.
    DATA system(10) VALUE 'PRD.015'.
    DATA empty_ref TYPE REF TO data.
    DATA export_parameters TYPE abap_func_parmbind_tab.

    "Get Function Module Interface
    cl_fb_function_utility=>meth_get_interface( EXPORTING im_name = |{ function_name }|
                                                IMPORTING ex_interface = DATA(interface)
                                                EXCEPTIONS OTHERS = 1 ).

    DATA component TYPE abap_componentdescr.
    "Get structure definition of /BMW/OTD1889_S_SPLUNK_PAYLOAD and add attributes/components dynamically
    DATA(components) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_name( '/BMW/OTD1889_S_SPLUNK_PAYLOAD' ) )->get_components( ).
    DATA(event_components) = CAST cl_abap_structdescr( components[ name = 'EVENT' ]-type )->get_components( ).
    "Fill Exporting parameters and ensure to use the Correct Object Type (structure or table)
    LOOP AT interface-export REFERENCE INTO DATA(export_parameter).
      CREATE DATA empty_ref TYPE (export_parameter->structure).

      INSERT VALUE #( name  = export_parameter->parameter kind = abap_func_importing
                      value =  empty_ref  )
        INTO TABLE export_parameters.
      "Add exporting parameters as Attributes to the payload structure
*      component-name = export_parameter->parameter.
*      component-type ?= cl_abap_elemdescr=>describe_by_name( export_parameter->structure ).
*      INSERT component INTO TABLE event_components.
    ENDLOOP.
*    SORT event_components BY name.
*    DELETE ADJACENT DUPLICATES FROM event_components.
    "Fill all common parameters (static)
    DATA(time_interval) = VALUE /bmw/otd1889_time_interval( start_date = sy-datum - 2 start_time = sy-uzeit - 1800
                                                              end_date   = sy-datum - 2 end_time   = sy-uzeit ).

    DATA(parameters) = VALUE abap_func_parmbind_tab( BASE export_parameters
                         ( name  = 'IV_SYSCLNT_SENDER' kind  = abap_func_exporting value = REF #( system ) )
                         ( name  = 'IV_SYSCLNT_RECIPIENT' kind  = abap_func_exporting value = REF #( system ) )
                         ( name  = 'IS_TIME_INTERVAL' kind  = abap_func_exporting value = REF #( time_interval ) ) ).
    "Check and fill additional Importing parameters
    IF lines( interface-import ) > 3.
      LOOP AT interface-import REFERENCE INTO DATA(import_parameter)
        WHERE defaultval IS INITIAL.
        CHECK NOT line_exists( parameters[ name = import_parameter->parameter ] ).

        CREATE DATA empty_ref TYPE (import_parameter->structure).

        INSERT VALUE #( name  = import_parameter->parameter kind = abap_func_exporting
                        value = empty_ref )
          INTO TABLE parameters.
      ENDLOOP.
    ENDIF.
    "Dynamic function call
    CALL FUNCTION function_name
      PARAMETER-TABLE parameters.
    "Create Payload strcuture dynamically during runtime with added required attributes from the Called Function
*    DATA(event_structure) = cl_abap_structdescr=>get( event_components ).
*    components[ name = 'EVENT' ]-type = event_structure.
*    DATA(payload_structure) = cl_abap_structdescr=>get( components ).
*    CREATE DATA empty_ref TYPE HANDLE payload_structure.
*
*    ASSIGN empty_ref->* TO FIELD-SYMBOL(<request>).
*    "Fill Splunk specific attributes (the values should be stored somewhere
*    ASSIGN COMPONENT 'SPLUNK_INDEX' OF STRUCTURE <request> TO FIELD-SYMBOL(<splunk_index>).
*    <splunk_index> = 'glob_sap_logs_t'.
*    ASSIGN COMPONENT 'SOURCETYPE' OF STRUCTURE <request> TO FIELD-SYMBOL(<sourcetype>).
*    <sourcetype> = 'glob_sap_jobslogs_json'.
    FIELD-SYMBOLS: <value_table>    TYPE ANY TABLE,
                   <events_content> TYPE ANY TABLE.
    DATA value TYPE REF TO data.
    LOOP AT parameters REFERENCE INTO DATA(return_parameter)
      WHERE kind =  abap_func_importing
        AND name <> 'EV_SUBRC'.
      "Assign monitoring Results to Payload structure
*      ASSIGN COMPONENT |EVENT-{ return_parameter->name }| OF STRUCTURE <request> TO FIELD-SYMBOL(<value>).
      ASSIGN return_parameter->value->* TO FIELD-SYMBOL(<results>).
*      <value> = <results>.
*
      ASSIGN <results> TO <value_table>.
      LOOP AT <value_table> REFERENCE INTO value.
        component-type ?= cl_abap_elemdescr=>describe_by_data( value ).
        components[ name = 'EVENT' ]-type = cl_abap_tabledescr=>get( component-type ).
        DATA(payload_structure) = cl_abap_structdescr=>get( components ).
        CREATE DATA empty_ref TYPE HANDLE payload_structure.

        ASSIGN empty_ref->* TO FIELD-SYMBOL(<request>).
*    "Fill Splunk specific attributes (the values should be stored somewhere
        ASSIGN COMPONENT 'SPLUNK_INDEX' OF STRUCTURE <request> TO FIELD-SYMBOL(<splunk_index>).
        <splunk_index> = 'glob_sap_logs_t'.
        ASSIGN COMPONENT 'SOURCETYPE' OF STRUCTURE <request> TO FIELD-SYMBOL(<sourcetype>).
        <sourcetype> = 'glob_sap_jobslogs_json'.

        EXIT.
      ENDLOOP.

      ASSIGN COMPONENT |EVENT| OF STRUCTURE <request> TO <events_content>.
      ASSIGN return_parameter->value->* TO <events_content>.
*      <events_content> = value #( FOR content in <value_table> ( table_line = result ) ).

    ENDLOOP.
    "Map/Rename Splunk attribute
    DATA(mappings) = VALUE /ui2/cl_json=>name_mappings( ( abap = `SPLUNK_INDEX` json = `index` ) ).
    DATA(json) = /ui2/cl_json=>serialize( data = <request>
                                          name_mappings = mappings
                                          pretty_name = /ui2/cl_json=>pretty_mode-low_case
                                          assoc_arrays = abap_true
                                          assoc_arrays_opt = abap_true ).
    cl_demo_output=>write_json( json ).
    cl_demo_output=>display(  ).

  ENDMETHOD.

ENDCLASS.

INITIALIZATION.
  DATA(time_interval) = VALUE /bmw/otd1889_time_interval( start_date = sy-datum - 2 start_time = sy-uzeit - 1800
                                                            end_date   = sy-datum - 2 end_time   = sy-uzeit ).

START-OF-SELECTION.
*  LOOP AT s_fname REFERENCE INTO DATA(function_module).
*    execute_fm=>process_fm( function_module->low ).
**    DATA(api_engine) = NEW /bmw/otd1889_cl_api_engine( parallel_processing = abap_true maximum_threads = threads ).
**
**    api_engine->process_function_monitor( function_name = function_module->low
**                                          time_interval = time_interval ).
*  ENDLOOP.
*  DATA enhancement_tool type ref to CL_ENH_TOOL_BADI_IMPL.
*  enhancement_tool ?= cl_enh_factory=>get_enhancement( '/BMW/OTD1889_ES_SPLUNK_MON' ).
*  DATA(enhancements) = enhancement_tool->get_implementations( ).
  DATA(enhancements) = CAST cl_enh_tool_badi_impl( cl_enh_factory=>get_enhancement( '/BMW/OTD1889_ES_SPLUNK_MON' ) )->get_implementations( ).
  CHECK lines( enhancements ) IS NOT INITIAL.
*
*  DATA: splunk_badi   TYPE REF TO /bmw/otd1889_badi_splunk_mon,
*        function_name TYPE string.
*  data(name) = enhancements[ 1 ]-badi_name.
*  function_name =  enhancements[ 1 ]-filter_values[ 1 ]-filter_string_value1.
*
*  GET BADI splunk_badi" TYPE (name)
*    FILTERS
*      function = '/BMW/OTD1889_ADDON_SM37'.
**    DATA(sm37) = splunk_badi->get_instance( function = '/BMW/OTD1889_ADDON_SM37' ).
*
*  CALL BADI splunk_badi->trigger_monitor
*    EXPORTING
*      time_interval = time_interval.
*
*  WRITE enhancements[ 1 ]-filter_values[ 1 ]-filter_string_value1.
