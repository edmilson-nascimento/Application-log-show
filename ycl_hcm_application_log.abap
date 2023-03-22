
CLASS ycl_hcm_application_log DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CONSTANTS:
      BEGIN OF ty_log,
        object    TYPE bal_s_log-object VALUE 'YHCM',
        subobject TYPE bal_s_log-subobject VALUE 'YHCM0001',
        alprog    TYPE bal_s_log-alprog VALUE 'YHCM0012',
      END OF ty_log,
      BEGIN OF message,
        id TYPE bapiret2-id VALUE 'ZHCM',
      END OF message .

    TYPES:
      BEGIN OF ty_header_log,
        title     TYPE bal_s_log-extnumber,
        object    TYPE bal_s_log-object,
        subobject TYPE bal_s_log-subobject,
        alprog    TYPE bal_s_log-alprog,
        handle    TYPE balloghndl,
        lognumber TYPE balognr,
      END OF ty_header_log .
    "! <p class="shorttext synchronized" lang="pt">Recebe info iniciais</p>
    METHODS constructor
      IMPORTING
        !iv_title     TYPE bal_s_log-extnumber
        !iv_object    TYPE bal_s_log-object    DEFAULT 'YHCM'
        !iv_subobject TYPE bal_s_log-subobject DEFAULT 'YHCM0001'
        !iv_alprog    TYPE bal_s_log-alprog .
    "! <p class="shorttext synchronized" lang="pt">Adiciona mensagens do tipo BAPIRET1</p>
    METHODS add_bapiret1
      IMPORTING
        !is_message TYPE bapiret1 .
    "! <p class="shorttext synchronized" lang="pt">Adiciona mensagens do tipo BAPIRET2</p>
    METHODS add_bapiret2
      IMPORTING
        !message TYPE bapiret2 .
    "! <p class="shorttext synchronized" lang="pt">Salva os dados que foram adicionados anteriormente</p>
    METHODS save .
    "! <p class="shorttext synchronized" lang="pt">Exibe mensagens de log</p>
    METHODS show .

    "! <p class="shorttext synchronized" lang="pt">Exibe mensagens de log (salvos)</p>
    CLASS-METHODS show_saved
      IMPORTING
        !log_numbers TYPE bal_t_logn
        !option      TYPE i DEFAULT 0 .
    "! <p class="shorttext synchronized" lang="pt">Retorna o numero do log</p>
    METHODS get_lognumber
      RETURNING
        VALUE(result) TYPE balognr .

    CLASS-METHODS save_single
      IMPORTING
        !is_header    TYPE ty_header_log
        !is_message   TYPE bapiret1
      RETURNING
        VALUE(result) TYPE balognr .
    "! <p class="shorttext synchronized" lang="pt">Retorna nro do Log apos salvar os dados da tabela passada</p>
    CLASS-METHODS save_bapiret2_tab
      IMPORTING
        !is_header    TYPE ty_header_log
        !it_message   TYPE bapiret2_t
      RETURNING
        VALUE(result) TYPE balognr .
    "! <p class="shorttext synchronized" lang="pt">Retorna as mensagens de acordo com o numero passado</p>
    CLASS-METHODS get_log_bapiret2
      IMPORTING
        !is_log_number TYPE balognr
      RETURNING
        VALUE(result)  TYPE bapiret2_t .

  PROTECTED SECTION.

  PRIVATE SECTION.

    DATA:
      gs_header TYPE ty_header_log .

    METHODS create .

    METHODS set_lognumber
      IMPORTING
        !iv_lognumber TYPE balognr .

    METHODS add
      IMPORTING
        !is_message TYPE bal_s_msg .

ENDCLASS.


CLASS ycl_hcm_application_log IMPLEMENTATION.


  METHOD constructor .

    me->gs_header = VALUE ty_header_log(
      title     = iv_title
      object    = iv_object
      subobject = iv_subobject
      alprog    = iv_alprog
    ).

    me->create( ) .

  ENDMETHOD.


  METHOD add_bapiret1 .

    IF ( is_message IS INITIAL ) .
      RETURN .
    ENDIF .

    DATA(bal_message) = VALUE bal_s_msg(
      msgty     = is_message-type
      msgid     = is_message-id
      msgno     = is_message-number
      msgv1     = is_message-message_v1
      msgv2     = is_message-message_v2
      msgv3     = is_message-message_v3
      msgv4     = is_message-message_v4 ) .

    me->add( bal_message ) .

  ENDMETHOD .


  METHOD add_bapiret2 .

    IF ( message IS INITIAL ) .
      RETURN .
    ENDIF .

    DATA(bal_message) =
      cl_rmps_trf_service=>convert_bapiret2_to_balmsg( is_bapiret2 = message  ).
    IF ( bal_message IS INITIAL ) .
      RETURN .
    ENDIF .

    me->add( bal_message ) .

  ENDMETHOD.


  METHOD save.

    DATA:
      lt_lognumbers TYPE bal_t_lgnm.

    IF ( me->gs_header-handle IS INITIAL ) .
      RETURN .
    ENDIF .

    DATA(lt_handles) = VALUE bal_t_logh( ( me->gs_header-handle ) ).

    CALL FUNCTION 'BAL_DB_SAVE_PREPARE'
      EXPORTING
        i_replace_in_all_logs = abap_on
