CLASS /yga/cl_oisu_log DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION .

    METHODS constructor
      IMPORTING
        !iv_object    TYPE balobj_d
        !iv_subobject TYPE balsubobj .
    "! <p class="shorttext synchronized" lang="pt">Cria novo objeto de log</p>
    METHODS create
      IMPORTING
        !iv_extnumber TYPE balnrext .
    "! <p class="shorttext synchronized" lang="pt">Adiciona mensagens de processsamento (store)</p>
    METHODS add
      IMPORTING
        !it_message TYPE bapiret2_t OPTIONAL
        !is_message TYPE bapiret2 OPTIONAL .
    "! <p class="shorttext synchronized" lang="pt">Salva mensagens de armazenadas em buffer</p>
    METHODS save .
    "! <p class="shorttext synchronized" lang="pt">Exibe mensagens</p>
    METHODS show
      IMPORTING
        !is_filter TYPE bal_s_lfil OPTIONAL .
    "! <p class="shorttext synchronized" lang="pt">Retorna mensagens centralizadas</p>
    METHODS get
      IMPORTING
        !iv_extnumber TYPE balnrext .
    "! <p class="shorttext synchronized" lang="pt">Adicionar diretamente log</p>
    METHODS add_backlog
      IMPORTING
        !im_step  TYPE char05
        !im_date  type sy-datum   OPTIONAL
        !im_time  type sy-uzeit   OPTIONAL
        !im_equnr TYPE equi-equnr OPTIONAL
        !im_tplnr TYPE iflo-tplnr OPTIONAL .


  PROTECTED SECTION.

  PRIVATE SECTION.

    DATA:
      gt_log_handle TYPE bal_t_logh,
      gv_object     TYPE balobj_d,
      gv_subobject  TYPE balsubobj,
      gv_log_handle TYPE balloghndl.

    "! <p class="shorttext synchronized" lang="pt">Retorna data no formato dd.mm.yyyy</p>
    CLASS-METHODS get_date_out
      IMPORTING
        !im_date      TYPE sy-datum
      RETURNING
        VALUE(result) TYPE bapiret2-message .

    "! <p class="shorttext synchronized" lang="pt">Retorna hora no formato HH:mm:ss</p>
    CLASS-METHODS get_time_out
      IMPORTING
        !im_time      TYPE sy-uzeit
      RETURNING
        VALUE(result) TYPE bapiret2-message .

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

        IF ( sy-subrc NE 0 ) AND
           ( sy-msgty IS NOT INITIAL ) .
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

      IF ( sy-subrc NE 0 ) AND
         ( sy-msgty IS NOT INITIAL ) .
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

    ls_s_log-aldate_del = sy-datum + 30 .                "#EC NUMBER_OK
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

    IF ( sy-subrc NE 0 ) AND
       ( sy-msgty IS NOT INITIAL ) .
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
         WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ELSE.
      APPEND me->gv_log_handle TO gt_log_handle.
    ENDIF.

  ENDMETHOD.


  METHOD get.

    DATA:
      lt_log_header   TYPE balhdr_t,
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

    IF ( sy-subrc NE 0 ) .

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

      IF ( sy-subrc NE 0 ) AND
         ( sy-msgty IS NOT INITIAL ) .
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

      IF ( sy-subrc NE 0 ) AND
         ( sy-msgty IS NOT INITIAL ) .
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

      IF ( sy-subrc EQ 0 ) .
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
        OTHERS                = 4.

    IF ( sy-subrc NE 0 ) AND
       ( sy-msgty IS NOT INITIAL ) .
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
         WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.


  ENDMETHOD.


  METHOD show.

    IF ( gt_log_handle[] IS NOT INITIAL ) .

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

      IF ( sy-subrc NE 0 ) AND
         ( sy-msgty IS NOT INITIAL ) .
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

    ENDIF.

  ENDMETHOD.


  METHOD add_backlog .

    CONSTANTS:
      lc_message_id TYPE bapiret2-id VALUE '/YGA/JUMP',
      lc_init       TYPE char02 VALUE '00',
      lc_step_01_ok TYPE char05 VALUE '01-ok', "Execução ok
      lc_step_01_w  TYPE char05 VALUE '01-w', " Waiting / Aguardando
      lc_step_02_ok TYPE char05 VALUE '02-ok', "Execução ok
      lc_step_02_w  TYPE char05 VALUE '02-w', " Waiting / Aguardando
      lc_step_03_ok TYPE char05 VALUE '03-ok', "Execução ok
      lc_step_03_w  TYPE char05 VALUE '03-w'. " Waiting / Aguardando


    CASE im_step .

      WHEN lc_init .
        me->add(
          EXPORTING it_message = VALUE bapiret2_t(
            ( type       = if_xo_const_message=>info
              id         = lc_message_id
              number     = 876                           "#EC NUMBER_OK
              message_v1 = get_date_out( sy-datum )
              message_v2 = get_time_out( sy-uzeit ) ) )
         ) .
        IF ( 0 EQ 1 ). MESSAGE i876(/yga/jump) WITH space space. ENDIF .

      WHEN lc_step_01_ok .
        me->add(
          EXPORTING it_message = VALUE bapiret2_t(
            ( type       = if_xo_const_message=>info
              id         = lc_message_id
              number     = 874                           "#EC NUMBER_OK
              message_v1 = |{ im_equnr ALPHA = OUT }|
              message_v2 = |{ im_tplnr ALPHA = OUT }| ) )
         ) .
        " Equipamento & ja está desmontado no loc.instalação &.
        IF ( 0 EQ 1 ). MESSAGE i874(/yga/jump) WITH space space. ENDIF .

      WHEN lc_step_01_w .
        me->add(
          EXPORTING it_message = VALUE bapiret2_t(
            ( type       = if_xo_const_message=>warning
              id         = lc_message_id
              number     = 875                           "#EC NUMBER_OK
              message_v1 = |{ im_equnr ALPHA = OUT }|
              message_v2 = |{ im_tplnr ALPHA = OUT }| ) )
         ) .
        " Equipamento & ja está desmontado no loc.instalação &.
        IF ( 0 EQ 1 ). MESSAGE i875(/yga/jump) WITH space space. ENDIF .

      WHEN lc_step_02_ok OR
           lc_step_03_ok .
        me->add(
          EXPORTING it_message = VALUE bapiret2_t(
            ( type       = if_xo_const_message=>info
              id         = lc_message_id
              number     = 872                           "#EC NUMBER_OK
              message_v1 = |{ im_equnr ALPHA = OUT }|
              message_v2 = |{ im_tplnr ALPHA = OUT }| ) )
         ) .
        " Equipamento & já está montado no loc.instalação &.
        IF ( 0 EQ 1 ). MESSAGE i872(/yga/jump) WITH space space. ENDIF .

      WHEN lc_step_02_w OR
           lc_step_03_w .
        me->add(
          EXPORTING it_message = VALUE bapiret2_t(
            ( type       = if_xo_const_message=>warning
              id         = lc_message_id
              number     = 873                           "#EC NUMBER_OK
              message_v1 = |{ im_equnr ALPHA = OUT }|
              message_v2 = |{ im_tplnr ALPHA = OUT }| ) )
         ) .
        " Equipamento & não está montado no loc.instalação &.
        IF ( 0 EQ 1 ). MESSAGE i873(/yga/jump) WITH space space. ENDIF .

      WHEN OTHERS .

    ENDCASE .

  ENDMETHOD .


  METHOD get_date_out .

    IF ( im_date IS INITIAL ) .
      RETURN .
    ENDIF .

    result = |{ im_date DATE = USER }| .

  ENDMETHOD.


  METHOD get_time_out .

    IF ( im_time IS INITIAL ) .
      RETURN .
    ENDIF .

    result =
      |{ im_time+0(2) }:{ im_time+2(2) }:{ im_time+4(2) }| .

  ENDMETHOD.


ENDCLASS.