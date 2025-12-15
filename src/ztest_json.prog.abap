*&---------------------------------------------------------------------*
*& Report ZTEST_JSON
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ztest_json.

START-OF-SELECTION.

    DATA(users) = cl_cts_request_org_factory=>get_user_details( VALUE #( ( name = 'USer1' )
                                                                         ( name = 'USer2' ) ) ).

    DATA(json) = /ui2/cl_json=>serialize( users ).

    DATA(json_string) = cl_abap_codepage=>convert_to( json ).
*CALL TRANSFORMATION id SOURCE XML json_string
*                       RESULT XML DATA(xml).
*cl_demo_output=>display_xml( xml ).

*  DATA(json) = `{"TEXT":"JSON"}`.
  CALL TRANSFORMATION id SOURCE XML json_string
                      RESULT XML DATA(xml).

  TRY.
      DATA(reader) = cl_sxml_string_reader=>create( xml ).
      DATA(writer) = CAST if_sxml_writer(
                            cl_sxml_string_writer=>create( ) ).
      writer->set_option( option = if_sxml_writer=>co_opt_linebreaks ).
      writer->set_option( option = if_sxml_writer=>co_opt_indent ).
      reader->next_node( ).
      reader->skip_node( writer ).
*       DATA(xml_output) = cl_abap_codepage=>convert_from( CAST cl_sxml_string_writer( writer )->get_output( ) ).
      DATA(xml_output) = cl_abap_conv_codepage=>create_in(  )->convert( CAST cl_sxml_string_writer( writer )->get_output( ) ).
    CATCH cx_sxml_parse_error.
      RETURN.
  ENDTRY.

  cl_demo_output=>display_xml( xml_output ).