*       i_t_replace_in_these_logs     =
*       i_t_replace_message_variables =
*       i_t_replace_context_fields    =
      EXCEPTIONS
        log_not_found         = 1
        OTHERS                = 2.

    IF ( sy-subrc NE 0 ) .
      RETURN .
    ENDIF .


    CALL FUNCTION 'BAL_DB_SAVE'
      EXPORTING
        i_client         = sy-mandt
*       i_in_update_task = space
*       i_save_all       = lv_save_all
        i_t_log_handle   = lt_handles
*       i_2th_connection = space
*       i_2th_connect_commit = space
*       i_link2job       = 'x'
      IMPORTING
        e_new_lognumbers = lt_lognumbers
*       e_second_connection  =
      EXCEPTIONS
        log_not_found    = 1
        save_not_allowed = 2
        numbering_error  = 3
        OTHERS           = 4.

    IF ( sy-subrc EQ 0 ) .
      me->gs_header-lognumber = VALUE #(
        lt_lognumbers[ 1 ]-lognumber OPTIONAL ) .
    ENDIF.

  ENDMETHOD.


  METHOD show.

    DATA:
      lt_handles         TYPE bal_t_logh,
      ls_display_profile TYPE bal_s_prof.

    " Get standard display profile
    CALL FUNCTION 'BAL_DSP_PROFILE_SINGLE_LOG_GET'
      IMPORTING
        e_s_display_profile = ls_display_profile
      EXCEPTIONS
        OTHERS              = 1.
    IF ( sy-subrc NE 0 ) .
      RETURN.
    ENDIF.

    CALL FUNCTION 'BAL_DSP_LOG_DISPLAY'
      EXPORTING
        i_s_display_profile = ls_display_profile
        i_t_log_handle      = lt_handles.

  ENDMETHOD.


  METHOD show_saved.

    DATA:
      lt_log_handle TYPE bal_t_logh,
      lt_msg_handle TYPE bal_t_msgh.
    DATA g_t_log_header TYPE balhdr_t .

**    IF ( is_log_number IS INITIAL ) .
**      RETURN .
**    ENDIF .
*
**    data(lognumbers) = value SZAL_LOGNUMBERS(
**      ( item = is_log_number )
**    ).
*    DATA(lognumber) = VALUE bal_r_logn(
*      ( sign   = if_fsbp_const_range=>sign_include
*        option = if_fsbp_const_range=>option_equal
*        low    = is_log_number )
*    ).


    IF ( lines( log_numbers ) EQ 0 ) .
      RETURN .
    ENDIF .

    DATA(log_filter) = VALUE bal_s_lfil( lognumber = log_numbers ) .

*    g_r_object-sign   = 'I'.
*    g_r_object-option = 'EQ'.
*    g_r_object-low    = const_object_flight_invoice.
*    APPEND g_r_object TO g_s_log_filter-object.
*    g_r_extnumber-sign   = 'I'.
*    g_r_extnumber-option = 'EQ'.
*    g_r_extnumber-low    = p_fldate.
*    APPEND g_r_extnumber TO g_s_log_filter-extnumber.


*   search on DB for these logs
    CALL FUNCTION 'BAL_DB_SEARCH'
      EXPORTING
*       i_s_log_filter = g_s_log_filter
        i_s_log_filter = log_filter
      IMPORTING
        e_t_log_header = g_t_log_header
      EXCEPTIONS
        OTHERS         = 0.
*   load logs from DB
    CALL FUNCTION 'BAL_DB_LOAD'
      EXPORTING
        i_t_log_header = g_t_log_header
      EXCEPTIONS
        OTHERS         = 0.


    DATA l_s_display_profile TYPE bal_s_prof .

    l_s_display_profile-disvariant-report = sy-repid.
