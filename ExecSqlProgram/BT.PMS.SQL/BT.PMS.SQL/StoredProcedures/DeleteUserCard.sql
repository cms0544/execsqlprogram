IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'DeleteUserCard') and xtype='P')  DROP PROCEDURE [dbo].[DeleteUserCard]
GO

/****** Object:  StoredProcedure [dbo].[DeleteUserCard]    Script Date: 2021/4/28 12:02:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<SAM>
-- Create date: <2019-05-05>
-- Description:	<删除卡片> 
--Exec DeleteUserCard 1
-- =============================================
create PROCEDURE [dbo].[DeleteUserCard] 
(
	@ID int
)
AS
BEGIN
	SET NOCOUNT ON; 
--BEGIN TRANSACTION
	Declare @CardID as nvarchar(125),@UserID int,@UserCode nvarchar(20),@CardType int
	set @CardID=''
	set @UserID=0
	set @UserCode=''
	set @CardType=0
	select @CardID=col_CardID,@UserID=col_UserID,@CardType=col_CardType,@UserCode=b.Code from BT_col_CardManagement a left join ZH_Members b on a.col_UserID=b.ID where a.col_ID=@ID
	if @CardID<>''
		begin
			Delete from BT_col_AutoDownloadUserForReader where col_CardNo=@CardID
			Delete from BT_col_AutoDownloadUserForReader where col_UserAddress in (select col_UserAddress from BT_col_UserInfoForReader where col_CardID=@CardID and ISNULL(col_UserAddress,0)>0 and col_CardType>=12)
 			--insert into BT_col_AutoDownloadUserForReader(col_UserCode,col_CardNo,col_DeviceID,col_Status,col_DateStart,col_DateEnd,col_IsQRCodeCard,col_CreateTime)
			--select col_UserCode,col_CardID,sys_ReaderID,99,col_DateStart,col_DateEnd,0,GetDate() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_CardID=@CardID --and col_IsUploadToReader<>99
			if @CardType<11
				begin
					INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
					SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_CardID=@CardID and a.col_CardType<11 
				end
			else if @CardType>12
				begin
					INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
					SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_CardID=@CardID and ISNULL(a.col_UserAddress,0)>0 and a.col_CardType>12 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and brandID=15)
				end
			else if @CardType=12
				begin
					INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
					SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_CardID=@CardID and ISNULL(a.col_UserAddress,0)>0 and a.col_CardType=12 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and brandID=15 and IsOctDevice='true')
				end
			else if @CardType=11
				begin
					INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
					SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_CardID=@CardID and a.col_CardType=11 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and HasQRCode='true') 
				end
			Delete From BT_col_TempUserFace where col_CardID=@CardID 
			Delete From BT_col_UserFaceData where col_CardID=@CardID 
			Delete from BT_sys_UserReaderAccess where sys_CardNo=@CardID
			Delete from BT_sys_UserReaderAccessOld where sys_CardNo=@CardID
			if not exists(select * from BT_col_CardManagement where col_UserID=@UserID and col_ID<>@ID)
				begin
					Delete from BT_sys_UserReaderAccess_JTCY where sys_memberid=@UserID
					Delete from tb_DoorGroup_UserReaderAccess_JTCY where sys_memberid=@UserID
				end
			--insert into BT_sys_FreeCard (sys_CardNO,sys_EventTime,sys_DeviceID,sys_CreateTime) select col_CardID,GetDate(),0,GetDate() from BT_col_UserInfoForReader where col_CardID=@CardID
			Delete from BT_col_UserOldCard where col_CardNo=@CardID
			Delete from BT_col_UserCardRecord where col_CardNo=@CardID
			if @CardType>=12
				begin
					update BT_col_UserIDAndAddress set col_IsDel=1 where col_CardID=@CardID
				end
			else
				begin
					update BT_col_UserIDAndAddress set col_UserID=0,col_CardID='',col_IsDel=0 where col_CardID=@CardID
				end
			Delete from BT_col_UserInfoForReader where col_CardID=@CardID
			--Update BT_col_UserInfoForReader set col_PlanTemplateID=2,col_Status=0,col_IsUploadToReader=99,col_UpdateTime=GetDate() where col_UserCode=@UserCode and col_CardID=@CardID
 		end	

	Delete From BT_col_CardManagement where col_ID=@ID

	delete from BT_col_CardManagement_FCCELL where  cardid = @ID

--commit Transaction 
Select 1
return 0


TheEnd:	
--commit Transaction 
Select 0
return 0

PROBLEM:
--rollback Transaction 
Select 0
return 1

END
