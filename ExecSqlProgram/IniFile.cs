using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

namespace ExecSqlProgram
{


    public class IniFile
    {
        [DllImport("kernel32.dll")] //写INI
        private static extern long WritePrivateProfileString(string section, string key, string val, string filePath);
        [DllImport("kernel32.dll")] //读INI
        private static extern int GetPrivateProfileString(string section, string key, string def, StringBuilder retVal, int size, string filePath);

        [DllImport("kernel32.dll")] //读INI
        private static extern int GetPrivateProfileString(string section, string key, string def, byte[] retVal, int size, string filePath);

        public string Path { set; get; }

        public IniFile(string path)
        {
            this.Path = path;
            if (!File.Exists(path))
            {
                File.Create(path);
            }
        }

        /// <summary>
        /// 写文件
        /// </summary>
        /// <param name="section"></param>
        /// <param name="key"></param>
        /// <param name="iValue"></param>

        public void IniWriteValue(string section,string key,string iValue)
        {
            WritePrivateProfileString(section, key, iValue,this.Path);
        }

        /// <summary>
        /// 读文件
        /// </summary>
        /// <param name="section"></param>
        public string IniReadValue(string section,string key)
        {
            StringBuilder sb = new StringBuilder(255);
            GetPrivateProfileString(section, key, "", sb, 255, this.Path);
            return sb.ToString();
        }

        /// <summary>
        /// 读文件(byte类型)
        /// </summary>
        /// <param name="section"></param>
        public byte[] IniReadValues(string section, string key)
        {
            byte[] temp = new byte[255];
            
           int i = GetPrivateProfileString(section, key, "", temp, 255, this.Path);
           return temp;
        }
    }
}
