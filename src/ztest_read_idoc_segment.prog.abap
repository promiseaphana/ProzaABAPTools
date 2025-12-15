*&---------------------------------------------------------------------*
*& Report ZTEST_READ_IDOC_SEGMENT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ztest_read_idoc_segment.
*PARAMETERS:pa TYPE edihsegtyp.

FIELD-SYMBOLS:<fs> TYPE any.
DATA:wf_ref TYPE REF TO data.

START-OF-SELECTION.

  DATA idoc_number TYPE edi_docnum VALUE '0000000000149307'.
  SELECT FROM edidc AS idoc_control
    RIGHT OUTER JOIN edid4 AS segments
    ON idoc_control~docnum = segments~docnum
    FIELDS idoc_control~docnum, idoc_control~status, idoc_control~credat,
          idoc_control~cretim,segments~segnam
         WHERE idoc_control~docnum = @idoc_number
          AND idoc_control~mestyp = 'MATMAS'
    INTO TABLE @DATA(IDOC_data).

  CALL FUNCTION 'EDI_DOCUMENT_OPEN_FOR_READ'
    EXPORTING
      document_number = idoc_number.

  DATA segment TYPE edidd.
  CALL FUNCTION 'EDI_SEGMENT_GET'
    EXPORTING
      document_number = idoc_number
      segment_name    = 'E1ADRM1'
    IMPORTING
      idoc_container  = segment.

  CREATE DATA wf_ref TYPE (segment-segnam).
  wf_ref->* = segment-sdata.

  CALL FUNCTION 'EDI_DOCUMENT_CLOSE_READ'
    EXPORTING
      document_number = segment-docnum.