* when you use also other ALV lists in your report,
* please specify a handle to distinguish between the display
* variants of these different lists, e.g:
    l_s_display_profile-disvariant-handle = 'LOG'.

    CALL FUNCTION 'BAL_DSP_LOG_DISPLAY'
      EXPORTING
        i_s_display_profile = l_s_display_profile
      EXCEPTIONS
        OTHERS              = 1.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.


  ENDMETHOD.


  METHOD get_lognumber .

    IF ( me->gs_header IS INITIAL ) .
      RETURN .
    ENDIF .

    result = me->gs_header-lognumber .

  ENDMETHOD .


  METHOD save_single .

    IF ( is_header IS INITIAL ) .
      RETURN .
    ENDIF .

    IF ( is_message IS INITIAL ) .
      RETURN .
    ENDIF.

    DATA(lo_app) =
      NEW ycl_hcm_application_log( iv_title     = is_header-title
                                   iv_object    = is_header-object
                                   iv_subobject = is_header-subobject
                                   iv_alprog    = is_header-alprog ) .

    IF ( lo_app IS BOUND ) .
      lo_app->add_bapiret1( is_message ) .
      lo_app->save( ) .
      result = lo_app->get_lognumber( ).
    ENDIF .

    FREE lo_app .

  ENDMETHOD .


  METHOD save_bapiret2_tab .

    IF ( is_header IS INITIAL ) .
      RETURN .
    ENDIF .

    IF ( it_message IS INITIAL ) .
      RETURN .
    ENDIF.

    DATA(lo_app) =
      NEW ycl_hcm_application_log( iv_title     = is_header-title
                                   iv_object    = is_header-object
                                   iv_subobject = is_header-subobject
                                   iv_alprog    = is_header-alprog ) .
    IF ( lo_app IS BOUND ) .
      LOOP AT it_message INTO DATA(ls_message) .
        lo_app->add_bapiret2( ls_message ) .
      ENDLOOP.
      lo_app->save( ) .
      result = lo_app->get_lognumber( ).
      FREE lo_app .
    ENDIF .

  ENDMETHOD .


  METHOD get_log_bapiret2 .

    DATA:
      lognumbers_filter TYPE STANDARD TABLE OF szal_lognumber,
      saved_messages    TYPE STANDARD TABLE OF balm.

    IF ( is_log_number IS INITIAL ) .
      RETURN .
    ENDIF .

    lognumbers_filter = VALUE #( ( item = is_log_number ) ) .

    CALL FUNCTION 'APPL_LOG_READ_DB_WITH_LOGNO'
      TABLES
        lognumbers = lognumbers_filter
        messages   = saved_messages.

    IF ( lines( saved_messages ) GT 0 ) .

      result = VALUE bapiret2_t(
        FOR l IN saved_messages (
          type       = l-msgty
          id         = l-msgid
          number     = l-msgno
          message_v1 = l-msgv1
          message_v2 = l-msgv2
          message_v3 = l-msgv3
          message_v4 = l-msgv4
      ) ) .


    ENDIF .

  ENDMETHOD .


  METHOD create.

    DATA(ls_log) = VALUE bal_s_log(
      extnumber  = me->gs_header-title
      object     = me->gs_header-object
      subobject  = me->gs_header-subobject
      aldate     = sy-datum
      altime     = sy-uzeit
      aluser     = sy-uname
      altcode    = sy-tcode
      alprog     = me->gs_header-alprog
      del_before = abap_on ) .

    CALL FUNCTION 'BAL_LOG_CREATE'
      EXPORTING
        i_s_log                 = ls_log
      IMPORTING
        e_log_handle            = me->gs_header-handle
      EXCEPTIONS
        log_header_inconsistent = 1
        OTHERS                  = 2.
    IF ( sy-subrc NE 0 ) .
      RETURN .
    ENDIF .

    CALL FUNCTION 'BAL_DB_LOGNUMBER_GET'
      EXPORTING
        i_log_handle = me->gs_header-handle
      IMPORTING
        e_lognumber  = me->gs_header-lognumber.

  ENDMETHOD.


  METHOD set_lognumber .

    IF ( iv_lognumber IS NOT INITIAL ) .
      me->gs_header-lognumber = iv_lognumber .
    ENDIF .

  ENDMETHOD .


  METHOD add .

    IF ( me->gs_header-handle IS INITIAL ) .
      RETURN.
    ENDIF .

    IF ( is_message IS INITIAL ) .
      RETURN.
    ENDIF .

    CALL FUNCTION 'BAL_LOG_MSG_ADD'
      EXPORTING
        i_log_handle = me->gs_header-handle
        i_s_msg      = is_message.

  ENDMETHOD.




ENDCLASS.

