

/****** Object:  Table [dbo].[tb_IODeviceStatus]    Script Date: 2021/06/09 17:55:30 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
IF not EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'tb_IODeviceStatus') AND type in (N'U'))
begin
CREATE TABLE [dbo].[tb_IODeviceStatus](
	[DeviceID] [int] NULL,
	[LastamendTime] [datetime] NULL
) ON [PRIMARY]
end
GO




