*&---------------------------------------------------------------------*
*& Report ZTEST_CODE_LOGIC
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ztest_code_logic.

TABLES: seoclass, dd02l.

SELECT-OPTIONS: sdate FOR dd02l-as4date DEFAULT sy-datum TO sy-datum,
                stime FOR dd02l-as4time DEFAULT sy-uzeit TO sy-uzeit.

START-OF-SELECTION.
*  DATA: filter      TYPE bal_s_lfil,
*        log_headers TYPE balhdr_t.
*  CALL FUNCTION 'BAL_FILTER_CREATE'
*    EXPORTING
*      i_aldate_from  = sy-datum
*      i_aldate_to    = sy-datum
*      i_altime_from  = '161700'
*      i_altime_to    = '163000'
*    IMPORTING
*      e_s_log_filter = filter.
*
*  CALL FUNCTION 'BAL_DB_SEARCH'
*    EXPORTING
*      i_s_log_filter = filter
*    IMPORTING
*      e_t_log_header = log_headers.
*
*  SELECT * FROM custom_table
*  INTO TABLE @DATA(blacklisted_objects).
*
*  DATA condition TYPE string.
*  LOOP AT blacklisted_objects REFERENCE INTO DATA(blacklisted_object).
*
*    condition = SWITCH #( blacklisted_object->subobject
*                  WHEN space THEN |object { blacklisted_object->object_option } '{ blacklisted_object->object }'|
*                  ELSE |object { blacklisted_object->object_option } '{ blacklisted_object->object }' | &
*                    |AND subobject { blacklisted_object->subobject_option } '{ blacklisted_object->subobject }'| ).
*
*    DELETE log_headers WHERE (condition).
*  ENDLOOP.

  TRY.
      DATA(db_system) = cl_db6_sys=>get_sys_ref( cl_db6_sys=>local_sysid ).
      DATA(dba_rdi) = cl_dba_rdi=>get_instance( db_system ).

      dba_rdi->query->get_history( EXPORTING collector = cl_hdb_rdi_meta=>co_pfx_col_tab_part_size
                                   IMPORTING to_date   = DATA(to_date)
                                             to_time   = DATA(to_time) ).
      dba_rdi->query->reset( ).
      dba_rdi->query->set_history( from_date = sdate-low
                                   from_time = stime-low
                                   to_date   = sdate-high
                                   to_time   = stime-high ).

      dba_rdi->query->set_filter_from_range_tab( ddic_field = 'SCHEMA_NAME'
                                                 range_tab  = VALUE hdb_range_tab( ( sign = 'I' option = 'EQ' low = 'SAPABAP' ) ) ).
      dba_rdi->query->set_top_n( 500 ). "Set maximum records

      DATA column_table_sizes TYPE hdb_column_tables_part_sizetab.
      dba_rdi->query->get_snapshot( EXPORTING ddic_src = cl_hdb_rdi_meta=>co_ddic_column_tables_part_siz
                                    IMPORTING data     = column_table_sizes ).

      dba_rdi->query->reset( ).

*      dba_rdi->query->get_history( EXPORTING collector = cl_hdb_rdi_meta=>co_pfx_col_tab_part_size
*                                   IMPORTING to_date   = to_date
*                                             to_time   = to_time ).
      dba_rdi->query->reset( ).
      dba_rdi->query->set_history( from_date = sdate-low
                                   from_time = stime-low
                                   to_date   = sdate-high
                                   to_time   = stime-high ).

      dba_rdi->query->set_filter_from_range_tab( ddic_field = 'SCHEMA_NAME'
                                                 range_tab  = VALUE hdb_range_tab( ( sign = 'I' option = 'EQ' low = 'SAPABAP' ) ) ).

      DATA rowstore_table_sizes TYPE hdb_globl_rowstore_tabl_sz_tab.
      dba_rdi->query->get_snapshot( EXPORTING ddic_src = cl_hdb_rdi_meta=>co_ddic_global_rowstore_tbl_sz
                                    IMPORTING data     = rowstore_table_sizes ).

      dba_rdi->query->reset( ).

