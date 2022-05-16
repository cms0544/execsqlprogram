IF NOT EXISTS (SELECT a.* FROM  sys.syscolumns AS a LEFT OUTER JOIN sys.sysobjects AS d ON a.id = d.id AND d.xtype = 'U' AND d.name <> 'dtproperties' where d.id = OBJECT_ID(N'ZH_Zhts') and a.name='RecordType')
    BEGIN
		ALTER TABLE [dbo].[ZH_Zhts] Add RecordType tinyint default(0)
    END 
Go

IF NOT EXISTS (SELECT a.* FROM  sys.syscolumns AS a LEFT OUTER JOIN sys.sysobjects AS d ON a.id = d.id AND d.xtype = 'U' AND d.name <> 'dtproperties' where d.id = OBJECT_ID(N'ZH_Zhts') and a.name='FeedbackTitle')
    BEGIN
		ALTER TABLE [dbo].[ZH_Zhts] Add FeedbackTitle nvarchar(100) 
    END 
Go


IF NOT EXISTS (select name from syscolumns where id=object_id(N'zh_zhts') AND NAME='memberid') 
alter table zh_zhts add memberid int 