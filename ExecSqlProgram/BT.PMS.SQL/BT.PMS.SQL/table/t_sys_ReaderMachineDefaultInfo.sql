--USE [BT_PMS]
--GO

--/****** Object:  Table [dbo].[t_sys_ReaderMachineDefaultInfo]    Script Date: 2019/10/21 19:59:03 ******/
--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO

--SET ANSI_PADDING ON
--GO

--CREATE TABLE [dbo].[t_sys_ReaderMachineDefaultInfo](
--	[col_ReaderTypeName] [nvarchar](64) NOT NULL,
--	[col_ReaderType] [varbinary](max) NOT NULL,
--	[col_ReaderInfo] [varbinary](max) NOT NULL,
-- CONSTRAINT [PK_t_sys_ReaderMachineDefaultInfo] PRIMARY KEY CLUSTERED 
--(
--	[col_ReaderTypeName] ASC
--)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
--) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

--GO

--SET ANSI_PADDING OFF
--GO


/*
IF Not exists(SELECT * FROM t_sys_ReaderMachineDefaultInfo)
	BEGIN
		INSERT INTO t_sys_ReaderMachineDefaultInfo 
		select Readername,ReaderType,ReaderInfo from TAMS.DBO.t_sys_ReaderMachine where MachineType in ('716EV3','721H','721HNet','727HV5','837E','837EF','725EV2')
	END

IF NOT EXISTS (select 1 from t_sys_ReaderMachineDefaultInfo where col_ReaderTypeName=N'725EV2')
	begin
		select Readername,ReaderType,ReaderInfo from TAMS.DBO.t_sys_ReaderMachine where MachineType='725EV2'
	end
*/
declare @temp_ReaderInfo [varbinary](max),@temp_Version varchar(10),@temp_ReaderTypeName nvarchar(64);


IF NOT EXISTS (select name from syscolumns where id=object_id(N't_sys_ReaderMachineDefaultInfo') AND NAME='col_Version')   alter table t_sys_ReaderMachineDefaultInfo add col_Version varchar(10);

IF NOT EXISTS (select 1 from t_sys_ReaderMachineDefaultInfo where col_ReaderTypeName=N'716EV3')
	INSERT INTO [t_sys_ReaderMachineDefaultInfo] ([col_ReaderTypeName],[col_Version],[col_ReaderType],[col_ReaderInfo]) VALUES (N'716EV3','',0x0300,0x8000000000000000000000000000000000000005DC05DC02BC02BC0064006400000000045708AE0D05115C15B31A0A1E6122B8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000);
IF NOT EXISTS (select 1 from t_sys_ReaderMachineDefaultInfo where col_ReaderTypeName=N'721H')
	INSERT INTO [t_sys_ReaderMachineDefaultInfo] ([col_ReaderTypeName],[col_Version],[col_ReaderType],[col_ReaderInfo]) VALUES (N'721H','',0x4900,0x300002BC0001E24002BC02BC0064006405DC04D20100);
IF NOT EXISTS (select 1 from t_sys_ReaderMachineDefaultInfo where col_ReaderTypeName=N'721HNet')
	INSERT INTO [t_sys_ReaderMachineDefaultInfo] ([col_ReaderTypeName],[col_Version],[col_ReaderType],[col_ReaderInfo]) VALUES (N'721HNet','',0x4900,0x300002BC0001E24002BC02BC0064006405DC04D200);

/**********725EV2*************/
SET @temp_ReaderTypeName=N'725EV2';
SET @temp_Version='20210429';
SET @temp_ReaderInfo=0x01020001E240000000000000000004D210E100000000006402BC02BC000F000000100F0F0008000101011C01050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
IF NOT EXISTS (select 1 from t_sys_ReaderMachineDefaultInfo where col_ReaderTypeName=@temp_ReaderTypeName)
	begin
		INSERT INTO [t_sys_ReaderMachineDefaultInfo] ([col_ReaderTypeName],[col_Version],[col_ReaderType],[col_ReaderInfo]) VALUES (@temp_ReaderTypeName,@temp_Version,0x4E29C100,@temp_ReaderInfo);
	end
else
	begin
		  IF NOT EXISTS (select 1 from t_sys_ReaderMachineDefaultInfo where col_ReaderTypeName=@temp_ReaderTypeName and ISNULL([col_Version],'')=@temp_Version)
			begin
				UPDATE t_sys_ReaderMachineDefaultInfo SET [col_Version]=@temp_Version,[col_ReaderInfo]=@temp_ReaderInfo where col_ReaderTypeName=@temp_ReaderTypeName
			end
	end