*      dba_rdi->query->get_history( EXPORTING collector = cl_hdb_rdi_meta=>co_pfx_col_tab_part_size
*                                   IMPORTING to_date   = to_date
*                                             to_time   = to_time ).
      dba_rdi->query->reset( ).
      dba_rdi->query->set_history( from_date = sdate-low
                                   from_time = stime-low
                                   to_date   = sdate-high
                                   to_time   = stime-high ).

      dba_rdi->query->set_filter_from_range_tab( ddic_field = 'SCHEMA_NAME'
                                                 range_tab  = VALUE hdb_range_tab( ( sign = 'I' option = 'EQ' low = 'SAPABAP' ) ) ).

      DATA disk_table_size TYPE hdb_globl_tab_persist_stat_tab.
      dba_rdi->query->get_snapshot( EXPORTING ddic_src = cl_hdb_rdi_meta=>co_ddic_glob_persistence_stat
                                    IMPORTING data     = disk_table_size ).

*        LOOP AT table_sizes REFERENCE INTO DATA(table_size).
*          IF line_exists( disk_table_sizes[ table_name = table_size->table_name ] ).
*            table_size->disk_gb = get_value_in_gb( CONV #( disk_table_sizes[ table_name = table_size->table_name ]-disk_size ) ).
*          ENDIF.
*        ENDLOOP.
*      dba_rdi->query->reset( ).
*
*      DATA db_sql_workload TYPE hdb_m_workload_tab.
*      dba_rdi->query->get_snapshot( EXPORTING ddic_src = cl_hdb_rdi_meta=>co_ddic_hdb_workload
*                                    IMPORTING data = db_sql_workload ).
*
*      dba_rdi->query->reset( ).
*
**      dba_rdi->query->get_history( EXPORTING collector = cl_hdb_rdi_meta=>co_pfx_col_tab_part_size
**                                   IMPORTING to_date   = to_date
**                                             to_time   = to_time ).
*      dba_rdi->query->reset( ).
*      dba_rdi->query->set_history( from_date = sdate-low
*                                   from_time = stime-low
*                                   to_date   = sdate-high
*                                   to_time   = stime-high ).
*
*      DATA expensive_statements TYPE hdb_m_expensive_statements_tab.
*      dba_rdi->query->get_snapshot( EXPORTING ddic_src = cl_hdb_rdi_meta=>co_ddic_m_expensive_statements
*                                    IMPORTING data = expensive_statements ).
*
*      dba_rdi->query->reset( ).
*
*      DATA sql_plan_cache TYPE hdb_m_sql_plan_cache_tab.
*      dba_rdi->query->get_snapshot( EXPORTING ddic_src = cl_hdb_rdi_meta=>co_ddic_m_sql_plan_cache
*                                    IMPORTING data     = sql_plan_cache ).
*    CATCH cx_db6_sys cx_dba_rdi cx_dba_adbc INTO DATA(exception).
*
*  ENDTRY.
*
*  TRY.
*      NEW cl_hdb_adbc( cl_hdb_adbc=>get_local_dbcon_name( ) )->get_db_size_history(
*        IMPORTING
*          itab  =  DATA(hana_db_size_history)
**      count =
*      ).
    CATCH cx_dba_adbc.

  ENDTRY.

  DATA queue_statuses TYPE RANGE OF arfcsstate-arfcstate.
  CONSTANTS: sign_include TYPE char1 VALUE 'I',
             option_equal TYPE char2 VALUE 'EQ'.
  "Error status
  queue_statuses[] = VALUE #(
  ( sign = sign_include option = option_equal  low = 'CPICERR' )
  ( sign = sign_include option = option_equal  low = 'SYSFAIL' )
  ( sign = sign_include option = option_equal  low = 'STOP' )
  ( sign = sign_include option = option_equal  low = 'ANORETRY' )
  ( sign = sign_include option = option_equal  low = 'WAITSTOP' )
  ( sign = sign_include option = option_equal  low = 'ARETRY' )
  ( sign = sign_include option = option_equal  low = 'RETRY' )
  ( sign = sign_include option = option_equal  low = 'SYSLOAD' ) ).

  SELECT * FROM trfcqin
    INTO TABLE @DATA(inbound_queues)
      WHERE qstate IN @queue_statuses
        AND ( ( qrfcdatum BETWEEN @sdate-low AND @sdate-high AND qrfcuzeit BETWEEN @stime-low AND @stime-high )
              OR ( qrfcdatum < @sdate-low AND qrfcdatum > @sdate-high AND qrfcuzeit BETWEEN @stime-low AND @stime-high ) )
        OR ( ( retrydate BETWEEN @sdate-low AND @sdate-high AND retrytime BETWEEN @stime-low AND @stime-high )
              OR ( retrydate < @sdate-low AND retrydate > @sdate-high AND retrytime BETWEEN @stime-low AND @stime-high ) ).

  SELECT * FROM trfcqout
    INTO TABLE @DATA(outbound_queues)
      WHERE qstate IN @queue_statuses
        AND ( ( qrfcdatum BETWEEN @sdate-low AND @sdate-high AND qrfcuzeit BETWEEN @stime-low AND @stime-high )
              OR ( qrfcdatum < @sdate-low AND qrfcdatum > @sdate-high AND qrfcuzeit BETWEEN @stime-low AND @stime-high ) ).

  TRY.
      TRY.
          DATA(erp_ctrl) = CAST /scwm/if_erp_ctrlprocs( /scdl/cl_af_management=>get_instance( )->get_service( /scwm/if_erp_ctrlprocs=>sc_service ) ).

          DATA warehouses TYPE /scwm/tt_t300.
          CALL FUNCTION '/SCWM/T300_READ_MULTI'
            EXPORTING
              it_lgnum = VALUE /scwm/tt_rsdsselopt( )
            IMPORTING
              et_t300  = warehouses
