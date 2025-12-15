CLASS zcl_json_field_reader DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_json_field_reader IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    DATA json_string TYPE string.
    json_string = '{"user": {"Firstname": "John", "Lastname": "Doe", "age": 30}}'.
    DATA(lv_pattern) = `\"Firstname\"\s*:\s*\"([^\"]+)\"`.

*    DATA submatch TYPE string.
    FIND REGEX lv_pattern IN json_string SUBMATCHES DATA(submatch).

*    DATA: json_string TYPE string VALUE '{"user": {"Firstname": "John", "Lastname": "Doe", "age": 30}}',
*          firstname   TYPE string,
*          regex       TYPE REF TO cl_abap_regex,
*          matcher     TYPE REF TO cl_abap_matcher.
*
*    DATA(pattern) = `\"Firstname\"\s*:\s*\"([^\"]+)\"`.
*
*    " Create regex object
*    regex = cl_abap_regex=>create_pcre(
*      pattern = lv_pattern
*      ignore_case = abap_true ).
*
*    " Create matcher object
*    matcher = regex->create_matcher( text = json_string ).
*
*    " Check if there is a match and retrieve the first capturing group
*    IF matcher->match( ).
*      firstname = matcher->get_submatch( 1 ).
*    ENDIF.
    cl_demo_output=>display( submatch ).
  ENDMETHOD.

ENDCLASS.
