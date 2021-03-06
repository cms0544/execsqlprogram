--USE [BT_PMS]
IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'sp_BT_sys_RawDataLogForReader_kanban') and xtype='P')  DROP PROCEDURE [dbo].[sp_BT_sys_RawDataLogForReader_kanban]
GO
/****** Object:  StoredProcedure [dbo].[sp_BT_sys_RawDataLogForReader_kanban]    Script Date: 2021/5/12 20:51:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Mason>
-- Create date: <2021-03-30,,>
-- Description:	<获取最新的图片,sp_BT_sys_RawDataLogForReader_kanban 'admin',0,1>
-- =============================================
create PROCEDURE [dbo].[sp_BT_sys_RawDataLogForReader_kanban]
  @userid varchar(max) = '',
  @lastid int=0,
  @showpic int = 0
AS
BEGIN
	create table #temphostdevice
	(
	    [id] int
	)


	if(@userid='admin')
	   begin
	       insert into #temphostdevice
		   select HostDeviceID from  BT_HostDevice 
	   end
	else
	  begin
	      insert into #temphostdevice
		   select HostDeviceID from  BT_HostDevice 
		   where HostDeviceID in(
				select modu_id from qx_mj where role_id = ( select UI_ROLE from yh where UI_ID = @userid  )
			)
	  end

	  declare @updateid int = 0;
	  select @updateid = max(sys_id) from BT_sys_RawDataLogForReader where sys_valid = 1 and sys_IsFirst = 1 and sys_readerid in (
		 select  id from #temphostdevice
	 
		)

	if(@updateid! = @lastid)

	   begin




				select top 11 sys_DeviceName,sys_CardNO,sys_CardName,dbo.dateformatter(sys_EventTime,'dd/MM/yyyy HH:mm:ss') as sys_EventTime,case when isnull(a.sys_IsTaData,0)=1 then '住戶' else '訪客' end as sys_IsTaData,
				--iif(isnull(a.sys_PicDataUrl,'')='',iif(isnull(b.zpurl,'')='','/attach/pms/f01i/no.gif',b.zpurl),sys_PicDataUrl) as sys_PicDataUrl
				iif(@showpic!=1,'/pms2/SignScreen/imgs/avator.jpg', iif(isnull(b.zpurl,'')='','/pms2/SignScreen/imgs/avator.jpg',substring(b.zpurl,charindex('\UoloadImg\',b.zpurl),len(b.zpurl)))) as  sys_PicDataUrl
				,sys_UserCode,
				case when isnull(a.sys_UserName, '')= '' then isnull(a.sys_CardName, '') else isnull(a.sys_UserName, '') end sys_UserName,isnull(v.simplecellname,isnull(c.cellname,'訪客')) as cellname,
				case when isnull(a.sys_Valid, 0)= 1 then '成功' else '失敗' end  sys_Valid,isnull(v.jtsf,'') as jtsf,@updateid as lastid
				from BT_sys_RawDataLogForReader as a with (nolock)
				left join ZH_Members as b on a.sys_UserID = b.id
				left join View_ZHFCLPInfo as c on c.ownerid = b.ownerid
				left join VI_col_CardManagement as v on  v.col_userid =  b.id and v.col_cardid = a.sys_CardNO

				where a.sys_valid = 1 and a.sys_IsFirst = 1 and sys_readerid in (
				 select  id from #temphostdevice
	 
				)
				order by sys_GetDataTime desc
	 end
	 else 
	  begin
	      select 1
	  end
END
