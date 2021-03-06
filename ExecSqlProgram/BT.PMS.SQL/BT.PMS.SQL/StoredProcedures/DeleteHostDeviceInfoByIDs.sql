--USE [BT_PMS]
IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'DeleteHostDeviceInfoByIDs') and xtype='P')  DROP PROCEDURE [dbo].[DeleteHostDeviceInfoByIDs]
GO
/****** Object:  StoredProcedure [dbo].[DeleteHostDeviceInfoByIDs]    Script Date: 2021/03/05 18:37:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<samlau>
-- Create date: <2021-03-05>
-- Description:	<根據ID刪除設備信息>
--exec DeleteHostDeviceInfoByIDs '6,7'
-- =============================================
CREATE PROCEDURE [dbo].[DeleteHostDeviceInfoByIDs](
@IDs nvarchar(max)--自增ID,刪除多個設備時
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	if replace(replace(@IDs,'0',''),',','')='' 
		begin
			 return 1
		end
 
	Declare @ReaderLOGO nvarchar(16),@sqlstr nvarchar(max) 
	set @ReaderLOGO=''   
	set @sqlstr=''
	--select @ReaderLOGO=ReaderLOGO from BT_HostDevice where HostDeviceID in ('+@IDs+')'
	set @sqlstr=@sqlstr+char(10)+char(9)+' Delete From BT_sys_ReaderOnlineLog where sys_DeviceID in ('+@IDs+')'
	set @sqlstr=@sqlstr+char(10)+char(9)+' Delete From BT_sys_ReaderOnlineStatus where sys_DeviceID in ('+@IDs+')'
	set @sqlstr=@sqlstr+char(10)+char(9)+' Delete From BT_col_AutoDownloadUserForReader where col_DeviceID in ('+@IDs+')'
	set @sqlstr=@sqlstr+char(10)+char(9)+' Delete from t_sys_ReaderMachine where ReaderLOGO in (select ReaderLOGO from BT_HostDevice where HostDeviceID in ('+@IDs+'))' --and readername=(select HostName from BT_HostDevice where HostDeviceID in ('+@IDs+')')
	set @sqlstr=@sqlstr+char(10)+char(9)+' Delete from BT_HostDevice where HostDeviceID in ('+@IDs+')'
	set @sqlstr=@sqlstr+char(10)+char(9)+' Delete from BT_HostDevice where MainReaderID in ('+@IDs+')'--samlau 20210415
	--set @sqlstr=@sqlstr+char(10)+char(9)+' update BT_HostDevice set deleted=1 where HostDeviceID in ('+@IDs+')'
	set @sqlstr=@sqlstr+char(10)+char(9)+' Delete FROM BT_sys_UserReaderAccess WHERE sys_ReaderID in ('+@IDs+')'
	set @sqlstr=@sqlstr+char(10)+char(9)+' Delete FROM BT_sys_UserReaderAccessOld WHERE sys_ReaderID in ('+@IDs+')'
	set @sqlstr=@sqlstr+char(10)+char(9)+' Delete FROM BT_sys_UserReaderAccess_JTCY WHERE sys_ReaderID in ('+@IDs+')'
	set @sqlstr=@sqlstr+char(10)+char(9)+' Delete FROM tb_DoorGroup_UserReaderAccess_JTCY WHERE sys_ReaderID in ('+@IDs+')'
	EXEC sp_executesql @sqlstr

	Delete from t_Soyal_ConnPort where ID not in (select connportID from t_sys_ReaderMachine)

	if not exists(select 1 from t_sys_ReaderMachine)
		begin
			truncate table t_sys_ReaderMachine
			truncate table t_Soyal_ConnPort
			truncate table t_Soyal_Area
		end

	truncate table BT_sys_IfNeedReStartServer
	insert into BT_sys_IfNeedReStartServer select 1,1,dateadd(minute,4,Getdate())
	return 1

END
