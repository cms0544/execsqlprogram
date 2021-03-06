if(exists(select 1 from sysobjects where id = object_id('func_GetDistinct')))
   begin
      drop function [dbo].[func_GetDistinct]
   end
/****** Object:  UserDefinedFunction [dbo].[func_GetDistinct]    Script Date: 2021/7/27 17:01:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[func_GetDistinct]
(
@str varchar(8000),
@splitChar char(1)
)
returns varchar(8000)
as
begin
declare @return varchar(8000)=''
select @return=@return+@splitChar+name from (
select  distinct name=substring(@str,number,charindex(@splitChar,@str+@splitChar,number)-number)
from master..spt_values
where number<=len(@str) and type='p' and substring(@splitChar+@str,number,1)=@splitChar
)as a
return stuff(@return,1,1,'')
end
