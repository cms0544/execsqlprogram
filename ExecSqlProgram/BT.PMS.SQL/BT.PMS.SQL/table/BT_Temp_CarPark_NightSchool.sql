if(not exists(select xtype from sysobjects where id = OBJECT_ID('BT_Temp_CarPark_NightSchool') and xtype = 'U'))
   begin

	CREATE TABLE [dbo].[BT_Temp_CarPark_NightSchool](
		[EnglishName] [nvarchar](100) NULL,
		[ChineseName] [nvarchar](100) NULL,
		[Rankstr] [nvarchar](100) NULL,
		[Dept] [nvarchar](100) NULL,
		[Mobile] [nvarchar](100) NULL,
		[Extension] [nvarchar](100) NULL,
		[Email] [nvarchar](200) NULL,
		[CarPlateNo] [nvarchar](100) NULL,
		[TypeofVehicle] [nvarchar](100) NULL,
		[StartDate] [datetime] NULL,
		[EndDate] [datetime] NULL,
		[Monday] [nvarchar](100) NULL,
		[Tuesday] [nvarchar](100) NULL,
		[Wednesday] [nvarchar](100) NULL,
		[Thursday] [nvarchar](100) NULL,
		[Friday] [nvarchar](100) NULL,
		[Saturday] [nvarchar](100) NULL,
		[Sunday] [nvarchar](100) NULL
	) ON [PRIMARY]

 end


