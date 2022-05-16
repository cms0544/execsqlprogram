 

IF NOT EXISTS (SELECT a.* FROM  sys.syscolumns AS a LEFT OUTER JOIN sys.sysobjects AS d ON a.id = d.id AND d.xtype = 'U' AND d.name <> 'dtproperties' where d.id = OBJECT_ID(N'BT_col_UserInfoForReaderBackup') and a.name='col_OwnerID')
    BEGIN
		ALTER TABLE BT_col_UserInfoForReaderBackup ADD [col_OwnerID] [int] NULL 
    END 
Go
UPDATE BT_col_UserInfoForReaderBackup SET col_OwnerID=(select a.ID From ZH_Owner a left join ZH_Members b on a.ID=b.OwnerID where b.ID=col_UserID) WHERE col_OwnerID IS NULL 
