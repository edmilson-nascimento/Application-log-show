report yteste.

tables:
  sscrfields, t001, t009b. "Fields on selection screens


class local_one definition final .

  public section .

    class-methods initialization .

  protected section .
  private section .

endclass .

class local_one implementation .

  method initialization .
  endmethod .

endclass .

data:
  gd_scftx type smp_dyntxt.   "function key 1 properties



selection-screen begin of block box2 with frame title txtblk02.

parameters:
  objtect type balhdr-object default 'USD'.

selection-screen end of block box2.


selection-screen begin of screen 9000 as window title txtblk03.
parameters:
  object   type balhdr-object modif id m1  default 'Z*',
  subobjec type balhdr-subobject default '*',
  aldate_f type balhdr-aldate default '20190101',
  aldate_t type balhdr-aldate default sy-datum,
  altime_f type balhdr-altime modif id m1 default '000000',
  altime_t type balhdr-altime modif id m1 default '235959'.

selection-screen end of screen 9000.


selection-screen function key 1.



at selection-screen output .

  loop at screen.
    if screen-group1 = 'M2'.
      screen-input = '0'.
*    screen-active = '0'.
    endif.
    modify screen.
  endloop.

at selection-screen.

  case sscrfields-ucomm .
    when 'FC01'.
      call selection-screen 9000 starting at 10 05 .
    when 'CRET' .

      data:
        e_s_log_filter type bal_s_lfil,
        e_t_log_header type balhdr_t.

      call function 'BAL_FILTER_CREATE'
        exporting
          i_object       = object
          i_subobject    = subobjec
*         i_extnumber    =
          i_aldate_from  = aldate_f
          i_aldate_to    = aldate_t
          i_altime_from  = altime_f
          i_altime_to    = altime_t
*         i_probclass_from       =
*         i_probclass_to =
*         i_alprog       =
*         i_altcode      =
*         i_aluser       =
*         i_almode       =
*         i_t_lognumber  =
        importing
          e_s_log_filter = e_s_log_filter.

      call function 'BAL_DB_SEARCH'
        exporting
*         i_client           = sy-mandt
          i_s_log_filter     = e_s_log_filter
*         i_t_sel_field      =
        importing
          e_t_log_header     = e_t_log_header
        exceptions
          log_not_found      = 1
          no_filter_criteria = 2
          others             = 3.

      if ( sy-subrc ne 0 ) .
      else .

        data(l_t_log_header) = e_t_log_header[] .

      endif.


      describe table l_t_log_header lines data(number_of_protocols) .

**********************************************************************
**     find out which logs are to be loaded
**********************************************************************
      data l_t_log_handle        type bal_t_logh .
      data l_t_log_loaded        type bal_t_logh .
      data l_t_locked        type  balhdr_t .

      clear l_t_log_handle.

      loop at l_t_log_header assigning field-symbol(<l_s_log_header>) .
        call function 'BAL_LOG_EXIST'
          exporting
            i_log_handle  = <l_s_log_header>-log_handle
          exceptions
            log_not_found = 1.
        if sy-subrc = 0.
          insert <l_s_log_header>-log_handle into table l_t_log_handle.
          delete l_t_log_header.
        endif.
      endloop.

*********************************************************************
*     load logs from database
*********************************************************************
*********************************************************************
* should we read from DB only BALHDR, use flag read_from_db_hdr
*********************************************************************
      call function 'BAL_DB_LOAD'
        exporting
          i_t_log_header  = l_t_log_header
*         i_do_not_load_messages = read_from_db_hdr
          i_lock_handling = 1
        importing
          e_t_log_handle  = l_t_log_loaded
          e_t_locked      = l_t_locked
        exceptions
          others          = 0.
      insert lines of l_t_log_loaded into table l_t_log_handle.

      describe table l_t_locked lines sy-tfill.
      if sy-tfill > 0.
        message s263(bl) with sy-tfill.
      endif.

*  else.
**********************************************************************
**     search logs in archive which fit to these criteria
**********************************************************************
*  read_from_db_hdr = true.
*  call function 'BAL_ARCHIVE_SEARCH'
*  exporting
*    i_s_log_filter          = l_s_log_filter
*    I_DO_NOT_LOAD_MESSAGES  = read_from_db_hdr
*  importing
*    e_s_arcdata             = l_s_arcdata
*  exceptions
*    log_not_found           = 1
*    read_error_from_archive = 2.
*  if sy-subrc <> 0.
*    number_of_protocols = 0.
*    if suppress_selection_dialog = false.
*      message id sy-msgid type 'S' number sy-msgno
*      with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*      continue.
*    else.
*      if sy-subrc = 1.
*        message s257(bl). exit.
*      else.
*        message s258(bl). exit.
*      endif.
*    endif.
*  endif.
*  describe table l_s_arcdata-balhdr_arc lines number_of_protocols.
*
***********************************************************************
**     load logs from archive
**********************************************************************
*  call function 'BAL_ARCHIVE_LOAD'
*  exporting
*    i_s_arcdata    = l_s_arcdata
*    i_do_not_load_messages = read_from_db_hdr
*  importing
*    e_t_log_handle = l_t_log_loaded
*  exceptions
*    others         = 0.
*  insert lines of l_t_log_loaded into table l_t_log_handle.
*  endif.
*
**********************************************************************
**   get standard profile profile if no display profile is defined
**********************************************************************

      data l_s_display_profile type  bal_s_prof .

*      if not i_s_display_profile is initial.
*        l_s_display_profile = i_s_display_profile.
*      else.
      if number_of_protocols = 1.
        call function 'BAL_DSP_PROFILE_SINGLE_LOG_GET'
          importing
            e_s_display_profile = l_s_display_profile
          exceptions
            others              = 0.
      else.
        call function 'BAL_DSP_PROFILE_STANDARD_GET'
          importing
            e_s_display_profile = l_s_display_profile
          exceptions
            others              = 0.
      endif.
*      endif.


*      l_s_display_profile-disvariant-report = i_variant_report.


      call function 'BAL_DSP_LOG_DISPLAY'
        exporting
          i_t_log_handle      = l_t_log_handle
          i_s_display_profile = l_s_display_profile
*         i_srt_by_timstmp    = i_srt_by_timstmp
        exceptions
          no_authority        = 1
          others              = 2.
      if sy-subrc <> 0.

      endif .



  endcase .


initialization.
*  txtblk01 = 'General Selections'.
*  txtblk02 = 'Output Currency Selection'.

*** fill-up of value for function key 1
  gd_scftx-icon_id       =  icon_system_sap_menu.
  gd_scftx-quickinfo     =  text-ss1.
  sscrfields-functxt_01  =  gd_scftx.
