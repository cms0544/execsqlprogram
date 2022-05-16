--USE [BT_PMS]
IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'SaveUserAutoDownloadRecord') and xtype='P')  DROP PROCEDURE [dbo].[SaveUserAutoDownloadRecord]
GO
/****** Object:  StoredProcedure [dbo].[SaveUserAutoDownloadRecord]    Script Date: 12/26/2018 18:23:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<SAM>
-- Create date: <2019-03-14>
-- Description:	<保存自动处理表里记录处理成功的記錄> 
--EXEC SaveUserAutoDownloadRecord 52577,'22G','何先生',0,'4276095627',0,'2021-03-02','2022-03-02',0,255,1,0,1,1,1,'',1
-- =============================================
CREATE PROCEDURE [dbo].[SaveUserAutoDownloadRecord] 
(
	@UserID bigint,
	@UserCode nvarchar(20), 
	@UserName nvarchar(400), 
	@UserType int,
	@FCCellID nvarchar(20),
	@CardID nvarchar(125),
	@CardType int,
	@StartDate nvarchar(19),
	@EndDate nvarchar(19), 
	@MaxSwipeTime int,
	@PlanTemplateID int,
	@Status int, 
	@IsQRCodeCard int, 
	@SetOrClear int, 
	@ReaderID int,
	@IsOK int, 
	@ErrorReason nvarchar(max),
	@UserAddress int=0
)
AS
BEGIN
	SET NOCOUNT ON;  
	
	Declare @CreateTime datetime,@TodayDate datetime,@Count int
	set @CreateTime=GetDate()
	set @TodayDate=Convert(nvarchar(10),GETDATE(),120)
	if @SetOrClear<0-- -3 開門
		begin
			Delete From BT_col_AutoDownloadUserForReader where col_DeviceID=@ReaderID and col_Status=@SetOrClear
			if @SetOrClear=-3--開門
				begin
					Delete From BT_col_AutoDownloadUserForReader where col_UserID=@UserID and col_UserCode='OPENDOOR' and col_Status=@SetOrClear
					if @IsOK=1--開門成功
						begin
							update BT_sys_RawDataLogForReader set sys_IsOpenDoor=1,sys_OpenDoorTime=GetDate() where sys_ID=@UserID and sys_IsOpenDoor=0
						end
				end

			return
		end

	Declare @tmpIsOK int
	set @tmpIsOK=@IsOK
	if @IsOK=1 and @ErrorReason like '%已存在%'
		begin
			set @tmpIsOK=0
		end

	if(@UserType=1 and @UserCode='0' and @UserName='')
		begin
			set @UserCode='QRCode Visitor'
			set @UserName=@UserCode
		end

	Declare @MainReaderID int,@DoorNum as int,@DeviceType nvarchar(125)--samlau 20210415
	set @MainReaderID=@ReaderID
	set @DoorNum=1--samlau 20210415
	set @DeviceType=''--samlau 20210415
	select @MainReaderID=MainReaderID,@DoorNum=HostCamera,@DeviceType=DeviceType from V_HostDevice Where HostDeviceID=@ReaderID--samlau 20210415
	if @DoorNum>1 and (@SetOrClear=1 or @SetOrClear=9 or @SetOrClear=99)--samlau 20210415
		begin
			--Delete from BT_sys_UserDownloadRecord where sys_UserCode=@UserCode and sys_CardID=@CardID and sys_SetOrClear=@SetOrClear and sys_ReaderID=@ReaderID and sys_CreateTime=@CreateTime
			insert into BT_sys_UserDownloadRecord(sys_UserID,sys_UserCode,sys_UserName,sys_UserType,sys_UserAddress,sys_FCCellID,sys_CardID,sys_CardType,sys_DateStart,sys_DateEnd,sys_MaxSwipeTime,sys_PlanTemplateID,sys_Status,sys_IsQRCodeCard,sys_SetOrClear,sys_ReaderID,sys_IsOK,sys_ErrorRemark,sys_CreateTime)   
			select @UserID,@UserCode,@UserName,@UserType,@UserAddress,@FCCellID,@CardID,@CardType,@StartDate,@EndDate,@MaxSwipeTime,@PlanTemplateID,@Status,@IsQRCodeCard,@SetOrClear,HostDeviceID,@tmpIsOK,@ErrorReason,@CreateTime from BT_col_AutoDownloadUserForReader a left join V_HostDevice b on a.col_DeviceID=b.HostDeviceID Where a.col_UserCode=@UserCode AND a.col_CardNo=@CardID and a.col_Status=@SetOrClear and b.MainReaderID=@MainReaderID--samlau 20210415
			if @SetOrClear=99--下載和刪除是同時的
				begin
					insert into BT_sys_UserDownloadRecord(sys_UserID,sys_UserCode,sys_UserName,sys_UserType,sys_UserAddress,sys_FCCellID,sys_CardID,sys_CardType,sys_DateStart,sys_DateEnd,sys_MaxSwipeTime,sys_PlanTemplateID,sys_Status,sys_IsQRCodeCard,sys_SetOrClear,sys_ReaderID,sys_IsOK,sys_ErrorRemark,sys_CreateTime)   
					select @UserID,@UserCode,@UserName,@UserType,@UserAddress,@FCCellID,@CardID,@CardType,@StartDate,@EndDate,@MaxSwipeTime,@PlanTemplateID,@Status,@IsQRCodeCard,col_Status,HostDeviceID,@tmpIsOK,@ErrorReason,@CreateTime from BT_col_AutoDownloadUserForReader a left join V_HostDevice b on a.col_DeviceID=b.HostDeviceID Where a.col_UserCode=@UserCode AND a.col_CardNo=@CardID and a.col_Status in (1,9) and b.MainReaderID=@MainReaderID--samlau 20210415
				end
			else
				begin
					insert into BT_sys_UserDownloadRecord(sys_UserID,sys_UserCode,sys_UserName,sys_UserType,sys_UserAddress,sys_FCCellID,sys_CardID,sys_CardType,sys_DateStart,sys_DateEnd,sys_MaxSwipeTime,sys_PlanTemplateID,sys_Status,sys_IsQRCodeCard,sys_SetOrClear,sys_ReaderID,sys_IsOK,sys_ErrorRemark,sys_CreateTime)   
					select @UserID,@UserCode,@UserName,@UserType,@UserAddress,@FCCellID,@CardID,@CardType,@StartDate,@EndDate,@MaxSwipeTime,@PlanTemplateID,@Status,@IsQRCodeCard,col_Status,HostDeviceID,@tmpIsOK,@ErrorReason,@CreateTime from BT_col_AutoDownloadUserForReader a left join V_HostDevice b on a.col_DeviceID=b.HostDeviceID Where a.col_UserCode=@UserCode AND a.col_CardNo=@CardID and a.col_Status=99 and b.MainReaderID=@MainReaderID--samlau 20210415
				end
		end
	else
		begin
			--Delete from BT_sys_UserDownloadRecord where sys_UserCode=@UserCode and sys_CardID=@CardID and sys_SetOrClear=@SetOrClear and sys_ReaderID=@ReaderID and sys_CreateTime=@CreateTime
			insert into BT_sys_UserDownloadRecord(sys_UserID,sys_UserCode,sys_UserName,sys_UserType,sys_UserAddress,sys_FCCellID,sys_CardID,sys_CardType,sys_DateStart,sys_DateEnd,sys_MaxSwipeTime,sys_PlanTemplateID,sys_Status,sys_IsQRCodeCard,sys_SetOrClear,sys_ReaderID,sys_IsOK,sys_ErrorRemark,sys_CreateTime)   
			VALUES(@UserID,@UserCode,@UserName,@UserType,@UserAddress,@FCCellID,@CardID,@CardType,@StartDate,@EndDate,@MaxSwipeTime,@PlanTemplateID,@Status,@IsQRCodeCard,@SetOrClear,@ReaderID,@tmpIsOK,@ErrorReason,@CreateTime)
		end

	if @IsOK=1
		begin
			Delete from BT_col_AutoDownloadUserForReader where col_UserCode=@UserCode AND col_CardNo=@CardID and col_DeviceID=@ReaderID and col_Status=@SetOrClear 
			if @UserType=1
				begin
					Delete from BT_col_AutoDownloadUserForReader where col_CardNo=@CardID and col_DeviceID=@ReaderID and col_Status=@SetOrClear 
				end

			if @DoorNum>1 and (@SetOrClear=1 or @SetOrClear=9)--samlau 20210415
				begin
					Delete from BT_col_AutoDownloadUserForReader where col_UserCode=@UserCode AND col_CardNo=@CardID and col_DeviceID in (select HostDeviceID from V_HostDevice Where HostCamera>1 AND MainReaderID=@MainReaderID) and col_Status=@SetOrClear 
					if @UserType=1
						begin
							Delete from BT_col_AutoDownloadUserForReader where col_CardNo=@CardID and col_DeviceID in (select HostDeviceID from V_HostDevice Where HostCamera>1 AND MainReaderID=@MainReaderID) and col_Status=@SetOrClear 
						end
				end

			if @SetOrClear=1 OR @SetOrClear=9
				begin	
					set @Count=0
					select @Count=1 from BT_col_UserInfoForReader WITH(NOLOCK) where col_UserCode=@UserCode and col_CardID=@CardID and col_InoutType=-1
					if @Count=1 AND @SetOrClear=1
						begin
							update BT_col_UserInfoForReader set col_InoutType=0 where col_UserCode=@UserCode and col_CardID=@CardID and col_InoutType=-1
						end
					set @Count=0
					select @Count=1 from BT_col_UserInfoForReader WITH(NOLOCK) where col_UserCode=@UserCode and col_CardID=@CardID and col_IsUploadToReader=@SetOrClear-1
					if @Count=1
						begin
							update BT_col_UserInfoForReader set col_IsUploadToReader=@SetOrClear where col_UserCode=@UserCode and col_CardID=@CardID and col_IsUploadToReader=@SetOrClear-1
						end

					update BT_col_UserInfoForReader set col_UploadTime=@CreateTime where col_UserCode=@UserCode and col_CardID=@CardID
					set @Count=0
					select @Count=1 from BT_col_UserOldCard WITH(NOLOCK) where col_UserCode=@UserCode and col_CardNo=@CardID 
					if @Count=1
						begin
							insert into BT_col_UserOldCard select @UserCode,@CardID,GetDate()
						end
					else
						begin
							update BT_col_UserOldCard set col_CreateTime=GetDate() where col_UserCode=@UserCode and col_CardNo=@CardID 
						end

					--if (@IsQRCodeCard=0 and Exists(select 1 from BT_col_UserInfoForReader WITH(NOLOCK) where col_CardID=@CardID and col_DateStart<=GETDATE() and col_DateEnd>GetDate() and col_Status=1))
					--	begin
					--		if @UserAddress>0--删除用户位置的去掉  有可能只是刪除權限而已，所以去掉
					--			begin
					--				set @Count=0
					--				select @Count=1 from BT_col_AutoDownloadUserForReader WITH(NOLOCK) where col_UserAddress=@UserAddress and col_DeviceID=@ReaderID and col_Status=99
					--				if @Count=1
					--					begin
					--						Delete from BT_col_AutoDownloadUserForReader where col_UserAddress=@UserAddress and col_DeviceID=@ReaderID and col_Status=99
					--					end
					--			end
					--		else --删除卡号的去掉  有可能只是刪除權限而已，所以去掉
					--			begin
					--				set @Count=0
					--				select @Count=1 from BT_col_AutoDownloadUserForReader WITH(NOLOCK) where col_CardNo=@CardID and col_DeviceID=@ReaderID and col_Status=99 
					--				if @Count=1
					--					begin
					--						Delete from BT_col_AutoDownloadUserForReader where col_CardNo=@CardID and col_DeviceID=@ReaderID and col_Status=99 
					--					end
					--			end
					--	end
					
					--Delete from BT_col_AutoDownloadUserForReader where col_UserCode=@UserCode AND col_CardNo=@CardID and col_Status=99 and col_DeviceID=@ReaderID and col_CreateTime<@CreateTime
					--if @DoorNum>1 and (@SetOrClear=1 or @SetOrClear=9)--samlau 20210415
					--	begin
					--		Delete from BT_col_AutoDownloadUserForReader where col_UserCode=@UserCode AND col_CardNo=@CardID and col_Status=99 and col_DeviceID in (select HostDeviceID from V_HostDevice Where HostCamera>1 AND MainReaderID=@MainReaderID) and col_CreateTime<@CreateTime 
					--	end
				end
			else if @SetOrClear=2
				begin
					set @Count=0
					select @Count=1 from BT_col_UserInfoForReader WITH(NOLOCK) where col_UserCode=@UserCode and col_CardID=@CardID and col_IsUploadToReader=@SetOrClear-1
					if @Count=1
						begin
							update BT_col_UserInfoForReader set col_IsUploadToReader=@SetOrClear where col_UserCode=@UserCode and col_CardID=@CardID and col_IsUploadToReader=@SetOrClear-1
						end
					update BT_col_UserInfoForReader set col_UploadTime=@CreateTime where col_UserCode=@UserCode and col_CardID=@CardID
					Exec DeleteUserFaceDownloadError @UserID,@CardID,1,@ReaderID
					--set @Count=0		有可能只是刪除權限而已，所以去掉
					--select @Count=1 from BT_col_AutoDownloadUserForReader WITH(NOLOCK) where col_CardNo=@CardID and col_DeviceID=@ReaderID and col_Status=99 
					--if @Count=1
					--	begin
					--		Delete from BT_col_AutoDownloadUserForReader where col_CardNo=@CardID and col_DeviceID=@ReaderID and col_Status=99 
					--	end 

					--Delete from BT_col_AutoDownloadUserForReader where col_UserCode=@UserCode AND col_CardNo=@CardID and col_Status=99 and col_DeviceID=@ReaderID and col_CreateTime<@CreateTime
				end
			else if @SetOrClear=99
				begin
					set @Count=0
					select @Count=1 from BT_col_UserInfoForReader WITH(NOLOCK) where col_UserCode=@UserCode and col_CardID=@CardID and col_IsUploadToReader=@SetOrClear-1
					if @Count=1
						begin
							update BT_col_UserInfoForReader set col_IsUploadToReader=@SetOrClear where col_UserCode=@UserCode and col_CardID=@CardID and col_IsUploadToReader=@SetOrClear-1
						end
					set @Count=0
					if @IsQRCodeCard=0
						begin
							select @Count=1 from BT_col_AutoDownloadUserForReader WITH(NOLOCK) where col_CardNo=(select col_CardID from BT_col_UserInfoForReader WITH(NOLOCK) where col_CardID=@CardID and (col_Status=0 or col_DateEnd<getdate())) and col_IsQRCodeCard=0 and col_Status<4
							if @Count=1
								begin
									Delete from BT_col_AutoDownloadUserForReader where col_CardNo=(select col_CardID from BT_col_UserInfoForReader WITH(NOLOCK) where col_UserID=@UserID and col_IsUploadToReader=99) and col_IsQRCodeCard=0 and col_Status<4
								end
						end
					else
						begin
							select @Count=1 from BT_col_AutoDownloadUserForReader WITH(NOLOCK) where col_CardNo=(select cardid from BT_OpenDoor_QRCode WITH(NOLOCK) where cardid=@CardID and (cancel=1 or end_time<getdate())) and col_IsQRCodeCard=1 and col_Status<4
							if @Count=1
								begin
									Delete from BT_col_AutoDownloadUserForReader where col_CardNo=(select cardid from BT_OpenDoor_QRCode WITH(NOLOCK) where cardid=@CardID and (cancel=1 or end_time<getdate())) and col_IsQRCodeCard=1 and col_Status<4
								end
						end
					
					--Delete from BT_col_AutoDownloadUserForReader where col_UserCode=@UserCode AND col_CardNo=@CardID and col_Status in (1,9) and col_DeviceID=@ReaderID and col_CreateTime<@CreateTime--samlau 20210415
					--if @DoorNum>1 and (@SetOrClear=1 or @SetOrClear=9)--samlau 20210415
					--	begin
					--		Delete from BT_col_AutoDownloadUserForReader where col_UserCode=@UserCode AND col_CardNo=@CardID and col_Status in (1,9) and col_DeviceID in (select HostDeviceID from V_HostDevice Where HostCamera>1 AND MainReaderID=@MainReaderID) and col_CreateTime<@CreateTime 
					--	end
				end
			--else if @SetOrClear=4 or @SetOrClear=99
			--	begin
			--		Delete From BT_col_UserFaceData where col_UserCode=@UserCode and col_CardID=@CardID  
			--	end
		end
	else
		begin
			Declare @IfHadUpdate int
			set @IfHadUpdate=0
			if @SetOrClear=1 OR @SetOrClear=9
				begin
					if charindex('卡已满',@ErrorReason)>0
						begin
							set @Count=0
							select @Count=1 from BT_col_AutoDownloadUserForReader WITH(NOLOCK) where col_CardNo in (select col_CardID from BT_col_UserInfoForReader WITH(NOLOCK) where col_IsUploadToReader=99 and not exists(select col_CardID from BT_col_UserInfoForReader WITH(NOLOCK) where col_Status=1 and col_DateEnd>Getdate())) and col_DeviceID=@ReaderID and col_Status=99 and col_UpdateTime<DateAdd(day,1,@TodayDate)
							if @Count=1
								begin
									update BT_col_AutoDownloadUserForReader set col_DownloadLevel=1,col_UpdateTime='2008-01-01 '+ convert(nvarchar(8),col_UpdateTime,108) where col_ID in (select top 10 col_ID from BT_col_AutoDownloadUserForReader where col_CardNo in (select col_CardID from BT_col_UserInfoForReader WITH(NOLOCK) where col_IsUploadToReader=99 and not exists(select col_CardID from BT_col_UserInfoForReader WITH(NOLOCK) where col_Status=1 and col_DateEnd>Getdate())) and col_DeviceID=@ReaderID and col_Status=99 and col_UpdateTime<DateAdd(day,1,@TodayDate) order by col_UpdateTime)
									if @DoorNum>1--samlau 20210415
										begin
											update BT_col_AutoDownloadUserForReader set col_DownloadLevel=1,col_UpdateTime='2008-01-01 '+ convert(nvarchar(8),col_UpdateTime,108) where col_ID in (select top 10 col_ID from BT_col_AutoDownloadUserForReader where col_CardNo in (select col_CardID from BT_col_UserInfoForReader WITH(NOLOCK) where col_IsUploadToReader=99 and not exists(select col_CardID from BT_col_UserInfoForReader WITH(NOLOCK) where col_Status=1 and col_DateEnd>Getdate())) and col_DeviceID in (select HostDeviceID from V_HostDevice Where HostCamera>1 AND MainReaderID=@MainReaderID) and col_Status=99 and col_UpdateTime<DateAdd(day,1,@TodayDate) order by col_UpdateTime,col_DeviceID)
										end	
								end

							set @Count=0
							select @Count=1 from BT_col_AutoDownloadUserForReader WITH(NOLOCK) where col_DeviceID=@ReaderID and col_Status=1
							if @Count=1
								begin
									if DATEPART(hour,GetDate())<8
										begin
											update BT_col_AutoDownloadUserForReader set col_RunCount=col_RunCount+1,col_DownloadLevel=3,col_UpdateTime=dateadd(minute,60,col_UpdateTime) where col_DeviceID=@ReaderID and col_Status=1
											if @DoorNum>1--samlau 20210415
												begin
													update BT_col_AutoDownloadUserForReader set col_RunCount=col_RunCount+1,col_DownloadLevel=3,col_UpdateTime=dateadd(minute,60,col_UpdateTime) where col_DeviceID in (select HostDeviceID from V_HostDevice Where HostCamera>1 AND MainReaderID=@MainReaderID) and col_Status=1
												end
										end
									else
										begin
											update BT_col_AutoDownloadUserForReader set col_RunCount=col_RunCount+1,col_DownloadLevel=3,col_UpdateTime=dateadd(minute,10,col_UpdateTime) where col_DeviceID=@ReaderID and col_Status=1
											if @DoorNum>1--samlau 20210415
												begin
													update BT_col_AutoDownloadUserForReader set col_RunCount=col_RunCount+1,col_DownloadLevel=3,col_UpdateTime=dateadd(minute,10,col_UpdateTime) where col_DeviceID in (select HostDeviceID from V_HostDevice Where HostCamera>1 AND MainReaderID=@MainReaderID) and col_Status=1
												end
										end
								end

							set @IfHadUpdate=1

						end
					else
						begin
							set @Count=0
							select @Count=1 from BT_col_AutoDownloadUserForReader WITH(NOLOCK) where col_CardNo in (select col_CardID from BT_col_UserInfoForReader WITH(NOLOCK) where col_IsUploadToReader=99) and col_DeviceID=@ReaderID and col_Status=99 and col_UpdateTime<DateAdd(day,1,@TodayDate)
							if @Count=1
								begin
									update BT_col_AutoDownloadUserForReader set col_DownloadLevel=1 where col_ID in (select top 10 col_ID from BT_col_AutoDownloadUserForReader where col_CardNo in (select col_CardID from BT_col_UserInfoForReader WITH(NOLOCK) where col_IsUploadToReader=99) and col_DeviceID=@ReaderID and col_Status=99 and col_UpdateTime<DateAdd(day,1,@TodayDate) order by col_UpdateTime)
									if @DoorNum>1--samlau 20210415
										begin
											update BT_col_AutoDownloadUserForReader set col_DownloadLevel=1 where col_ID in (select top 10 col_ID from BT_col_AutoDownloadUserForReader where col_CardNo in (select col_CardID from BT_col_UserInfoForReader WITH(NOLOCK) where col_IsUploadToReader=99) and col_DeviceID in (select HostDeviceID from V_HostDevice Where HostCamera>1 AND MainReaderID=@MainReaderID) and col_Status=99 and col_UpdateTime<DateAdd(day,1,@TodayDate) order by col_UpdateTime)
										end
								end
						end
				end

			if @IfHadUpdate=0
				begin
					Update BT_col_AutoDownloadUserForReader set col_RunCount=col_RunCount+1,col_DownloadLevel=3,col_UpdateTime=dateadd(SECOND,POWER(col_RunCount+2,2)-1,getdate()) where col_UserCode=@UserCode AND col_CardNo=@CardID and col_DeviceID=@ReaderID and col_Status=@SetOrClear  
					Update BT_col_AutoDownloadUserForReader set col_UpdateTime=dateadd(MINUTE,-30,col_DateEnd) WHERE col_UserCode=@UserCode AND col_CardNo=@CardID and col_DeviceID=@ReaderID and col_Status=@SetOrClear and col_UpdateTime>=dateadd(MINUTE,60,col_DateStart) and col_UpdateTime>=dateadd(MINUTE,-30,col_DateEnd) and col_DownloadLevel=3
					if @DoorNum>1--samlau 20210415
						begin
							Update BT_col_AutoDownloadUserForReader set col_RunCount=col_RunCount+1,col_DownloadLevel=3,col_UpdateTime=dateadd(SECOND,POWER(col_RunCount+2,2)-1,getdate()) where col_UserCode=@UserCode AND col_CardNo=@CardID and col_DeviceID in (select HostDeviceID from V_HostDevice Where HostCamera>1 AND MainReaderID=@MainReaderID) and col_Status=@SetOrClear  
							Update BT_col_AutoDownloadUserForReader set col_UpdateTime=dateadd(MINUTE,-30,col_DateEnd) WHERE col_UserCode=@UserCode AND col_CardNo=@CardID and col_DeviceID in (select HostDeviceID from V_HostDevice Where HostCamera>1 AND MainReaderID=@MainReaderID) and col_Status=@SetOrClear and col_UpdateTime>=dateadd(MINUTE,60,col_DateStart) and col_UpdateTime>=dateadd(MINUTE,-30,col_DateEnd) and col_DownloadLevel=3
						end
				end

			if @SetOrClear=2
				begin
					Exec SaveUserFaceDownloadError @UserID,@CardID,1,@ReaderID
				end
		end

	set @Count=0
	select @Count=1 from BT_col_AutoDownloadUserForReader WITH(NOLOCK) where col_UserCode=@UserCode AND col_CardNo=@CardID and col_Status=@SetOrClear and col_DeviceID=-1
	if @Count=1
		begin
			set @Count=0
			--update BT_HostDevice set HasITimex=0 where HasITimex is null
			select @Count=Count(a.col_UserCode) from BT_col_AutoDownloadUserForReader as a WITH(NOLOCK) left join BT_col_UserInfoForReader as c WITH(NOLOCK) on a.col_UserCode=c.col_UserCode and a.col_CardNo=c.col_CardID left join (select * from BT_sys_UserReaderAccess where sys_UserCode=@UserCode and sys_CardNo=@CardID) as b on a.col_UserCode=b.sys_UserCode and a.col_CardNo=b.sys_CardNo where (a.col_DeviceID=-1 or a.col_DeviceID=@ReaderID) and a.col_UserCode=@UserCode and a.col_CardNo=@CardID and a.col_Status=@SetOrClear 
			and b.sys_ReaderID not in (
			select sys_ReaderID from BT_sys_UserDownloadRecord where sys_UserCode=a.col_UserCode and sys_CardID=a.col_CardNo and sys_SetOrClear=a.col_Status and sys_IsOK=1 and sys_CreateTime>=a.col_UpdateTime
			) 
			--select @Count=Count(a.col_UserCode) from BT_col_AutoDownloadUserForReader as a left join BT_col_UserInfoForReader as c on a.col_CardNo=c.col_CardID,V_HostDeviceForSam as b where (a.col_DeviceID=-1 or a.col_DeviceID=@ReaderID) and a.col_UserCode=@UserCode 
			--and b.HostDeviceID not in (
			--select sys_ReaderID from BT_sys_UserDownloadRecord where sys_UserCode=a.col_UserCode and sys_SetOrClear=a.col_Status and sys_IsOK=1 and sys_CreateTime>=a.col_UpdateTime
			--) 
			if @Count=0
				begin
					Delete from BT_col_AutoDownloadUserForReader where col_UserCode=@UserCode AND col_CardNo=@CardID and col_Status=@SetOrClear and col_DeviceID=-1 
				end
		end

	set @Count=0	
	if @SetorClear>1 AND @SetorClear<99
		begin
			select @Count=1 from BT_col_UserInfoForReader WITH(NOLOCK) where col_UserCode=@UserCode and col_CardID=@CardID and col_IsUploadToReader=@SetorClear
			if @Count=0
				return
		end
		
	set @Count=0
	--update BT_HostDevice set HasITimex=0 where HasITimex is null
	select @Count=Count(a.col_UserCode) from BT_col_UserInfoForReader as a WITH(NOLOCK) left join (select * from BT_sys_UserReaderAccess WITH(NOLOCK) where sys_UserCode=@UserCode and sys_CardNo=@CardID) as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode=@UserCode and col_CardID=@CardID and a.col_IsUploadToReader=@SetorClear 
	and b.sys_ReaderID not in (
	select sys_ReaderID from BT_sys_UserDownloadRecord where sys_UserCode=a.col_UserCode and sys_CardID=a.col_CardID and sys_SetOrClear=@SetorClear and sys_IsOK=1 and sys_CreateTime>=a.col_UpdateTime
	) 
	--select @Count=Count(a.col_UserCode) from BT_col_UserInfoForReader as a,V_HostDeviceForSam as b where a.col_UserCode=@UserCode and a.col_IsUploadToReader=@SetorClear 
	--and b.HostDeviceID not in (
	--select sys_ReaderID from BT_sys_UserDownloadRecord where sys_UserCode=a.col_UserCode and sys_SetOrClear=@SetorClear and sys_CreateTime>=a.col_CreateTime
	--) 

	if @Count=0
		begin				
			--update BT_col_UserInfoForReader set col_IsUploadToReader=@SetOrClear where col_UserCode=@UserCode and col_CardID=@CardID 
			if @SetOrClear=2 or @SetOrClear=99
				begin
					Delete From BT_col_TempUserFace where col_CardID=@CardID 
				end
					
 			if @SetOrClear=99 
				begin
					Delete from BT_col_UserOldCard where col_UserCode=@UserCode and col_CardNo=@CardID 
					if @IsQRCodeCard=1-- @UserCode='QRCode Scanner'
						begin
							set @Count=0
							select @Count=1 from BT_OpenDoor_QRCode WITH(NOLOCK) where cardid=@CardID  
							if @Count=0
								begin
									Delete from BT_sys_UserReaderAccess where sys_CardNo=@CardID
									Delete from BT_sys_UserReaderAccessOld where sys_CardNo=@CardID 
									Delete from BT_col_UserInfoForReader where col_UserCode=@UserCode and col_CardID=@CardID
									Delete from BT_col_UserOldCard where col_CardNo=@CardID
									Delete from BT_col_UserCardRecord where col_CardNo=@CardID
									Delete From BT_col_TempUserFace where col_CardID=@CardID 
									Delete From BT_col_UserFaceData where col_CardID=@CardID 
								end
							else
								begin
									update BT_col_CardManagement set col_State=0 where col_CardID=@CardID and col_State=1
									update BT_OpenDoor_QRCode set cancel=1 where cardid=@CardID and cancel=0
								end
						end
					else
						begin
							--set @Count=0
							--select @Count=1 from ZH_Owner WITH(NOLOCK) where CODE=@UserCode
							--if @Count=0
							--	begin
							--		Delete from BT_sys_UserReaderAccess where sys_UserCode=@UserCode
							--		Delete from BT_col_UserInfoForReader where col_UserCode=@UserCode
							--	end

							set @Count=0
							select @Count=1 from ZH_Members WITH(NOLOCK) where id=@UserID
							if @Count=0 and not exists(select 1 from ZH_Owner WITH(NOLOCK) where id=@UserID and code=@UserCode)
								begin
									Delete from BT_sys_UserReaderAccess where sys_UserCode=@UserCode
									Delete from BT_sys_UserReaderAccessOld where sys_UserCode=@UserCode 
									Delete from tb_DoorGroup_UserReaderAccess_JTCY where sys_MemberID=@UserID 
									Delete from BT_col_UserInfoForReader where col_UserCode=@UserCode and col_CardID=@CardID
									Delete from BT_col_UserOldCard where col_UserCode=@UserCode
									Delete from BT_col_UserCardRecord where col_UserCode=@UserCode
									Delete From BT_col_TempUserFace where col_UserCode=@UserCode
									Delete From BT_col_UserFaceData where col_UserCode=@UserCode 
								end

							set @Count=0
							select @Count=1 from BT_col_CardManagement WITH(NOLOCK) where col_CardID=@CardID
							if @Count=0
								begin
									Delete from BT_sys_UserReaderAccess where sys_CardNo=@CardID
									Delete from BT_sys_UserReaderAccessOld where sys_CardNo=@CardID 
									if not exists(select * from BT_col_CardManagement where col_UserID=@UserID and col_CardID<>@CardID)
										begin
											Delete from BT_sys_UserReaderAccess_JTCY where sys_memberid=@UserID
											Delete from tb_DoorGroup_UserReaderAccess_JTCY where sys_memberid=@UserID
										end					
									Delete from BT_col_UserInfoForReader where col_UserCode=@UserCode and col_CardID=@CardID --and col_IsUploadToReader=99
									Delete from BT_col_UserOldCard where col_CardNo=@CardID
									Delete from BT_col_UserCardRecord where col_CardNo=@CardID
									Delete From BT_col_TempUserFace where col_CardID=@CardID 
									Delete From BT_col_UserFaceData where col_CardID=@CardID 
								end
							else
								begin
									update BT_col_CardManagement set col_State=0 where col_CardID=@CardID and col_State=1 and col_DateEnd<GETDATE()
									update BT_OpenDoor_QRCode set cancel=1 where cardid=@CardID and cancel=0
								end
						end
						
					if @UserAddress>0
						begin
							update BT_col_UserIDAndAddress set col_IsDel=1 where col_UserAddress=@UserAddress AND col_UserID>0 and col_UserID=@UserID and col_CardID=@CardID
						end
				end

		end
		
	set @Count=0
	SELECT @Count=1 FROM BT_col_AutoDownloadUserForReader WITH(NOLOCK) where 1=1
	if @Count=0
		begin
			Truncate table BT_col_AutoDownloadUserForReader
		end
END
