*&---------------------------------------------------------------------*
*& Report ZTEST_INSTANCE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ztest_instance.
  CALL FUNCTION 'AUTHORITY_CHECK_TCODE'
    exporting
        tcode = 'SU01'
   EXCEPTIONS
    ok = 0
    OTHERS = 1.
  if sy-subrc is not INITIAL.
    MESSAGE e172(00) WITH 'SU01'.
  endif.
PARAMETERS text TYPE string.

START-OF-SELECTION.

  SELECT SINGLE FROM t000
    FIELDS mtext, cccategory, cccoractiv
    INTO @DATA(clients).

*  DATA(field) = COND string( WHEN source_structure IS INITIAL THEN source_field ELSE |{ source_structure }-{ source_field }| ).
  ASSIGN COMPONENT 'cccategory' OF STRUCTURE clients TO FIELD-SYMBOL(<value>).

  DATA condition TYPE string.
  condition = |cccategory = 'T' and cccoractiv = '2'|.
*    DATA(client) = clients[ cccategory = 'T' cccoractiv = '2' ].
*    DATA(client) = clients[ condition ].
*     DATA(client) = VALUE t000_tab( FOR wa in clients WHERE ( TABLE_LINE = condition ) ( wa ) ).
*  SELECT SINGLE * FROM @clients AS clients
*     WHERE (condition)
*     INTO @DATA(client).

  RETURN.

  DATA(values) = NEW cl_abap_cc_domain( 'RFCTYPE' )->values.
  DATA(mixed) = to_mixed( 'RFCTYPE_TEST' ).
  WRITE |mixed: { mixed }|.

  mixed = from_mixed( val = mixed sep = '_' case = 'A' ).
  WRITE |from mixed: { mixed }|.

  DATA(uppercase) = to_upper( 'rfctype_Test' ).
  WRITE / |uppercase: { uppercase }|.
*DATA val type string VALUE 'EWMSGM_3400100000017926'.
*DATA(string) = match( val = val regex = '[^[:alpha:]]' ).
*write string.
*DATA(string2) = match( val = val regex = '[^a-zA-Z]' ).
*
*write string2.

  DATA(string3) = match( val = text regex = '^[[:alpha:]]+' ).

  WRITE / |Match function: { string3 }|.

*  DATA(string4) = cl_abap_regex=>create_posix( pattern = '^[[:alpha:]]+' )->create_matcher( text = text )->match( ).
*                                                                                                    CATCH cx_sy_matcher. " System Exceptions for Regular Expressions
*  WRITE / |Match method: { string4 }|.

  DATA(string5) = 'DeepDive'.
  string5 = replace( val = string5 sub = 'ee' with = 'ii' ).
  WRITE / |Replace function: { string5 }|.

  TRY.
      DATA(serverHost) = CAST cl_dest_rfc_abap( cl_dest_factory=>create( 'Visual' ) )->server_name.
      WRITE serverHost.
    CATCH cx_dest_api.

  ENDTRY.
