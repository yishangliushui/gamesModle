using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;
using System.Diagnostics;

/*    ע������
1.���ű���Ҫ������Assets/Editor�ļ��������У���û�У����½�һ����Ϊ"Editor"���ļ��У�������ᱨ���Ҳ���MenuItem
2.ʹ��ʱ�������趨���·����Ĭ��Ϊ"D:\temp\model.unity3d"
3.���ű�����unity2023,����汾δ����
4.ʹ��ʱ����ѡ����Ҫ�������ļ��У�Ȼ�󵥻��Ҽ���ѡ��"�����unity3d"
*/
public class BundleExporter : MonoBehaviour
{
    [MenuItem("Assets/�����unity3d",false,0)]
    //"Assets/�Զ������"���ɰ���ϲ�����и������Ҽ��˵���ʾ�Ĵ���
    //0��ʾ�����Ҽ��˵�����λ���ɰ������
    static void ExportResource()
    {
        //�������·����Ĭ��ΪD:\temp
        string OutputFolder = @"D:\temp";

        if(!Directory.Exists(OutputFolder))
        {
            Directory.CreateDirectory(OutputFolder);
        }

        //�����ʽ1���ֶ���������·��
        //string BuildFolder ="Assets/Prefabs"

        //�����ʽ2��������ѡ�е��ļ���
        string BuildFolder = AssetDatabase.GUIDToAssetPath(Selection.assetGUIDs[0]);
        List<string> BuildFiles = new List<string>();

        UnityEngine.Debug.Log("ѡ�е�Ŀ¼Ϊ��" + BuildFolder);

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

        //Ĭ�ϴ����һ�������ɰ����޸�
        //��������ļ�Ϊ"model.unity3d"
        Builds[0].assetBundleName = "model";  //�ļ������������޸�
        Builds[0].assetBundleVariant = "unity3d"; //�ļ�β׺��Ĭ��Ϊunity3d

        Builds[0].assetNames = BuildFiles.ToArray();
        BuildPipeline.BuildAssetBundles(OutputFolder, Builds, BuildAssetBundleOptions.None, BuildTarget.StandaloneWindows);

        UnityEngine.Debug.Log("��Դ�������ɹ�:"+OutputFolder);
        
        Process.Start(OutputFolder); //������ļ��У����˶α�������Ϊmacϵͳ�������⣬ע�ʹ��뼴��
    }

}
