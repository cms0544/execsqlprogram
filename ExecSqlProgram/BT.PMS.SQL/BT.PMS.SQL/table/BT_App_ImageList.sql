--USE [BT_PMS]
if(exists(select 1 from sysobjects where id = OBJECT_ID('BT_App_ImageList'))) drop table BT_App_ImageList
GO

/****** Object:  Table [dbo].[BT_col_CardManagement]    Script Date: 2021/07/23 16:23:43 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[BT_App_ImageList](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ImageData] [nvarchar](max) NULL,
	[urlPath] [nvarchar](max) NULL,
	[intime] [datetime] NULL DEFAULT (getdate()),
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO


