CLASS zcl_build_structure_hierarchy DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_BUILD_STRUCTURE_HIERARCHY IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    SELECT FROM dd03l
      FIELDS fieldname, position, datatype, '00000' AS parent
      WHERE tabname = '/SCMTMS/CPX_TOR_GENRIC_REQUEST'
        AND datatype <> @space
        ORDER BY position DESCENDING
    INTO TABLE @DATA(field_hierarchy).

    out->write(  lines( field_hierarchy ) ).

*    SORT field_hierarchy BY position DESCENDING.

    LOOP AT field_hierarchy REFERENCE INTO DATA(field).
      LOOP AT field_hierarchy REFERENCE INTO DATA(parent) FROM sy-tabix + 1
        WHERE datatype = 'STRU'.
        field->parent = parent->position.
        out->write( |{ field->fieldname }: { parent->fieldname }| ).
        EXIT.
      ENDLOOP..
    ENDLOOP.

    out->write( lines( field_hierarchy ) ).

*    DATA(structure_def) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_name( 'ZDEEP_NESTED_STRUCTURE' ) )->get_ddic_field_list( ).
  ENDMETHOD.
ENDCLASS.
