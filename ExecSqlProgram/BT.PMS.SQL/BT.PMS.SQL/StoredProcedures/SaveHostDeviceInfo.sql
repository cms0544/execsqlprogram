--USE [BT_PMS]
IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'SaveHostDeviceInfo') and xtype='P')  DROP PROCEDURE [dbo].[SaveHostDeviceInfo]
GO
/****** Object:  StoredProcedure [dbo].[SaveHostDeviceInfo]    Script Date: 2021/03/05 18:37:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<samlau>
-- Create date: <2021-03-05>
-- Description:	<保存設備信息>
--exec SaveHostDeviceInfo 0,1,1,'716EV3','192.168.7.55',1621,0,0,'','',1,'716EV3',1,0,1
--select * from t_Soyal_Area
--select * from t_Soyal_ConnPort
--select * from BT_HostDevice
--select * from t_sys_ReaderMachine
--delete from BT_HostDevice
--delete from t_sys_ReaderMachine

--exec SaveHostDeviceInfo 0,1,1,1,'837E','192.168.7.55',1621,0,0,'','',1,'837E',1,1,15,1,0,1
--exec SaveHostDeviceInfo 34,1,1,1,'837E','192.168.7.55',1621,0,0,'','',1,'837E',1,1,15,1,0,1
--exec SaveHostDeviceInfo 35,1,2,2,'837E2','192.168.7.56',1621,0,0,'','',1,'837E',1,1,15,1,0,1
-- =============================================
CREATE PROCEDURE [dbo].[SaveHostDeviceInfo](
@ID int,--自增ID，修改時傳值
@FC_lgid int,
@MainDeviceID int,--站號
@DeviceID int,--副卡機時為副站號,否則為站號
@DeviceName nvarchar(125),
@IPAddress nvarchar(64),
@Port int,
@CommID int=0,
@Rate int=0,
@UserName nvarchar(64)='',
@PassWord nvarchar(64)='',
@ConnectType int=1,
@DeviceType nvarchar(64)='837E',
@InOutType int=1,
@IsMainDevice int=1,--0 勾選副站號
@BrandType int=15,
@DoorID int=1,
@IsCardRegReader int=-1,
@IsEnabled int=1,
@NeedTemperature bit=0,
@IsOctDevice bit=0,
@IsClubHouse bit=0,
@HasQRCode bit=0,
@HasFace bit=0
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	Declare @AreaID int,@Count int,@ConnPortID int,@tmpConnPortID int,@ReaderID int,@ReaderLOGO nvarchar(16),@oldConnPortID int,@oldReaderLOGO nvarchar(16),@oldMainDeviceID int,@oldDeviceID int,@oldDeviceName nvarchar(125),@oldDeviceType nvarchar(64),@oldIsMainDevice int,@olcConnectType int,@MainControllerID int,@ReaderType varbinary(MAX),@ReaderInfo varbinary(MAX)
	set @AreaID=0
	set @ConnPortID=0
	set @ReaderLOGO=''
	set @ReaderID=0
	select top 1 @AreaID=sslpid from FC_LG WHERE lgid=@FC_lgid
	set @AreaID=@AreaID+100--小區ID+100
	set @Count=0
	select top 1 @Count=1 from t_Soyal_Area where ID=@AreaID
	if @Count=0 and @BrandType=15
		begin
			insert into t_Soyal_Area(ID,AreaID,AreaName) select @AreaID,@AreaID,'區域 '+Cast(@AreaID as nvarchar(16))
		end
    SET @IsMainDevice=1
	if @DeviceType=''
		begin
			SET @DeviceType='837E'
			--if @ConnectType=1
			--	begin
			--		if @IsMainDevice=1
			--			begin
			--				set @DeviceType='716EV3'--721H
			--			end
			--		else
			--			begin
			--				set @DeviceType='721HNet'
			--			end
			--	end
			--else
			--	begin
			--		  set @DeviceType='727HV5'	
			--	end
		end

	if @IsMainDevice=1
		begin
			set @DeviceID=@MainDeviceID 
		end

	if @IsCardRegReader=-1
		begin
			set @IsCardRegReader=0
			if @ConnectType=2
				begin
					set @IsCardRegReader=1
				end
		end
		
	Declare @OldIsEnabled as int
	set @OldIsEnabled=1

	declare @isNewReader int
	set @isNewReader=0
	declare @result int,@messageinfo nvarchar(max)
	set @result=0
	SET @messageinfo=''
	declare @deleted int
	if @IsEnabled=1
		begin
			set @deleted=0
		end
	else
		begin
			set @deleted=1
		end

	if @ID<=0
		begin
			if(exists(select 1 from BT_HostDevice WHERE AreaID=@AreaID AND HostName=@DeviceName and deleted=0))
				begin
					set @result=-1
					set @messageinfo='設備名稱重複！'
					select @result
					return @result
				end

			if(exists(select 1 from BT_HostDevice WHERE AreaID=@AreaID AND ISNULL(HostIP,'')=@IPAddress and ISNULL(HostPort,0)=@Port and ISNULL(Com,0)=@CommID and ISNULL(Rate,0)=@Rate and deleted=0)) --and MainReaderID=@MainDeviceID and ReaderID=@DeviceID
				begin
					set @result=-2
					set @messageinfo='設備信息重複！'
					select @result
					return @result
				end
			 
			if(@IsMainDevice=1 and exists(select 1 from BT_HostDevice WHERE AreaID=@AreaID AND IsMainDevice=@IsMainDevice and MainReaderID=@MainDeviceID and ReaderID=@DeviceID and deleted=0))
				begin
					set @result=-3
					set @messageinfo='設備站號重複！'
					select @result
					return @result
				end 
				
			if @ConnectType=1
				begin
					set @CommID=NULL
					set @Rate=NULL
				end
			else
				begin
					set @IPAddress=NULL
					set @Port=NULL
				end

			set @isNewReader=1
			insert into BT_HostDevice(FC_lgid,AreaID,MainReaderID,ReaderID,HostName,HostIP,HostPort,Intranet_HostIP,Intranet_HostPort,Com,Rate,HostLoginUser,HostLoginPassword,HostConnectType,DeviceType,BrandID,IsMainDevice,InOutType,IsCardMachine,Deleted,CreatedTime,UpdatedTime,HasITimex,DoorID,ReaderLOGO,HostCamera,HasVSM,HasVidosoft,HasCams,HasRemoteManagement,HasStayingStatistics,HasFaceStatistics,HasHeatMap,HasVTO,IsControlRoomVTO,HasQRCode,HasFace,NeedTemperature,IsOctDevice,IsClubHouse)
			select @FC_lgid,@AreaID,@MainDeviceID,@DeviceID,@DeviceName,@IPAddress,@Port,@IPAddress,@Port,@CommID,@Rate,@UserName,@PassWord,@ConnectType,@DeviceType,@BrandType,@IsMainDevice,@InOutType,@IsCardRegReader,@deleted,GETDATE(),GETDATE(),1,@DoorID,'',1,0,0,0,0,0,0,0,0,0,@HasQRCode,@HasFace,@NeedTemperature,@IsOctDevice,@IsClubHouse
			select @ID=max(HostDeviceID) from BT_HostDevice
		end
	else
		begin
			if(exists(select 1 from BT_HostDevice WHERE HostDeviceID<>@ID AND AreaID=@AreaID and HostName=@DeviceName and deleted=0))
				begin
					set @result=-1
					set @messageinfo='設備名稱重複！'
					select @result
					return @result
				end
			if(exists(select 1 from BT_HostDevice WHERE HostDeviceID<>@ID AND AreaID=@AreaID AND ISNULL(HostIP,'')=@IPAddress and ISNULL(HostPort,0)=@Port and ISNULL(Com,0)=@CommID and ISNULL(Rate,0)=@Rate and deleted=0))-- and MainReaderID=@MainDeviceID and ReaderID=@DeviceID
				begin
					set @result=-2
					set @messageinfo='設備信息重複！'
					select @result
					return @result
				end
				
			if(exists(select 1 from BT_HostDevice WHERE HostDeviceID<>@ID AND AreaID=@AreaID AND IsMainDevice=@IsMainDevice and MainReaderID=@MainDeviceID and ReaderID=@DeviceID and deleted=0))
				begin
					set @result=-3
					set @messageinfo='設備站號重複！'
					select @result
					return @result
				end 
				
			select @OldIsEnabled=Deleted from BT_HostDevice WHERE HostDeviceID=@ID
			set @oldConnPortID=0
			set @olcConnectType=0
			set @oldMainDeviceID=0
			set @oldDeviceID=0
			set @oldDeviceName=''
			set @oldIsMainDevice=0
			select @oldMainDeviceID=MainReaderID,@oldDeviceID=ReaderID,@oldDeviceName=HostName,@oldIsMainDevice=IsMainDevice,@olcConnectType=HostConnectType,@ReaderLOGO=ReaderLOGO from BT_HostDevice where HostDeviceID=@ID
--select @ID,@oldMainDeviceID,@oldDeviceID,@oldDeviceName,@IsMainDevice,@oldReaderLOGO

			select @ReaderID=ID,@oldConnPortID=connportID,@MainControllerID=MainControllerID from t_sys_ReaderMachine where ReaderLOGO=@ReaderLOGO
				--select @ReaderID,@oldConnPortID,@ReaderLOGO
		   select @oldConnPortID=TheConnPortID from t_Soyal_ConnPort where ID=@oldConnPortID

			if @ConnectType=1
				begin
					set @CommID=NULL
					set @Rate=NULL
				end
			else
				begin
					set @IPAddress=NULL
					set @Port=NULL
				end

			update BT_HostDevice set FC_lgid=@FC_lgid,MainReaderID=@MainDeviceID,ReaderID=@DeviceID,HostName=@DeviceName,HostIP=@IPAddress,HostPort=@Port,Intranet_HostIP=@IPAddress,Intranet_HostPort=@Port,Com=@CommID,Rate=@Rate,HostLoginUser=@UserName,HostLoginPassword=@PassWord,HostConnectType=@ConnectType,DeviceType=@DeviceType,BrandID=@BrandType,IsMainDevice=@IsMainDevice,InOutType=@InOutType,IsCardMachine=@IsCardRegReader,Deleted=@deleted,UpdatedTime=getdate(),DoorID=@DoorID,HasQRCode=@HasQRCode,HasFace=@HasFace,NeedTemperature=@NeedTemperature,IsOctDevice=@IsOctDevice,IsClubHouse=@IsClubHouse where HostDeviceID=@ID
		end 

	if @BrandType<>15
		begin
			if @BrandType=13
				begin
					set @ReaderLOGO='H000000000' + right('000000' + cast(@ID as nvarchar(16)),6)
				end
			else if @BrandType=16--added by warren 
				begin
					set @ReaderLOGO='O000000000' + right('000000' + cast(@ID as nvarchar(16)),6)
				end
			else
				begin
					set @ReaderLOGO='D000000000' + right('000000' + cast(@ID as nvarchar(16)),6)
				end

			update BT_HostDevice set ReaderLOGO=@ReaderLOGO where HostDeviceID=@ID
			truncate table BT_sys_IfNeedReStartServer
			insert into BT_sys_IfNeedReStartServer select 1,1,dateadd(minute,1,Getdate())

			Delete From BT_sys_ReaderOnlineStatus where sys_DeviceID=@ID 

			select @ID
			return @ID
		end

	set @ConnPortID=@MainDeviceID 
	if @IsMainDevice=1
		begin
			set @MainDeviceID=0
		end
--select @oldConnPortID
	if @ConnPortID is not null and @ConnPortID<>@oldConnPortID
		begin
			Delete From t_Soyal_ConnPort where AreaID=@AreaID and TheConnPortID=@oldConnPortID
		end
		
	set @Count=0
	if @ConnectType=1
		begin
			select top 1 @Count=ID from t_Soyal_ConnPort where AreaID=@AreaID and TheConnPortID=@ConnPortID -- ConnPortType='SoyalTCPIP' and AreaID=@AreaID and ConnPortIP=@IPAddress
	 		if @Count=0 
				begin
					insert into t_Soyal_ConnPort(TheConnPortID,AreaID,ConnPortName,ConnPortType,ConnPortCOM,ConnPortBaud,ConnPortIP,ConnPortTCPPort)
					select @ConnPortID,@AreaID,'TCP/IP','SoyalTCPIP',NULL,NULL,@IPAddress,@Port
					select @ConnPortID=max(ID) from t_Soyal_ConnPort
				end
			else 
				begin
					update t_Soyal_ConnPort set ConnPortName='TCP/IP',ConnPortType='SoyalTCPIP',ConnPortCOM=NULL,ConnPortBaud=NULL,ConnPortIP=@IPAddress,ConnPortTCPPort=@Port where AreaID=@AreaID and TheConnPortID=@ConnPortID
					select @ConnPortID=ID from t_Soyal_ConnPort where AreaID=@AreaID and TheConnPortID=@ConnPortID
				end
		end
	else
		begin
			select top 1 @Count=ID from t_Soyal_ConnPort where AreaID=@AreaID and TheConnPortID=@ConnPortID -- and ConnPortType='SoyalCOM' 
			if @Count=0
				begin
					insert into t_Soyal_ConnPort(TheConnPortID,AreaID,ConnPortName,ConnPortType,ConnPortCOM,ConnPortBaud,ConnPortIP,ConnPortTCPPort)
					select @ConnPortID,@AreaID,'COM Port','SoyalCOM',@CommID,@Rate,NULL,NULL
					select @ConnPortID=max(ID) from t_Soyal_ConnPort
				end
			else
				begin
					update t_Soyal_ConnPort set ConnPortName='COM Port',ConnPortType='SoyalCOM',ConnPortCOM=@CommID,ConnPortBaud=@Rate,ConnPortIP=NULL,ConnPortTCPPort=NULL where AreaID=@AreaID and TheConnPortID=@ConnPortID
					select @ConnPortID=ID from t_Soyal_ConnPort where AreaID=@AreaID and TheConnPortID=@ConnPortID
				end
		end

	if @DeviceType='AR-725-ESR11B1-A'
		begin
			set @DeviceType='725EV2'
		end

	if @DeviceType='Octopus-837E'
		begin
			select @ReaderType=col_ReaderType,@ReaderInfo=col_ReaderInfo from t_sys_ReaderMachineDefaultInfo where col_ReaderTypeName=@DeviceType
			set @DeviceType='837E'
		end

	if @DeviceType='Octopus-725EV2'
		begin
			select @ReaderType=col_ReaderType,@ReaderInfo=col_ReaderInfo from t_sys_ReaderMachineDefaultInfo where col_ReaderTypeName=@DeviceType
			set @DeviceType='725EV2'
		end

	if @DeviceType='716EV3' and @IsMainDevice=1
		begin
			set @ReaderLOGO='S' + right('000' + cast(@AreaID as nvarchar(16)),3) + right('000' + cast(@DeviceID as nvarchar(16)),3) + right('000',3) + right('000',3) + '000'
		end
	else if @DeviceType='721HNet' and @IsMainDevice=0
		begin
			set @ReaderLOGO='S' + right('000' + cast(@AreaID as nvarchar(16)),3) + right('000' + cast(@MainDeviceID as nvarchar(16)),3) + right('000' + cast(@DeviceID as nvarchar(16)),3) + right('000',3) + '000'
		end
	else
		begin
			set @ReaderLOGO='S' + right('000' + cast(@AreaID as nvarchar(16)),3) + right('000',3) + right('000' + cast(@DeviceID as nvarchar(16)),3) + right('000',3) + '000'
		end

	update BT_HostDevice set ReaderLOGO=@ReaderLOGO where HostDeviceID=@ID

	if @ReaderType is null--注意：如果是八達通的，會在上面先取值
		begin
			select @ReaderType=col_ReaderType,@ReaderInfo=col_ReaderInfo from t_sys_ReaderMachineDefaultInfo where col_ReaderTypeName=@DeviceType
		end

	Declare @ReaderMachineBrandType int =2

	if @BrandType=16--智慧屋苑八達通
		begin
				SET @ReaderMachineBrandType=6;--itimex八達通
		end

	set @MainControllerID=0
	if @IsMainDevice=0
		begin
			select @MainControllerID=ID from t_sys_ReaderMachine where connportID=@ConnPortID and ReaderID=@MainDeviceID and MainControllerID=0
			if @MainControllerID=0
				begin
					insert into t_sys_ReaderMachine(ReaderLOGO,ReaderID,connportID,MainControllerID,MainReaderID,ReaderType,Readername,DoorNo,ReaderInfo,MachineType,CityCodeForReader,BrandType)
					select @ReaderLOGO,@DeviceID,@ConnPortID,0,0,@ReaderType,@DeviceName,@DeviceID,@ReaderInfo,@DeviceType,'',@ReaderMachineBrandType
					select @MainControllerID=ID from t_sys_ReaderMachine where connportID=@ConnPortID and ReaderID=@DeviceID and MainControllerID=0
				end
		end
		
	if @IsMainDevice=0
		begin
			set @ConnPortID=0
		end

	if @ReaderID=0
		begin
			insert into t_sys_ReaderMachine(ReaderLOGO,ReaderID,connportID,MainControllerID,MainReaderID,ReaderType,Readername,DoorNo,ReaderInfo,MachineType,CityCodeForReader,BrandType)
			select @ReaderLOGO,@DeviceID,@ConnPortID,@MainControllerID,0,@ReaderType,@DeviceName,@DeviceID,@ReaderInfo,@DeviceType,'',@ReaderMachineBrandType
		end
	else
		begin
			update t_sys_ReaderMachine set ReaderLOGO=@ReaderLOGO,ReaderID=@DeviceID,connportID=@ConnPortID,MainControllerID=@MainControllerID,ReaderType=@ReaderType,Readername=@DeviceName,DoorNo=@DeviceID,ReaderInfo=@ReaderInfo,MachineType=@DeviceType,BrandType=@ReaderMachineBrandType where ID=@ReaderID
		end

	truncate table BT_sys_IfNeedReStartServer
	insert into BT_sys_IfNeedReStartServer select 1,1,dateadd(minute,1,Getdate())

	Delete From BT_sys_ReaderOnlineStatus where sys_DeviceID=@ID 
	--if @isNewReader=1 or (@isNewReader=0 and @OldIsEnabled=0 and @IsEnabled=1)
	--	begin
	--		exec SaveAutoDownloadUserCardForInitReader @ID
	--	end 
	
	select @ID
	return @ID

END
