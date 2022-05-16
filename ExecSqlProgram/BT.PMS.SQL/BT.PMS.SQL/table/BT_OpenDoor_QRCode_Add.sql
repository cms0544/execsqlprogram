

IF NOT EXISTS (select name from syscolumns where id=object_id(N'BT_OPENDOOR_QRCODE') AND NAME='floor_unitvisited')  ALTER TABLE [dbo].[BT_OPENDOOR_QRCODE] ADD floor_unitvisited nvarchar(1000);
