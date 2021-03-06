if(exists(select 1 from sysobjects where id = object_id('sp_Zh_memember')))
   begin
      drop procedure sp_Zh_memember
   end
/****** Object:  StoredProcedure [dbo].[sp_Zh_memember]    Script Date: 2021/7/26 11:52:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Mason>
-- Create date: <2021-03-12,,>
-- Description:	<獲取家庭成員列表,, exec sp_Zh_memember 26,'','','',1,10,''>
-- =============================================
CREATE procedure [dbo].[sp_Zh_memember]
	@ownerid varchar(max) = 0 ,
	@code varchar(max) = '',
	@cardid varchar(max) = '',
	@mobile varchar(max) = '',
	@page int,
	@rows int,
	@memeberid varchar(max) = '',
	@name varchar(max) = '',
	@cellname varchar(max) = ''
AS
BEGIN
   declare @str varchar(max) = '';
   set @str = 'select a.id,a.zpurl,a.code,a.name,a.sex,a.jtsf,a.memo,a.alias,a.card_id,a.card_kmbm,a.col_OctopusNo,a.card_state,convert(varchar(10),a.card_DateStart,120) as card_DateStart,convert(varchar(10),a.card_DateEnd,120) as card_DateEnd,a.bt_app_user_mobile,a.app_is_maste,a.app_remark,app_disabled,a.app_bind_created_by_qrcode,a.whatapps,a.zjstatus,a.feestatus,a.feevalue,a.col_Leave_Reason,case when a.app_is_maste=0 then ''子賬戶'' when a.app_is_maste=1 then ''主賬戶'' else '''' end as mastername,case when isnull([app_disabled],0) = 1 then ''禁用'' else ''啟用'' end as [disabledname],app_permission_type,usercardid,bt_app_user_uid,app_bind_guid,col_qrcodeno,a.enname,a.jjlxr,a.jjlxrmobile,a.lxdh,a.authorizer,a.authorizedperson,case when a.authorizedfrom is null then null else convert(varchar(10),a.authorizedfrom,103) end as authorizedfrom,case when a.authorizedend is null then null else convert(varchar(10),a.authorizedend,103) end as authorizedend,jtsfname,a.cellnames,a.ownerid ';
   set @str = @str + ' into #tempMme';
   set @str = @str + ' from V_ZH_Members a ';
   set @str = @str + ' left join ZH_Owner b on a.ownerid = b.ID where 1=1 ';


   if(@ownerid !=0)
     begin
	      set @str = @str + ' and ( ownerid = '''+ convert(varchar(max), @ownerid)+''' or a.id in (select col_userid from BT_col_CardManagement where col_id in (select cardid from BT_col_CardManagement_fccell where cellid in (select cellid from zh_fc where ownerid = '+@ownerid+'))))';
	 end


   if(@code != '')
     begin
	    set @str = @str + ' and a.code like ''%'+@code+'%''';
	 end

   if(@cardid != '')
     begin
	    set @str = @str + ' and a.card_ID like ''%'+@cardid+'%'' or col_OctopusNo like ''%'+@cardid+'%''';
	 end


   if(@mobile != '')
     begin
	    set @str = @str + ' and a.bt_app_user_mobile like ''%'+@mobile+'%''';
	 end
	if(@memeberid!='')
	  begin
	    set @str = @str + ' and a.id in ('+convert(varchar(max),@memeberid)+')';
	  end

	if(@name !='')
	  begin
	   set @str = @str + ' and (a.name like ''%'+@name+'%'' or a.alias like ''%'+@name+'%'')'
	  end

	if(@cellname !='')
    begin
	   set @str = @str + ' and (a.cellnames like ''%'+@cellname+'%'' )'
	  end

   set @str = @str + ' select * from #tempMme order by id desc offset '+ convert(varchar(max),(@page - 1)*@rows )+ ' row fetch next '+convert(varchar(max),@rows) + ' rows only';

   set @str = @str + ' select count(1) from #tempMme';
   print @str

   exec(@str)

END