/**********727HV5*************/
IF NOT EXISTS (select 1 from t_sys_ReaderMachineDefaultInfo where col_ReaderTypeName=N'727HV5')
	INSERT INTO [t_sys_ReaderMachineDefaultInfo] ([col_ReaderTypeName],[col_Version],[col_ReaderType],[col_ReaderInfo]) VALUES (N'727HV5','',0xC625C200,0x01020001E240000000000000000004D210E100000000006402BC02BC000F000000100F0F0008000101011C01050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000);

/**********837E*************/
SET @temp_ReaderTypeName=N'837E';
SET @temp_Version='20210429';
SET @temp_ReaderInfo=0x01020001E240000000000000000004D210E100000000006402BC02BC000F000000100F0F0008000101011C01050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
IF NOT EXISTS (select 1 from t_sys_ReaderMachineDefaultInfo where col_ReaderTypeName=@temp_ReaderTypeName)
	begin
		INSERT INTO [t_sys_ReaderMachineDefaultInfo] ([col_ReaderTypeName],[col_Version],[col_ReaderType],[col_ReaderInfo]) VALUES (@temp_ReaderTypeName,@temp_Version,0xC425C200,@temp_ReaderInfo);
	end
else
	begin
		  IF NOT EXISTS (select 1 from t_sys_ReaderMachineDefaultInfo where col_ReaderTypeName=@temp_ReaderTypeName and ISNULL([col_Version],'')=@temp_Version)
			begin
				UPDATE t_sys_ReaderMachineDefaultInfo SET [col_Version]=@temp_Version,[col_ReaderInfo]=@temp_ReaderInfo where col_ReaderTypeName=@temp_ReaderTypeName
			end
	end

/**********837EF*************/
IF NOT EXISTS (select 1 from t_sys_ReaderMachineDefaultInfo where col_ReaderTypeName=N'837EF')
	INSERT INTO [t_sys_ReaderMachineDefaultInfo] ([col_ReaderTypeName],[col_Version],[col_ReaderType],[col_ReaderInfo]) VALUES (N'837EF','',0xC525C500,0x01010001E240000000000000000004D210E100000000006402BC02BC000F000000100F0F0008000101031C01050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000);


/**********Octopus-725EV2*************/
SET @temp_ReaderTypeName=N'Octopus-725EV2';
SET @temp_Version='20210429';
SET @temp_ReaderInfo=0x01020001E240000000000000000004D210E100000000006402BC02BC000F000000100F0F0008000101011C01050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
IF NOT EXISTS (select 1 from t_sys_ReaderMachineDefaultInfo where col_ReaderTypeName=@temp_ReaderTypeName)
	begin
		INSERT INTO [t_sys_ReaderMachineDefaultInfo] ([col_ReaderTypeName],[col_Version],[col_ReaderType],[col_ReaderInfo]) VALUES (@temp_ReaderTypeName,@temp_Version,0x4E29C100,@temp_ReaderInfo);
	end
else
	begin
		  IF NOT EXISTS (select 1 from t_sys_ReaderMachineDefaultInfo where col_ReaderTypeName=@temp_ReaderTypeName and ISNULL([col_Version],'')=@temp_Version)
			begin
				UPDATE t_sys_ReaderMachineDefaultInfo SET [col_Version]=@temp_Version,[col_ReaderInfo]=@temp_ReaderInfo where col_ReaderTypeName=@temp_ReaderTypeName
			end
	end

/**********Octopus-837E*************/
SET @temp_ReaderTypeName=N'Octopus-837E';
SET @temp_Version='20210429';
SET @temp_ReaderInfo=0x01020001E240000000000000000004D210E100000000006402BC02BC000F000000100F0F0008000101011C0105000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
IF NOT EXISTS (select 1 from t_sys_ReaderMachineDefaultInfo where col_ReaderTypeName=@temp_ReaderTypeName)--added by warren on 2021-04-30
	begin
		INSERT INTO [t_sys_ReaderMachineDefaultInfo] ([col_ReaderTypeName],[col_Version],[col_ReaderType],[col_ReaderInfo]) VALUES (@temp_ReaderTypeName,@temp_Version,0xC425C200,@temp_ReaderInfo);
	end
else
	begin
		  IF NOT EXISTS (select 1 from t_sys_ReaderMachineDefaultInfo where col_ReaderTypeName=@temp_ReaderTypeName and ISNULL([col_Version],'')=@temp_Version)
			begin
				UPDATE t_sys_ReaderMachineDefaultInfo SET [col_Version]=@temp_Version,[col_ReaderInfo]=@temp_ReaderInfo where col_ReaderTypeName=@temp_ReaderTypeName
			end
	end