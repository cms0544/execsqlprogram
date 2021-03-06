if(exists(select * from sysobjects where id = object_id('sp_getDownloadStatus') and xtype = 'P'))
  begin
      drop PROCEDURE sp_getDownloadStatus 
  end
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <20,,>
-- Description:	<Description,, sp_getDownloadStatus 2550>
-- =============================================
CREATE PROCEDURE sp_getDownloadStatus 
	-- Add the parameters for the stored procedure here
	@col_id int
AS
BEGIN
	

	declare @userid int,@col_cardid nvarchar(max) ;

	select @userid = col_UserID,@col_cardid = col_CardID from BT_col_CardManagement where col_id = @col_id

	select * into #BT_sys_UserDownloadRecord from BT_sys_UserDownloadRecord where sys_UserID = @userid and sys_CardID = @col_cardid
	select  a.sys_id, a.sys_CardID,b.HostName,case a.sys_SetOrClear when 1 then  iif(a.sys_IsOK = 1,'下載卡片成功','下載卡片失敗') when 2 then  iif(a.sys_IsOK = 1,'下載人臉成功','下載人臉失敗') when 99 then  iif(a.sys_IsOK = 1,'刪除成功','刪除失敗') when 4 then  iif(a.sys_IsOK = 1,'只刪除人臉成功','只刪除人臉失敗') end as status
	from #BT_sys_UserDownloadRecord as a
	left join BT_HostDevice as b on a.sys_ReaderID = b.HostDeviceID
	 where sys_CreateTime in (
	select  max(sys_CreateTime) as sys_CreateTime from #BT_sys_UserDownloadRecord  
	group by sys_cardid,sys_ReaderID)
END
GO


