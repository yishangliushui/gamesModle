using UnityEngine;
using UnityEditor;
using System.IO;

public class MultiPlatformExportAssetBundles
{
    [MenuItem("Assets/构建unity3D资源包")]
    static void ExportResource()
    {
        // 打开保存面板
        string path = EditorUtility.SaveFilePanel("保存资源包", "", "New Resource", "unity3d");
        if (string.IsNullOrEmpty(path)) return;

        // 获取输出目录和资源包名称
        string outputDirectory = Path.GetDirectoryName(path);
        string bundleName = Path.GetFileNameWithoutExtension(path);

        // 创建输出目录（如果不存在）
        if (!Directory.Exists(outputDirectory))
            Directory.CreateDirectory(outputDirectory);

        // 获取选中的资源路径
        Object[] selection = Selection.GetFiltered(typeof(Object), SelectionMode.DeepAssets);
        string[] assetPaths = new string[selection.Length];
        for (int i = 0; i < selection.Length; i++)
        {
            assetPaths[i] = AssetDatabase.GetAssetPath(selection[i]);
        }

        // 配置资源包构建参数
        AssetBundleBuild build = new AssetBundleBuild
        {
            assetBundleName = bundleName,
            assetNames = assetPaths
        };

        // 设置构建目标（可根据需要修改）
        BuildTarget buildTarget = BuildTarget.StandaloneWindows;

        // 构建资源包
        AssetBundleManifest manifest = BuildPipeline.BuildAssetBundles(
            outputDirectory,
            new[] { build },
            BuildAssetBundleOptions.None,
            buildTarget
        );

        // 显示结果
        if (manifest != null)
        {
            string resultPath = Path.Combine(outputDirectory, bundleName);
            EditorUtility.DisplayDialog("构建成功",
                $"资源包已成功构建到路径：\n{resultPath}", "确定");

            // 在资源管理器中显示生成的文件
            EditorUtility.RevealInFinder(resultPath);
        }
        else
        {
            EditorUtility.DisplayDialog("构建失败",
                "资源包构建失败，请检查控制台输出", "确定");
        }
    }
}