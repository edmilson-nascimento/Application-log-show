CLASS /yga/cl_oisu_log DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION .

    METHODS constructor
      IMPORTING
        !iv_object    TYPE balobj_d
        !iv_subobject TYPE balsubobj .
    METHODS create
      IMPORTING
        !iv_extnumber TYPE balnrext .
    METHODS add
      IMPORTING
        !it_message TYPE bapiret2_t OPTIONAL
        !is_message TYPE bapiret2 OPTIONAL .
    METHODS save .
    METHODS show
      IMPORTING
        !is_filter TYPE bal_s_lfil OPTIONAL .
    METHODS get
      IMPORTING
        !iv_extnumber TYPE balnrext .

    "! <p class="shorttext synchronized" lang="pt">Adicionar diretamente log</p>
    CLASS-METHODS add_direct
      IMPORTING
        !im_step TYPE char05 .


  PROTECTED SECTION.

  PRIVATE SECTION.

    DATA:
      gt_log_handle    TYPE bal_t_logh,
      me->gv_object    TYPE balobj_d,
      me->gv_subobject TYPE balsubobj,
      me->gv_log_handle    TYPE balloghndl.

    "! <p class="shorttext synchronized" lang="pt">Criar diretamente mensagem de log</p>
    CLASS-METHODS create_direct
      IMPORTING
        !im_message TYPE bapiret2_t .


ENDCLASS.



