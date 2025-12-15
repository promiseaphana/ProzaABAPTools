*&---------------------------------------------------------------------*
*& Report ZCREATE_PACKAGE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zcreate_package.

CLASS packager DEFINITION.
  PUBLIC SECTION.
    METHODS: create_package
      IMPORTING
        parent    TYPE tdevc-devclass
        count     TYPE numc2
        transport TYPE trkorr
      CHANGING
        package   TYPE scompkdtln.
ENDCLASS.

CLASS packager IMPLEMENTATION.

  METHOD create_package.
    cl_package_factory=>create_new_package(
      EXPORTING
        i_suppress_dialog       = abap_false
      IMPORTING
        e_package               = DATA(package_instance)
      CHANGING
        c_package_data          = package
      EXCEPTIONS
        object_already_existing = 1
        object_just_created     = 2
        not_authorized          = 3
        wrong_name_prefix       = 4
        undefined_name          = 5
        reserved_local_name     = 6
        invalid_package_name    = 7
        layer_invalid           = 10
        author_not_existing     = 11
        prefix_in_use           = 14
        unexpected_error        = 15
        intern_err              = 16
        no_access               = 17
        OTHERS                  = 18
    ).

    "Save the package, no need to activate it in prio 7.10 releases
    package_instance->save(
      EXPORTING
        i_suppress_dialog     = abap_false
        i_transport_request   = transport
      EXCEPTIONS
        object_invalid        = 1
        object_not_changeable = 2
        cancelled_in_corr     = 3
        permission_failure    = 4
        unexpected_error      = 5
        intern_err            = 6
        OTHERS                = 7 ).

    IF substring_after( sub = 'UC' val = package-devclass ) < 40.
      DATA(package_data) = VALUE scompkdtln(
                             devclass   = |{ parent }-UC{ count                     ALPHA = IN }|
                             ctext      = |Development Package for Use Case { count ALPHA = IN }|
                             language   = 'E'
                             masterlang = 'E'
                             as4user    = sy-uname " SET the system as responsible
                             created_by = sy-uname
                             parentcl   = parent  " super/parent package
                             dlvunit    = 'HOME'
                             pdevclass  = ''
                             korrflag   = abap_true
      ).

      create_package(
        EXPORTING
          parent    = parent
          count     = CONV #( count + 1 )
          transport = transport
        CHANGING
          package   = package_data
      ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
" Main Program
PARAMETERS: parent  TYPE tdevc-devclass,
            target  TYPE devclass,
            trans   TYPE trkorr,
            counter TYPE numc2.

START-OF-SELECTION.

  DATA count TYPE numc2.
  DO counter TIMES.
    count += 1.
    DATA(package_data) = VALUE scompkdtln(
                          devclass   = |{ target }{ count                         ALPHA = IN }|
                          ctext      = |Development Package for Developer { count ALPHA = IN }|
                          language   = 'E'
                          masterlang = 'E'
                          as4user    = sy-uname " SET the system as responsible
                          created_by = sy-uname
                          parentcl   = parent  " super/parent package
                          dlvunit    = 'HOME'
                          pdevclass  = ''
                          korrflag   = abap_true
    ).

    NEW packager( )->create_package(
      EXPORTING
        parent    = package_data-devclass
        count     = 1
        transport = trans
      CHANGING
        package   = package_data
    ).
  ENDDO.
