if(exists(select 1 from sysobjects where id = object_id('ZH_ZhfwAPP')))
   begin
      drop TABLE [dbo].[ZH_ZhfwAPP]
   end
/****** Object:  Table [dbo].[ZH_Zhts4APP]    Script Date: 2021/6/18 9:32:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ZH_ZhfwAPP](
	[ZH_Zhfw_id] [int] NOT NULL  primary key,
	[bt_app_user_uid] [uniqueidentifier] NOT NULL,
)

