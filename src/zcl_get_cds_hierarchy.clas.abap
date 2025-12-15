CLASS zcl_get_cds_hierarchy DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA:
      sqlview_name TYPE string.
    METHODS:
      get_number_of_hierarchy_levels
        IMPORTING
                  node          TYPE cl_ddls_dependency_visitor=>ty_s_dependency_graph_node
        RETURNING VALUE(levels) TYPE i,
      get_basic_view_sqlview_name
        IMPORTING
                  node        TYPE cl_ddls_dependency_visitor=>ty_s_dependency_graph_node
        RETURNING VALUE(view) TYPE string,
      get_field_mappings
        IMPORTING material           TYPE /bmw/otd3037_wl
        RETURNING VALUE(mapped_data) TYPE cl_api_product_dpc_ext=>ty_s_product_struc.
ENDCLASS.

CLASS zcl_get_cds_hierarchy IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    DATA(dependency_visitor) = NEW cl_ddls_dependency_visitor( ).
    dependency_visitor->compute_dependency_information( to_upper( 'A_Product' ) ).
    DATA(sqlview_name) = get_basic_view_sqlview_name( dependency_visitor->get_dependency_graph( ) ).
    NEW cl_ddic_table_information( )->if_ddic_table_information~get_fields_of_table( EXPORTING iv_field_name = CONV #( sqlview_name )
                                                                                     IMPORTING et_fields = DATA(fields) ).


  ENDMETHOD.

  METHOD get_number_of_hierarchy_levels.
    CHECK node-children IS BOUND.
    DATA(children) = CORRESPONDING cl_ddls_dependency_visitor=>ty_t_dependency_graph_nodes( node-children->* ).
    levels = get_number_of_hierarchy_levels( children[ 1 ] ) + 1.
  ENDMETHOD.

  METHOD get_basic_view_sqlview_name.
    CHECK node-children IS BOUND.
    DATA(children) = CORRESPONDING cl_ddls_dependency_visitor=>ty_t_dependency_graph_nodes( node-children->* ).
    view = COND #( WHEN children[ 1 ]-type = cl_ddls_dependency_visitor=>co_node_type-table THEN node-name
                    ELSE get_basic_view_sqlview_name( node = children[ 1 ] ) ).
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

*    LOOP AT mappings INTO DATA(mapping).
*      ASSIGN COMPONENT mapping-abap OF STRUCTURE material TO FIELD-SYMBOL(<material>).
*      CHECK sy-subrc = 0.
*
*      ASSIGN COMPONENT mapping-json OF STRUCTURE mapped_data TO FIELD-SYMBOL(<mapped_data>).
*      <mapped_data> = <material>.
*    ENDLOOP.
*
*    IF cl_abap_typedescr=>describe_by_data( material_api_data )->type_kind = cl_abap_typedescr=>typekind_table.
*      FIELD-SYMBOLS <api_data_table> TYPE ANY TABLE.
*      ASSIGN material_api_data TO <api_data_table>.
*      DATA line_of_data TYPE REF TO data.
*      CREATE DATA line_of_data LIKE LINE OF <api_data_table>.
*      ASSIGN line_of_data->* TO FIELD-SYMBOL(<api_data>).
*      INSERT INITIAL LINE INTO TABLE <api_data_table> ASSIGNING <api_data>.
*    ELSE.
*      ASSIGN material_api_data TO <api_data>.
*    ENDIF.
*
*    LOOP AT fields INTO DATA(field_mapping).
*      IF field_mapping-rollname = 'MATNR'.
*        ASSIGN COMPONENT 'Product' OF STRUCTURE data->* TO FIELD-SYMBOL(<source>).
*      ELSE.
*        ASSIGN COMPONENT field_mapping-rollname OF STRUCTURE data->* TO <source>.
*      ENDIF.
*
*      CHECK sy-subrc = 0.
*      ASSIGN COMPONENT field_mapping-fieldname OF STRUCTURE <api_data> TO FIELD-SYMBOL(<target>).
*
*      CHECK sy-subrc = 0.
*      <target> = <source>.
*    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
