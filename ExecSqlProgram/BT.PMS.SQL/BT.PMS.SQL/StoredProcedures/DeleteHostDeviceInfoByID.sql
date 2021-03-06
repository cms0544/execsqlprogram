--USE [BT_PMS]
IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'DeleteHostDeviceInfoByID') and xtype='P')  DROP PROCEDURE [dbo].[DeleteHostDeviceInfoByID]
GO
/****** Object:  StoredProcedure [dbo].[DeleteHostDeviceInfoByID]    Script Date: 2021/03/05 18:37:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<samlau>
-- Create date: <2021-03-05>
-- Description:	<根據ID刪除設備信息>
--exec DeleteHostDeviceInfoByID 35
-- =============================================
CREATE PROCEDURE [dbo].[DeleteHostDeviceInfoByID](
@ID int--自增ID
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	if @ID=0
		begin
			 return 1
		end
 
	Declare @ReaderLOGO nvarchar(16) 
	set @ReaderLOGO=''   
	select @ReaderLOGO=ReaderLOGO from BT_HostDevice where HostDeviceID=@ID
	Delete From BT_sys_ReaderOnlineLog where sys_DeviceID=@ID
	Delete From BT_sys_ReaderOnlineStatus where sys_DeviceID=@ID
	Delete From BT_col_AutoDownloadUserForReader where col_DeviceID=@ID
	Delete from t_sys_ReaderMachine where ReaderLOGO=@ReaderLOGO --and readername=(select HostName from BT_HostDevice where HostDeviceID=@ID)
	Delete from t_Soyal_ConnPort where ID not in (select connportID from t_sys_ReaderMachine)
	Delete from BT_HostDevice where HostDeviceID=@ID
	Delete from BT_HostDevice where MainReaderID=@ID--samlau 20210415
	--update BT_HostDevice set deleted=1 where HostDeviceID=@ID
	Delete FROM BT_sys_UserReaderAccess WHERE sys_ReaderID=@ID
	Delete FROM BT_sys_UserReaderAccessOld WHERE sys_ReaderID=@ID
	Delete FROM BT_sys_UserReaderAccess_JTCY WHERE sys_ReaderID=@ID
	Delete FROM tb_DoorGroup_UserReaderAccess_JTCY WHERE sys_ReaderID=@ID

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
