--USE [BT_PMS]
--drop table BT_HostDeviceType
--GO

IF Not exists(SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'BT_HostDeviceType') and type=N'U')
	begin 

--/****** Object:  Table [dbo].[BT_HostDeviceType]    Script Date: 2021-04-14 11:51:55 ******/
----SET ANSI_NULLS ON
----GO

--SET QUOTED_IDENTIFIER ON
--GO

CREATE TABLE [dbo].[BT_HostDeviceType](
	[col_ID] [int] NOT NULL,
	[col_DeviceName] [nvarchar](50) NOT NULL,
	[col_Type] [int] NOT NULL CONSTRAINT [DF_BT_HostDeviceType_col_Type]  DEFAULT ((1)),
	[col_DoorNum] [int] NOT NULL CONSTRAINT [DF_BT_HostDeviceType_col_DoorNum]  DEFAULT ((1)),
	[col_BrandID] [int] NOT NULL,
	[col_Hidden] [bit] NOT NULL CONSTRAINT [DF_BT_HostDeviceType_col_Hidden]  DEFAULT ((0)),
	[col_Remark] [nvarchar](512) NULL,
	[col_CreateTime] [DateTime] NOT NULL CONSTRAINT [DF_BT_HostDeviceType_col_CreateTime]  DEFAULT ((GetDate())),
 CONSTRAINT [PK_BT_HostDeviceType] PRIMARY KEY CLUSTERED 
(
	[col_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
 

--col_Type:1 ¿¨™C£»2 ¿ØÖÆÆ÷
	end
GO

IF Not exists(SELECT * FROM [BT_HostDeviceType])
	BEGIN
		insert into BT_HostDeviceType(col_ID,col_DeviceName,col_Type,col_DoorNum,col_BrandID,col_Hidden,col_Remark,col_CreateTime) select 1,'DS-K1T671TM-3XF',1,1,13,0,'',GETDATE()
		insert into BT_HostDeviceType(col_ID,col_DeviceName,col_Type,col_DoorNum,col_BrandID,col_Hidden,col_Remark,col_CreateTime) select 2,'DS-K2604',2,4,13,0,'',GETDATE()
		insert into BT_HostDeviceType(col_ID,col_DeviceName,col_Type,col_DoorNum,col_BrandID,col_Hidden,col_Remark,col_CreateTime) select 3,'DHI-VTO9331D',1,1,14,0,'',GETDATE()
		insert into BT_HostDeviceType(col_ID,col_DeviceName,col_Type,col_DoorNum,col_BrandID,col_Hidden,col_Remark,col_CreateTime) select 4,'DHI-ASI1201A',1,1,14,0,'',GETDATE()
		insert into BT_HostDeviceType(col_ID,col_DeviceName,col_Type,col_DoorNum,col_BrandID,col_Hidden,col_Remark,col_CreateTime) select 5,'837E',1,1,15,0,'',GETDATE()
	END

IF NOT EXISTS (select 1 from BT_HostDeviceType where col_DeviceName=N'AR-725-ESR11B1-A')
	begin
		insert into BT_HostDeviceType(col_ID,col_DeviceName,col_Type,col_DoorNum,col_BrandID,col_Hidden,col_Remark,col_CreateTime) select 6,'AR-725-ESR11B1-A',1,1,15,0,'',GETDATE()--725EV2
	end

IF NOT EXISTS (select 1 from BT_HostDeviceType where col_DeviceName=N'DS-K1T802E')
	begin
		insert into BT_HostDeviceType(col_ID,col_DeviceName,col_Type,col_DoorNum,col_BrandID,col_Hidden,col_Remark,col_CreateTime) select 7,'DS-K1T802E',1,1,13,0,'',GETDATE()
	end


--Added by warren on 2021-04-28
IF NOT EXISTS (select 1 from BT_HostDeviceType where col_DeviceName=N'Octopus-837E')
	begin
		insert into BT_HostDeviceType(col_ID,col_DeviceName,col_Type,col_DoorNum,col_BrandID,col_Hidden,col_Remark,col_CreateTime) select 10,'Octopus-837E',1,1,15,0,'',GETDATE()--837E
	end

 --Added by warren on 2021-05-06
 IF NOT EXISTS (select 1 from BT_HostDeviceType where col_BrandID=16 AND col_DeviceName=N'WG(Registration reader)')
	begin
		INSERT INTO [dbo].[BT_HostDeviceType]
				   ([col_ID]
				   ,[col_DeviceName]
				   ,[col_Type]
				   ,[col_DoorNum]
				   ,[col_BrandID]
				   ,[col_Hidden]
				   ,[col_Remark]
				   ,[col_CreateTime])
			 VALUES
				   (11
				   ,N'WG(Registration reader)'
				   ,1
				   ,1
				   ,16
				   ,0
				   ,N''
				   ,GETDATE())
	end

 IF NOT EXISTS (select 1 from BT_HostDeviceType where col_BrandID=16 AND col_DeviceName=N'Standard(Registration reader)')
	begin
		INSERT INTO [dbo].[BT_HostDeviceType]
				   ([col_ID]
				   ,[col_DeviceName]
				   ,[col_Type]
				   ,[col_DoorNum]
				   ,[col_BrandID]
				   ,[col_Hidden]
				   ,[col_Remark]
				   ,[col_CreateTime])
			 VALUES
				   (12
				   ,N'Standard(Registration reader)'
				   ,1
				   ,1
				   ,16
				   ,0
				   ,N''
				   ,GETDATE())
	end
	--

 IF NOT EXISTS (select 1 from BT_HostDeviceType where col_BrandID=16 AND col_DeviceName=N'Standard(Access control reader)')
	begin
		INSERT INTO [dbo].[BT_HostDeviceType]
				   ([col_ID]
				   ,[col_DeviceName]
				   ,[col_Type]
				   ,[col_DoorNum]
				   ,[col_BrandID]
				   ,[col_Hidden]
				   ,[col_Remark]
				   ,[col_CreateTime])
			 VALUES
				   (13
				   ,N'Standard(Access control reader)'
				   ,1
				   ,1
				   ,16
				   ,0
				   ,N''
				   ,GETDATE())
	end
	
--Added by warren on 2021-05-12
IF NOT EXISTS (select * from BT_HostDeviceType where col_DeviceName=N'Octopus-725EV2')
	begin
		insert into BT_HostDeviceType(col_ID,col_DeviceName,col_Type,col_DoorNum,col_BrandID,col_Hidden,col_Remark,col_CreateTime) select 14,'Octopus-725EV2',1,1,15,0,'',GETDATE()--837E
	end
