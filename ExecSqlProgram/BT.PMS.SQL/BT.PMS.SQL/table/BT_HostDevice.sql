



IF NOT EXISTS (select name from syscolumns where id=object_id(N'BT_HostDevice') AND NAME='HasQRCode')  ALTER TABLE [dbo].[BT_HostDevice] ADD HasQRCode bit;
IF NOT EXISTS (select name from syscolumns where id=object_id(N'BT_HostDevice') AND NAME='IsClubHouse')   alter table BT_HostDevice add IsClubHouse [bit];




IF NOT EXISTS (SELECT a.* FROM  sys.syscolumns AS a LEFT OUTER JOIN sys.sysobjects AS d ON a.id = d.id AND d.xtype = 'U' AND d.name <> 'dtproperties' where d.id = OBJECT_ID(N'BT_HostDevice') and a.name='HasQRCodeReader')
    BEGIN
		ALTER TABLE BT_HostDevice ADD [HasQRCodeReader] [bit] NULL CONSTRAINT [DF_BT_HostDevice_HasQRCodeReader]  DEFAULT ((0))
    END 

update BT_HostDevice set [HasQRCodeReader]=1 where DeviceType='DS-K1T671TM-3XF' and [HasQRCodeReader] is null
update BT_HostDevice set [HasQRCodeReader]=0 where [HasQRCodeReader] is null