*             ET_T300T =
*           EXCEPTIONS
*             NOT_FOUND       = 1
*             OTHERS   = 2
            .

          DATA logical_systems TYPE /scwm/cl_mq_services=>yt_logsysrfc.
          LOOP AT warehouses REFERENCE INTO DATA(warehouse).
            NEW /scwm/cl_mq_services( )->get_erp_systems(
              EXPORTING
                iv_whno    = warehouse->lgnum
              IMPORTING
                et_systems = DATA(warehouse_logical_systems) ).

            INSERT LINES OF warehouse_logical_systems INTO TABLE logical_systems.
          ENDLOOP.

          DELETE ADJACENT DUPLICATES FROM logical_systems.
          LOOP AT logical_systems REFERENCE INTO DATA(logical_system).
*        Skip It If The Connected ERP System is S74HANA CE
            IF erp_ctrl->select_by_bskey_single( iv_erpbskey = logical_system->bskey )-is_cloud = abap_true.
              DELETE logical_systems FROM logical_system->*.
            ENDIF.

* Check If This Is A Local System (To Avoid Rfc Authorization Checks)
            IF NEW /scwm/cl_mq_services( )->check_is_local_system( iv_logsys = logical_system->logsys ) = abap_true.
              CONTINUE.
            ELSE.
* check if authorization exists and if destination exists.
* just use a dummy queue name. The call is only to check if the call is
* possible and not to get a real result.
              CALL FUNCTION 'TRFC_GET_QINS_INFO_DETAILS'
                DESTINATION logical_system->rfcdest
                EXPORTING
                  qname                 = 'YYZZWW'
                EXCEPTIONS
                  communication_failure = 1
                  system_failure        = 2
                  OTHERS                = 3.
