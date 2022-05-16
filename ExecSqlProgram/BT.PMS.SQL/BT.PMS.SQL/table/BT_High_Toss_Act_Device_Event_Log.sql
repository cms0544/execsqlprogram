
/****** Object:  Table [dbo].[BT_High_Toss_Act_Device_Event_Log]    Script Date: 2021/5/27 16:19:29 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO
IF Not exists(SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'BT_High_Toss_Act_Device_Event_Log') and type=N'U')
begin 
CREATE TABLE [dbo].[BT_High_Toss_Act_Device_Event_Log](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[device_code] [varchar](100) NOT NULL,
	[camSerial] [nvarchar](300) NULL,
	[ecode] [int] NULL,
	[ip] [varchar](100) NULL,
	[imageUploadUrl] [nvarchar](max) NULL,
	[videoUploadUrl] [nvarchar](max) NULL,
	[mdate] [datetime] NULL,
	[count] [int] NULL,
	[careateTime] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
end
GO

SET ANSI_PADDING OFF
GO

IF NOT EXISTS (select name from syscolumns where id=object_id(N'BT_High_Toss_Act_Device_Event_Log') AND NAME='remark')  	
	alter table BT_High_Toss_Act_Device_Event_Log add remark nvarchar(max)

IF NOT EXISTS (select name from syscolumns where id=object_id(N'BT_High_Toss_Act_Device_Event_Log') AND NAME='remarkUpdateTime')  	
    alter table BT_High_Toss_Act_Device_Event_Log add remarkUpdateTime datetime


