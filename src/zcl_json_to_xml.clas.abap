CLASS zcl_json_to_xml DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_json_to_xml IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    DATA(users) = cl_cts_request_org_factory=>get_user_details( VALUE #( ( name = 'TESTER' )
                                                                         ( name = 'TEST-INFO' ) ) ).

*    TRY .
*        DATA(lr_xml_writer) = cl_proxy_sxml_factory=>create_string_writer( ).
*
*        cl_proxy_xml_transform=>abap_to_xml(
*            abap_data     = users
*            xml_writer    = lr_xml_writer ).
*
*        DATA xml          TYPE xstring.
*        xml = lr_xml_writer->get_output( ).
*
*      CATCH cx_proxy_fault cx_transformation_error cx_edocument INTO DATA(gx_exception).
*
*    ENDTRY.

    DATA(json) = /ui2/cl_json=>serialize( users ).

    DATA(json_string) = cl_abap_codepage=>convert_to( json ).
*    cl_demo_output=>display_json( json_string ).

    CALL TRANSFORMATION id SOURCE XML json_string
                        RESULT XML DATA(xml).


    cl_demo_output=>display_xml( xml ).

  ENDMETHOD.
ENDCLASS.
