using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;
using System.Diagnostics;

/*    注意事项
1.本脚本需要放置在Assets/Editor文件夹下运行（若没有，则新建一个名为"Editor"的文件夹），否则会报错找不到MenuItem
2.使用时可自行设定输出路径，默认为"D:\temp\model.unity3d"
3.本脚本适配unity2023,其余版本未测试
4.使用时，先选中需要导出的文件夹，然后单击右键，选择"打包成unity3d"
*/
public class BundleExporter : MonoBehaviour
{
    [MenuItem("Assets/打包成unity3d",false,0)]
    //"Assets/自定义词条"，可按照喜好自行更改在右键菜单显示的词条
    //0表示排在右键菜单的首位，可按需调整
    static void ExportResource()
    {
        //设置输出路径，默认为D:\temp
        string OutputFolder = @"D:\temp";

        if(!Directory.Exists(OutputFolder))
        {
            Directory.CreateDirectory(OutputFolder);
        }

        //打包方式1：手动键入代打包路径
        //string BuildFolder ="Assets/Prefabs"

        //打包方式2：打包鼠标选中的文件夹
        string BuildFolder = AssetDatabase.GUIDToAssetPath(Selection.assetGUIDs[0]);
        List<string> BuildFiles = new List<string>();

        UnityEngine.Debug.Log("选中的目录为：" + BuildFolder);

        DirectoryInfo directoryInfo = new DirectoryInfo(BuildFolder);
        FileInfo[] fileInfos = directoryInfo.GetFiles();

        for (int i = 0; i < fileInfos.Length - 1; i++)
        {
            if (fileInfos[i].Extension == ".meta")
            {
                continue;
            }
            BuildFiles.Add(fileInfos[i].FullName.Replace(Application.dataPath.Replace("/", @"\"), "Assets"));
        }


        AssetBundleBuild[] Builds = new AssetBundleBuild[1];

        //默认打包成一个包，可按需修改
        //命名输出文件为"model.unity3d"
        Builds[0].assetBundleName = "model";  //文件名，可自行修改
        Builds[0].assetBundleVariant = "unity3d"; //文件尾缀，默认为unity3d

        Builds[0].assetNames = BuildFiles.ToArray();
        BuildPipeline.BuildAssetBundles(OutputFolder, Builds, BuildAssetBundleOptions.None, BuildTarget.StandaloneWindows);

        UnityEngine.Debug.Log("资源包创建成功:"+OutputFolder);
        
        Process.Start(OutputFolder); //打开输出文件夹，若此段报错，可能为mac系统兼容问题，注释代码即可
    }

}
