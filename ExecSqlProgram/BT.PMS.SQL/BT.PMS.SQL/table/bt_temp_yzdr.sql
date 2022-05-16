if(exists(select 1 from sysobjects where id = object_id('bt_temp_yzdr')))
 begin
    drop table bt_temp_yzdr
 end
/****** Object:  Table [dbo].[bt_temp_yzdr]    Script Date: 2021/5/14 16:57:13 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[bt_temp_yzdr](
	[cellname] [varchar](max) NULL,
	[cardno] [varchar](max) NULL,
	[enname] [varchar](max) NULL,
	[name] [varchar](max) NULL,
	[sex] [varchar](max) NULL,
	[code] [varchar](max) NULL,
	[Identity] [varchar](max) NULL,
	[Authorizer] [varchar](max) NULL,
	[Authorized_Person] [varchar](max) NULL,
	[Authorized_from] [varchar](max) NULL,
	[Authorized_until] [varchar](max) NULL,
	[zjstatus] [varchar](max) NULL,
	[inserttime] [varchar](max) NULL,
	[feetype] [varchar](max) NULL,
	[starttime] [varchar](max) NULL,
	[endttime] [varchar](max) NULL,
	[col_leave_reason] [varchar](max) NULL,
	[mobile] [varchar](max) NULL,
	[whatsapps] [varchar](max) NULL,
	[email] [varchar](max) NULL,
	[yzdzdy] [varchar](max) NULL,
	[yzdzds] [varchar](max) NULL,
	[yzdzjd] [varchar](max) NULL,
	[yzdzdq] [varchar](max) NULL,
	[jjlxr] [varchar](max) NULL,
	[jjlxrmobile] [varchar](max) NULL,
	[cardtype] [varchar](max) NULL,
	[memo] [varchar](max) NULL,
	[maxfk] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


