
IF NOT EXISTS (select name from syscolumns where id=object_id(N'BT_CarPark_Used_Devcie') AND NAME='LastUploadedTime')  ALTER TABLE [dbo].[BT_CarPark_Used_Devcie] ADD LastUploadedTime datetime;


 