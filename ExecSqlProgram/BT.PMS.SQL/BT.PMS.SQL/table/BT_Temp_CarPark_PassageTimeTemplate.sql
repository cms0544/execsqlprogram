if(not exists(select xtype from sysobjects where id = OBJECT_ID('BT_Temp_CarPark_PassageTimeTemplate') and xtype = 'U'))
   begin

		CREATE TABLE [dbo].[BT_Temp_CarPark_PassageTimeTemplate](
			[EnglishName] [nvarchar](100) NULL,
			[ChineseName] [nvarchar](100) NULL,
			[Rankstr] [nvarchar](100) NULL,
			[Dept] [nvarchar](100) NULL,
			[PersonnelType] [nvarchar](100) NULL,
			[Mobile] [nvarchar](100) NULL,
			[Extension] [nvarchar](100) NULL,
			[Email] [nvarchar](100) NULL,
			[CarPlateNo] [nvarchar](100) NULL,
			[TypeofVehicle] [nvarchar](100) NULL,
			[StartTime] [datetime] NULL,
			[EndTime] [datetime] NULL
		) ON [PRIMARY]

	end


