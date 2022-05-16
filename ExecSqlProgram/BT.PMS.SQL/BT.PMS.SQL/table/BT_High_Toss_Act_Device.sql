
/****** Object:  Table [dbo].[BT_High_Toss_Act_Device]    Script Date: 2021/5/27 16:18:42 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO
IF Not exists(SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'BT_High_Toss_Act_Device') and type=N'U')
begin 
CREATE TABLE [dbo].[BT_High_Toss_Act_Device](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[device_name] [varchar](200) NOT NULL,
	[device_account] [varchar](100) NOT NULL,
	[device_password] [varchar](200) NOT NULL,
	[device_ip] [varchar](50) NULL,
	[device_port] [int] NOT NULL,
	[device_housing_estate] [int] NULL,
	[device_ridgepole] [int] NULL,
	[device_code] [varchar](100) NOT NULL,
	[device_floor_begin] [int] NULL,
	[device_floor_end] [int] NULL,
	[device_creater] [varchar](50) NULL,
	[update_time] [datetime] NULL,
	[created_time] [datetime] NULL,
	[device_planar] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
end
GO

SET ANSI_PADDING OFF
GO


