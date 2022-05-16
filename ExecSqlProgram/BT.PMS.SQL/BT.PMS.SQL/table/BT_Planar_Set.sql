
/****** Object:  Table [dbo].[BT_Planar_Set]    Script Date: 2021/5/27 16:14:52 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
IF Not exists(SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'BT_Planar_Set') and type=N'U')
begin 
CREATE TABLE [dbo].[BT_Planar_Set](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[planar_Name] [nvarchar](200) NULL,
	[sort] [int] NULL,
	[update_time] [datetime] NULL,
	[created_time] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
end

GO