CLASS /yga/cl_oisu_log IMPLEMENTATION.


  METHOD add.

    IF it_message[] IS NOT INITIAL.

      LOOP AT it_message INTO DATA(ls_message).

        DATA(ls_msg) = VALUE bal_s_msg( msgty = ls_message-type
                                        msgid = ls_message-id
                                        msgno = ls_message-number
                                        msgv1 = ls_message-message_v1
                                        msgv2 = ls_message-message_v2
                                        msgv3 = ls_message-message_v3
                                        msgv4 = ls_message-message_v4 ).

        CALL FUNCTION 'BAL_LOG_MSG_ADD'
          EXPORTING
            i_s_msg          = ls_msg
            i_log_handle     = me->gv_log_handle
          EXCEPTIONS
            log_not_found    = 1
            msg_inconsistent = 2
            log_is_full      = 3
            OTHERS           = 4.

        IF ( sy-subrc NE 0
        AND sy-msgty IS NOT INITIAL.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
             WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

      ENDLOOP.

    ELSEIF is_message IS NOT INITIAL.

      ls_msg = VALUE bal_s_msg( msgty = is_message-type
                                msgid = is_message-id
                                msgno = is_message-number
                                msgv1 = is_message-message_v1
                                msgv2 = is_message-message_v2
                                msgv3 = is_message-message_v3
                                msgv4 = is_message-message_v4 ).

      CALL FUNCTION 'BAL_LOG_MSG_ADD'
        EXPORTING
          i_s_msg          = ls_msg
          i_log_handle     = me->gv_log_handle
        EXCEPTIONS
          log_not_found    = 1
          msg_inconsistent = 2
          log_is_full      = 3
          OTHERS           = 4.

      IF ( sy-subrc NE 0
      AND sy-msgty IS NOT INITIAL.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
           WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

    ENDIF.

  ENDMETHOD.


  METHOD constructor.

    me->gv_object    = iv_object.
    me->gv_subobject = iv_subobject.

  ENDMETHOD.


  METHOD create.

    CLEAR:
      me->gv_log_handle, gt_log_handle .

    DATA(ls_s_log) = VALUE bal_s_log( aluser    = sy-uname
                                      alprog    = sy-repid
                                      object    = me->gv_object
                                      subobject = me->gv_subobject
                                      extnumber = iv_extnumber ).

*    " definir data de expiração do log
*    zcl_ca_fixed_value=>get_value( EXPORTING  i_zarea       = '04'
*                                              i_zprocesso   = '/YGA/LOGS_SLG0'
*                                              i_campo       = 'ALDATE_DEL'
*                                              i_zocorrencia = 1
*                                              i_zcontador   = 1
*                                   IMPORTING  e_val_min     = DATA(lv_aldate_del)
*                                   EXCEPTIONS no_data       = 1
*                                              OTHERS        = 2 ).
*    IF ( sy-subrc EQ 0.
*      ls_s_log-aldate_del = sy-datum + lv_aldate_del.
*    ELSE.
*      ls_s_log-aldate_del = sy-datum + 365.
*    ENDIF.
*    "definir se o log pode ser eliminado antes de atingir a data de expiração
*    zcl_ca_fixed_value=>get_value( EXPORTING  i_zarea       = '04'
*                                              i_zprocesso   = '/YGA/LOGS_SLG0'
*                                              i_campo       = 'DEL_BEFORE'
*                                              i_zocorrencia = 1
*                                              i_zcontador   = 1
*                                   IMPORTING  e_val_min     = DATA(lv_del_before)
*                                   EXCEPTIONS no_data       = 1
*                                              OTHERS        = 2 ).
*    IF ( sy-subrc EQ 0.
*      ls_s_log-del_before = lv_del_before.
*    ENDIF.

    ls_s_log-aldate_del = sy-datum + 30 .
    ls_s_log-del_before = abap_on .

    CALL FUNCTION 'BAL_LOG_CREATE'
      EXPORTING
        i_s_log                 = ls_s_log
      IMPORTING
        e_log_handle            = me->gv_log_handle
      EXCEPTIONS
        log_header_inconsistent = 1
        error_message           = 2
        OTHERS                  = 3.

    IF ( sy-subrc NE 0.
      IF ( sy-msgty IS NOT INITIAL.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
           WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
    ELSE.
      APPEND me->gv_log_handle TO gt_log_handle.
    ENDIF.

  ENDMETHOD.


  METHOD get.

    DATA: lt_log_header   TYPE balhdr_t,
          lt_log_handle   TYPE bal_t_logh,
          lt_log_messages TYPE bal_t_msgr,
          lr_object       TYPE bal_r_obj,
          lr_extnumber    TYPE bal_r_extn,
          lr_subobject    TYPE bal_r_sub.
    " definir EXTNUMBER para o filtro de pesquisa
    APPEND INITIAL LINE TO lr_extnumber ASSIGNING FIELD-SYMBOL(<fs_extnumber>).
    <fs_extnumber>-sign   = 'I'.
    <fs_extnumber>-option = 'EQ'.
    <fs_extnumber>-low    = iv_extnumber.
    DATA(ls_log_filter) = VALUE bal_s_lfil( extnumber = lr_extnumber ).

    " definir OBJECT para o filtro de pesquisa
    APPEND INITIAL LINE TO lr_object ASSIGNING FIELD-SYMBOL(<fs_object>).
    <fs_object>-sign   = 'I'.
    <fs_object>-option = 'EQ'.
    <fs_object>-low    = me->gv_object.
    ls_log_filter-object = lr_object.

* definir SUBOBJECT para o filtro de pesquisa
    APPEND INITIAL LINE TO lr_subobject ASSIGNING FIELD-SYMBOL(<fs_subobject>).
    <fs_subobject>-sign   = 'I'.
    <fs_subobject>-option = 'EQ'.
    <fs_subobject>-low    = me->gv_subobject.
    ls_log_filter-subobject = lr_subobject.

    " procurar log especifico para a interface na memória
    REFRESH lt_log_handle.
    CALL FUNCTION 'BAL_GLB_SEARCH_LOG'
      EXPORTING
        i_s_log_filter = ls_log_filter
      IMPORTING
        e_t_log_handle = lt_log_handle
      EXCEPTIONS
        log_not_found  = 1
        OTHERS         = 2.

    IF ( sy-subrc NE 0.
      " procurar log especifico para a interface na base de dados
      REFRESH lt_log_header.
      CALL FUNCTION 'BAL_DB_SEARCH'
        EXPORTING
          i_client           = sy-mandt
          i_s_log_filter     = ls_log_filter
        IMPORTING
          e_t_log_header     = lt_log_header
        EXCEPTIONS
          log_not_found      = 1
          no_filter_criteria = 2
          OTHERS             = 3.

      IF ( sy-subrc NE 0
      AND sy-msgty IS NOT INITIAL.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
           WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      " determinar log handle para a interface em causa
      REFRESH lt_log_handle.
      CALL FUNCTION 'BAL_DB_LOAD'
        EXPORTING
          i_t_log_header     = lt_log_header
        IMPORTING
          e_t_log_handle     = lt_log_handle
        EXCEPTIONS
          no_logs_specified  = 1
          log_not_found      = 2
          log_already_loaded = 3
          OTHERS             = 4.

      IF ( sy-subrc NE 0
      AND sy-msgty IS NOT INITIAL.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
           WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
    ENDIF.

    " determinar mensagens do log em causa
    LOOP AT lt_log_handle INTO DATA(lv_log_handle).

      REFRESH lt_log_messages.
      CALL FUNCTION 'BAL_LOG_READ'
        EXPORTING
          i_log_handle  = lv_log_handle
          i_read_texts  = 'X'
        IMPORTING
          et_msg        = lt_log_messages
        EXCEPTIONS
          log_not_found = 1
          OTHERS        = 2.

      IF ( sy-subrc EQ 0.
        me->gv_log_handle = lv_log_handle.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD save.

    DATA:
      lt_lognumber  TYPE STANDARD TABLE OF balnri.

    CALL FUNCTION 'APPL_LOG_WRITE_DB'
      EXPORTING
        object                = me->gv_object
        subobject             = me->gv_subobject
        log_handle            = me->gv_log_handle
      TABLES
        object_with_lognumber = lt_lognumber
      EXCEPTIONS
        object_not_found      = 1
        subobject_not_found   = 2
        internal_error        = 3
        OTHERS                = 4 .

    IF ( sy-subrc NE 0
    AND sy-msgty IS NOT INITIAL.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
         WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

  ENDMETHOD.


  METHOD show.

    IF gt_log_handle[] IS NOT INITIAL.

      CALL FUNCTION 'BAL_DSP_LOG_DISPLAY'
        EXPORTING
          i_t_log_handle       = gt_log_handle
          i_s_log_filter       = is_filter
        EXCEPTIONS
          profile_inconsistent = 1
          internal_error       = 2
          no_data_available    = 3
          no_authority         = 4
          OTHERS               = 5.

      IF ( sy-subrc NE 0
      AND sy-msgty IS NOT INITIAL.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
           WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

    ENDIF.

  ENDMETHOD.


  METHOD add_direct .

    CONSTANTS:
      lc_init       TYPE char02 VALUE '00',
      lc_step_01_ok TYPE char05 VALUE '01-ok', "Execução ok
      lc_step_01_w  TYPE char05 VALUE '01-w', " Waiting / Aguardando
      lc_step_02_ok TYPE char05 VALUE '02-ok', "Execução ok
      lc_step_02_w  TYPE char05 VALUE '02-w', " Waiting / Aguardando
      lc_step_03_ok TYPE char05 VALUE '03-ok', "Execução ok
      lc_step_03_w  TYPE char05 VALUE '03-w'. " Waiting / Aguardando


    CASE im_step .

      WHEN lc_init .
        DATA(lt_message) = VALUE bapiret2_t(
          ( type       = if_xo_const_message=>info
            id         = '/YGA/JUMP'
            number     = 000
            message_v1 = 'Fase'
            message_v2 = im_step
            message_v3 = |- { sy-uzeit+0(2) }:{ sy-uzeit+2(2) }:{ sy-uzeit+4(2) }| )
        ) .
        /yga/cl_oisu_log=>create_direct( lt_message ) .

      WHEN lc_step_01_ok OR
           lc_step_02_ok OR
           lc_step_03_ok .
        lt_message = VALUE bapiret2_t(
          ( type       = if_xo_const_message=>success
            id         = '/YGA/JUMP'
            number     = 000
            message_v1 = 'Fase'
            message_v2 = im_step
            message_v3 = |- { sy-uzeit+0(2) }:{ sy-uzeit+2(2) }:{ sy-uzeit+4(2) }| ) ) .
        /yga/cl_oisu_log=>create_direct( lt_message ) .

      WHEN lc_step_01_w OR
           lc_step_02_w OR
           lc_step_03_w .
        lt_message = VALUE bapiret2_t(
          ( type       = if_xo_const_message=>warning
            id         = '/YGA/JUMP'
            number     = 000
            message_v1 = 'Fase'
            message_v2 = im_step
            message_v3 = |- { sy-uzeit+0(2) }:{ sy-uzeit+2(2) }:{ sy-uzeit+4(2) }| ) ) .
        /yga/cl_oisu_log=>create_direct( lt_message ) .

      WHEN OTHERS .

    ENDCASE .

  ENDMETHOD .



  METHOD create_direct .

    CONSTANTS:
      lc_object    TYPE balobj_d  VALUE '/YGA/JUMP',
      lc_subobject TYPE balsubobj VALUE '/YGA/OISU_BACKLOG'.

    DATA(lo_log) = NEW /yga/cl_oisu_log( iv_object    = lc_object
                                         iv_subobject = lc_subobject ) .
    IF ( lo_log IS NOT BOUND ) .
      RETURN .
    ENDIF .

    IF ( lines( im_message ) EQ 0 ) .
      RETURN .
    ENDIF .

    lo_log->create( iv_extnumber = |OISU Backlog| ) .
    lo_log->add( it_message = im_message ) .
    lo_log->save( ) .

  ENDMETHOD .

ENDCLASS.