--USE [BT_PMS]
IF NOT EXISTS (select name from syscolumns where id=object_id(N'BT_col_CardManagement') AND NAME='col_Leave_Reason')
	begin
		alter table BT_col_CardManagement add col_Leave_Reason varchar(max)   
	end
select * into BT_col_CardManagementOld from BT_col_CardManagement Order by col_ID
drop table BT_col_CardManagement
GO

/****** Object:  Table [dbo].[BT_col_CardManagement]    Script Date: 2019/4/30 11:57:43 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[BT_col_CardManagement](
	[col_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[col_CardID] [nvarchar](125) NOT NULL,
	[col_CardType] [int] NOT NULL CONSTRAINT [DF_BT_col_CardManagement_col_CardType]  DEFAULT ((0)),
	[col_MaxSwipeTime] [int] NOT NULL CONSTRAINT [DF_BT_col_CardManagement_col_MaxSwipeTime]  DEFAULT ((0)),
	[col_DateStart] [datetime] NOT NULL,
	[col_DateEnd] [datetime] NOT NULL,
	[col_State] [int] NOT NULL CONSTRAINT [DF_BT_col_CardManagement_col_State]  DEFAULT ((1)),
	[col_OwnerID] [int] NOT NULL CONSTRAINT [DF_BT_col_CardManagement_col_OwnerID]  DEFAULT ((0)),
	[col_UserID] [int] NOT NULL CONSTRAINT [DF_BT_col_CardManagement_col_UserID]  DEFAULT ((0)),
	[col_UserType] [int] NOT NULL CONSTRAINT [DF_BT_col_CardManagement_col_UserType]  DEFAULT ((0)),
	[col_FCCellID] [int] NOT NULL CONSTRAINT [DF_BT_col_CardManagement_col_FCCellID]  DEFAULT ((0)),
	[col_CardName] [nvarchar](125) NULL CONSTRAINT [DF_BT_col_CardManagement_col_CardName]  DEFAULT (('')),
	[col_Remark] [nvarchar](max) NULL,
	[col_CreateTime] [datetime] NOT NULL,
	[kmbm] [nvarchar](max) NULL,
	[col_Leave_Reason] [nvarchar](max) NULL,
 CONSTRAINT [PK_BT_col_CardManagement] PRIMARY KEY CLUSTERED 
(
	[col_CardID] ASC,
	[col_UserID],
	[col_DateStart],
	[col_DateEnd]
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

--IF NOT EXISTS (SELECT a.* FROM  sys.syscolumns AS a LEFT OUTER JOIN sys.sysobjects AS d ON a.id = d.id AND d.xtype = 'U' AND d.name <> 'dtproperties' where d.id = OBJECT_ID(N'BT_col_CardManagement') and a.name='col_OwnerID')
--    BEGIN
--		ALTER TABLE BT_col_CardManagement ADD [col_OwnerID] [int] NULL CONSTRAINT [DF_BT_col_CardManagement_col_OwnerID]  DEFAULT ((0)) 
--    END 
--Go

--IF NOT EXISTS (SELECT a.* FROM  sys.syscolumns AS a LEFT OUTER JOIN sys.sysobjects AS d ON a.id = d.id AND d.xtype = 'U' AND d.name <> 'dtproperties' where d.id = OBJECT_ID(N'BT_col_CardManagement') and a.name='col_UserType')
--    BEGIN
--		ALTER TABLE BT_col_CardManagement ADD [col_UserType] [int] NULL CONSTRAINT [DF_BT_col_CardManagement_col_UserType]  DEFAULT ((0)) 
--    END 
--Go
--update BT_col_CardManagement set col_UserType=1 where col_CardID in (select cardid from [BT_OPENDOOR_QRCODE])
--update BT_col_CardManagement set col_UserType=0 where col_UserType is null

--update a set col_OwnerID=b.OwnerID from BT_col_CardManagement a,ZH_Members b where a.col_UserID=b.ID and a.col_UserID>0 and a.col_OwnerID is null

insert into BT_col_CardManagement(col_CardID,col_CardType,col_MaxSwipeTime,col_DateStart,col_DateEnd,col_State,col_OwnerID,col_UserID,col_UserType,col_FCCellID,col_CardName,col_Remark,col_CreateTime,kmbm,col_Leave_Reason) 
select col_CardID,col_CardType,col_MaxSwipeTime,col_DateStart,col_DateEnd,col_State,col_OwnerID,col_UserID,col_UserType,col_FCCellID,col_CardName,col_Remark,col_CreateTime,kmbm,col_Leave_Reason from BT_col_CardManagementOld

DROP TABLE BT_col_CardManagementOld
go

IF NOT EXISTS (select name from syscolumns where id=object_id(N'BT_col_CardManagement') AND NAME='col_card_status')  		alter table BT_col_CardManagement add col_card_status int

IF NOT EXISTS (select name from syscolumns where id=object_id(N'BT_col_CardManagement') AND NAME='col_card_fee')  		alter table BT_col_CardManagement add col_card_fee decimal(18,2)
			
			
