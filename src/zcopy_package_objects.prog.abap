REPORT zcopy_package_objects.

TABLES: tadir.

PARAMETERS: objtype TYPE char10 AS LISTBOX VISIBLE LENGTH 10 OBLIGATORY,
            objname TYPE sobj_name OBLIGATORY,
            package TYPE devclass OBLIGATORY,
            transp  TYPE trkorr.

DATA: lt_tadir TYPE TABLE OF tadir,
      ls_tadir TYPE tadir.

INITIALIZATION.

  DATA: lt_values TYPE vrm_values,
        ls_value  TYPE vrm_value.

*AT SELECTION-SCREEN OUTPUT.

  CLEAR lt_values.

  ls_value-key = 'C'.
  ls_value-text = 'Class'.
  APPEND ls_value TO lt_values.

  ls_value-key = 'R'.
  ls_value-text = 'Report'.
  APPEND ls_value TO lt_values.

  ls_value-key = 'T'.
  ls_value-text = 'Table'.
  APPEND ls_value TO lt_values.

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'OBJTYPE'
      values = lt_values.



START-OF-SELECTION.

  SELECT FROM tdevc
    FIELDS devclass
    WHERE devclass LIKE @package
    INTO TABLE @DATA(packages).

  LOOP AT packages INTO DATA(package_name).
    WRITE: / 'Processing package:', package_name.

    CASE objtype.
      WHEN 'C'. " Class
        " Implement class copy logic here
        WRITE: / 'Copying class:', objname, 'to package:', package_name.

        DATA(successful) = zcl_copy_objects_helper=>create_copy_of_class(
                              data = VALUE #( name             = replace( val = objname sub = 'XX' with = substring_after( sub = 'DEV-' val = CONV string( package_name ) len = 2 ) )
                                              template-name    = objname
                                              package_ref-name = package_name )
                              transport = transp ).
        WRITE: / 'Copying class:', successful.

      WHEN 'R'. " Report
        " Implement report copy logic here
        WRITE: / 'Copying report:', objname, 'to package:', package_name.
        successful = zcl_copy_objects_helper=>create_copy_of_program(
                      data = VALUE #( name             = replace( val = objname sub = 'XX' with = substring_after( sub = 'DEV-' val = CONV string( package_name ) len = 2 ) )
                                      template-name    = objname
                                      package_ref-name = package_name )
                      transport = transp ).
        WRITE: / 'Copying program:', successful.
      WHEN 'T'. " Table
        " Implement table copy logic here
        WRITE: / 'Copying table:', objname, 'to package:', package_name.
        successful = zcl_copy_objects_helper=>create_copy_of_table(
                      data = VALUE #( name             = replace( val = objname sub = 'XX' with = substring_after( sub = 'DEV-' val = CONV string( package_name ) len = 2 ) )
                                      template-name    = objname
                                      package_ref-name = package_name )
                      transport = transp ).
        WRITE: / 'Copying class:', successful.

      WHEN OTHERS.
        WRITE: / 'Unsupported object type:', objtype.
    ENDCASE.
  ENDLOOP.

  CONSTANTS:
    co_package   TYPE sxco_package VALUE 'ZTEST'.

*    DATA(lo_transport_target) = xco_cp_abap_repository=>package->for( co_package
*            )->read(
*            )-property-transport_layer->get_transport_target( ).

  "Get TR
  DATA(lo_transport_request) = xco_cts=>transport->for( '' )->get_request( ).

  DATA(lo_put_operation) = xco_cp_generation=>environment->dev_system( lo_transport_request->value
    )->create_put_operation( ).
