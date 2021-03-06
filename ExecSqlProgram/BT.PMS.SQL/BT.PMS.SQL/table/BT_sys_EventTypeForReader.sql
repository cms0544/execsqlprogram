--USE [BT_PMS]
--drop table BT_sys_EventTypeForReader
--GO
--/****** Object:  Table [dbo].[BT_sys_EventTypeForReader]    Script Date: 01/24/2019 17:21:04 ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO

IF Not exists(SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'BT_sys_EventTypeForReader') and type=N'U')
	begin 
CREATE TABLE [dbo].[BT_sys_EventTypeForReader](
	[sys_ID] [int] NOT NULL,
	[sys_EventType] [nvarchar](125) NULL,
	[sys_EventTypeCHS] [nvarchar](125) NULL,
	[sys_EventTypeENG] [nvarchar](125) NULL,
 CONSTRAINT [PK_BT_sys_EventTypeForReader] PRIMARY KEY CLUSTERED 
(
	[sys_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
	end
Go

IF Not exists(SELECT * FROM BT_sys_EventTypeForReader)
	BEGIN
insert into BT_sys_EventTypeForReader select 1,'合法卡認證通過','合法卡认证通过','合法卡認證通過'
insert into BT_sys_EventTypeForReader select 6,'未分配權限','未分配权限','未分配權限'
insert into BT_sys_EventTypeForReader select 7,'無效時段','无效时段','無效時段'
insert into BT_sys_EventTypeForReader select 8,'卡號過期','卡号过期','卡號過期'
insert into BT_sys_EventTypeForReader select 9,'無此卡號','无此卡号','無此卡號'
insert into BT_sys_EventTypeForReader select 15,'二維碼開門','二维码开门','二維碼開門'
insert into BT_sys_EventTypeForReader select 60,'面部+卡片驗證進出','人脸加刷卡认证通过','面部+卡片驗證進出'
insert into BT_sys_EventTypeForReader select 75,'面部驗證進出','人脸认证通过','面部驗證進出'
insert into BT_sys_EventTypeForReader select 76,'面部驗證失敗','人脸认证失败','面部驗證失敗'
insert into BT_sys_EventTypeForReader select 105,'人證比對通過','人证比对通过','人證比對通過'
	END

IF NOT EXISTS (select 1 from BT_sys_EventTypeForReader where sys_ID=999)--僅測溫模式事件
	begin
		insert into BT_sys_EventTypeForReader select 999,'測溫事件','测温事件','測溫事件'
	end
--select * from BT_sys_EventTypeForReader