* handle error message, so that a warning is issued that ERP can not be accessed

              IF sy-subrc <> 0.
                DELETE logical_systems FROM logical_system->*.
              ENDIF.
            ENDIF.
          ENDLOOP.
        CATCH /scdl/cx_af_management INTO DATA(lc_af_management).
          MESSAGE  lc_af_management->get_text( ) TYPE 'S' DISPLAY LIKE 'S'.
      ENDTRY.

      /scwm/cl_mq_manager=>get_instance( )->get_queues(
        EXPORTING
          it_logsys           = VALUE #( FOR logical_syst IN logical_systems ( logical_syst-logsys ) )
          iv_inb              = abap_true
          iv_outb             = abap_true
          iv_read_log_message = abap_true
        IMPORTING
          et_queues           = DATA(ewm_queues) ).

      TYPES: BEGIN OF ewm_message,
               busobj      TYPE  /scwm/de_mq_busobj,
               errmess     TYPE  natxt,
               msgid       TYPE  symsgid,
               msgno(3),")       TYPE  symsgno,
               qstate      TYPE  /scwm/de_mq_qrfcstate,
               product(10),
             END OF ewm_message.
      DATA ewm_messages TYPE STANDARD TABLE OF ewm_message.

      ewm_messages = VALUE #( ( busobj = 'Goods Movement'
                                msgid = 'M7'
                                msgno = '0*'
                                errmess = '*'
                                qstate = '*'
                                product = 'MM' )
                              ( busobj = 'Goods Movement'
                               msgid = 'M7'
                               msgno = '520'
                               errmess = '*'
                               qstate = '*'
                               product = 'MM' ) ).

      DELETE ewm_queues WHERE busobj NOT IN VALUE piq_selopt_t( FOR ewm_msg IN ewm_messages ( sign = 'I' option = 'CP' low = ewm_msg-busobj ) )
                          OR msgid NOT IN VALUE piq_selopt_t( FOR ewm_msg IN ewm_messages ( sign = 'I' option = 'CP' low = ewm_msg-msgid ) )
                          OR msgno NOT IN VALUE piq_selopt_t( FOR ewm_msg IN ewm_messages ( sign = 'I' option = 'CP' low = ewm_msg-msgno ) )
                          OR errmess NOT IN VALUE piq_selopt_t( FOR ewm_msg IN ewm_messages ( sign = 'I' option = 'CP' low = ewm_msg-errmess ) )
                          OR qstate NOT IN VALUE piq_selopt_t( FOR ewm_msg IN ewm_messages ( sign = 'I' option = 'CP' low = ewm_msg-qstate ) ).

      DATA(queue_list) = VALUE /scwm/tt_mq_queue_enriched(
                            FOR inbound_queue IN inbound_queues
                            FOR ewm_queue IN ewm_queues
                              WHERE ( tid = |{ inbound_queue-arfcipid }{ inbound_queue-arfcpid }{ inbound_queue-arfctime }{ inbound_queue-arfctidcnt }| )
                            ( CORRESPONDING #( BASE ( CORRESPONDING #( inbound_queue ) ) ewm_queue ) ) ).

    CATCH /scwm/cx_mq_manager.


  ENDTRY.

  WRITE 'test'.

*  DATA: expensive_statements TYPE hdb_m_expensive_statements_tab.
*  DATA(results) = VALUE custom_table( FOR s4_cache IN expensive_statements
*                            ( VALUE custom_table( BASE CORRESPONDING #( s4_cache MAPPING rows_processed = records
*                                                                                                     elapsed_time   = duration_microsec
*                                                                                                     wait_time      = lock_wait_duration )
*                                                              database_name = 'S4HANA'
*                                                              table_names   = shift_left( translate( val =  s4_cache-object_name from = `SAPABAP.` to = space ) )
*                                                              sql_fulltext  = shift_left( translate( val =  s4_cache-statement_string from = `"` to = space ) )
*                                                              ) ) ).
