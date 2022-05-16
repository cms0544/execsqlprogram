 
--0£º˜IÖ÷£»1£ºÔL¿Í
IF NOT EXISTS (SELECT a.* FROM  sys.syscolumns AS a LEFT OUTER JOIN sys.sysobjects AS d ON a.id = d.id AND d.xtype = 'U' AND d.name <> 'dtproperties' where d.id = OBJECT_ID(N'BT_col_UserInfoForReader') and a.name='col_UserType')
    BEGIN
		ALTER TABLE BT_col_UserInfoForReader ADD [col_UserType] [int] NULL CONSTRAINT [DF_BT_col_UserInfoForReader_col_UserType]  DEFAULT ((0)) 
    END 
Go

IF NOT EXISTS (SELECT a.* FROM  sys.syscolumns AS a LEFT OUTER JOIN sys.sysobjects AS d ON a.id = d.id AND d.xtype = 'U' AND d.name <> 'dtproperties' where d.id = OBJECT_ID(N'BT_col_UserInfoForReader') and a.name='col_UserAddress')
    BEGIN
		ALTER TABLE BT_col_UserInfoForReader ADD [col_UserAddress] [int] NULL CONSTRAINT [DF_BT_col_UserInfoForReader_col_UserAddress]  DEFAULT ((0)) 
    END 
Go

IF NOT EXISTS (SELECT a.* FROM  sys.syscolumns AS a LEFT OUTER JOIN sys.sysobjects AS d ON a.id = d.id AND d.xtype = 'U' AND d.name <> 'dtproperties' where d.id = OBJECT_ID(N'BT_col_UserInfoForReader') and a.name='col_IfHadFace')
    BEGIN
		ALTER TABLE BT_col_UserInfoForReader ADD [col_IfHadFace] [int] NULL CONSTRAINT [DF_BT_col_UserInfoForReader_col_IfHadFace]  DEFAULT ((0)) 
    END 
Go
IF NOT EXISTS (SELECT a.* FROM  sys.syscolumns AS a LEFT OUTER JOIN sys.sysobjects AS d ON a.id = d.id AND d.xtype = 'U' AND d.name <> 'dtproperties' where d.id = OBJECT_ID(N'BT_col_UserInfoForReader') and a.name='col_InOutType')
    BEGIN
		ALTER TABLE BT_col_UserInfoForReader ADD [col_InOutType] [int] NULL CONSTRAINT [DF_BT_col_UserInfoForReader_col_InOutType]  DEFAULT ((0)) 
    END 
Go
IF NOT EXISTS (SELECT a.* FROM  sys.syscolumns AS a LEFT OUTER JOIN sys.sysobjects AS d ON a.id = d.id AND d.xtype = 'U' AND d.name <> 'dtproperties' where d.id = OBJECT_ID(N'BT_col_UserInfoForReader') and a.name='col_UpdateTime')
    BEGIN
		ALTER TABLE BT_col_UserInfoForReader ADD [col_UpdateTime] [datetime] NULL CONSTRAINT [DF_BT_col_UserInfoForReader_col_UpdateTime]  DEFAULT ((getdate())) 
    END 
Go
IF NOT EXISTS (SELECT a.* FROM  sys.syscolumns AS a LEFT OUTER JOIN sys.sysobjects AS d ON a.id = d.id AND d.xtype = 'U' AND d.name <> 'dtproperties' where d.id = OBJECT_ID(N'BT_col_UserInfoForReader') and a.name='col_OwnerID')
    BEGIN
		ALTER TABLE BT_col_UserInfoForReader ADD [col_OwnerID] [int] NULL CONSTRAINT [DF_BT_col_UserInfoForReader_col_OwnerID]  DEFAULT ((0)) 
    END 
Go

UPDATE BT_col_UserInfoForReader SET col_UserType=0 WHERE col_UserType IS NULL 
UPDATE BT_col_UserInfoForReader SET col_UserAddress=col_UserID WHERE col_UserAddress IS NULL AND col_UserID<16000
UPDATE a SET col_IfHadFace=1 from BT_col_UserInfoForReader a,V_ZH_Members b WHERE a.col_CardID=b.card_ID and REPLACE(ISNULL(b.zpurl,'no.gif'),'no.gif','')<>'' 
UPDATE BT_col_UserInfoForReader SET col_IfHadFace=0 WHERE col_IfHadFace IS NULL 
UPDATE BT_col_UserInfoForReader SET col_InOutType=0 WHERE col_InOutType IS NULL 
UPDATE BT_col_UserInfoForReader SET col_UpdateTime=col_CreateTime WHERE col_UpdateTime IS NULL 
UPDATE BT_col_UserInfoForReader SET col_OwnerID=(select a.ID From ZH_Owner a left join ZH_Members b on a.ID=b.OwnerID where b.ID=col_UserID) WHERE col_OwnerID IS NULL 

