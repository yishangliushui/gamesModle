using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using UnityEngine;

// Token: 0x02000002 RID: 2
public class AedenthornUtils
{
    // Token: 0x06000001 RID: 1 RVA: 0x00002090 File Offset: 0x00000290
    public static bool CheckKeyDown(string value)
    {
        bool flag;
        try
        {
            flag = Input.GetKeyDown(value.ToLower());
        }
        catch
        {
            flag = false;
        }
        return flag;
    }

    // Token: 0x06000002 RID: 2 RVA: 0x000020C4 File Offset: 0x000002C4
    public static bool CheckKeyUp(string value)
    {
        bool flag;
        try
        {
            flag = Input.GetKeyUp(value.ToLower());
        }
        catch
        {
            flag = false;
        }
        return flag;
    }

    // Token: 0x06000003 RID: 3 RVA: 0x000020F8 File Offset: 0x000002F8
    public static bool CheckKeyHeld(string value, bool req = true)
    {
        bool flag;
        try
        {
            flag = Input.GetKey(value.ToLower());
        }
        catch
        {
            flag = !req;
        }
        return flag;
    }

    // Token: 0x06000004 RID: 4 RVA: 0x00002130 File Offset: 0x00000330
    public static void ShuffleList<T>(List<T> list)
    {
        int i = list.Count;
        while (i > 1)
        {
            i--;
            int num = Random.Range(0, i);
            T t = list[num];
            list[num] = list[i];
            list[i] = t;
        }
    }

    // Token: 0x06000005 RID: 5 RVA: 0x00002180 File Offset: 0x00000380
    public static string GetAssetPath(object obj, bool create = false)
    {
        return AedenthornUtils.GetAssetPath(obj.GetType().Namespace, create);
    }

    // Token: 0x06000006 RID: 6 RVA: 0x000021A4 File Offset: 0x000003A4
    public static string GetAssetPath(string name, bool create = false)
    {
        string text = Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), name);
        bool flag = create && !Directory.Exists(text);
        if (flag)
        {
            Directory.CreateDirectory(text);
        }
        return text;
    }

    // Token: 0x06000007 RID: 7 RVA: 0x000021EC File Offset: 0x000003EC
    public static string GetTransformPath(Transform t)
    {
        bool flag = !t.parent;
        string text;
        if (flag)
        {
            text = t.name;
        }
        else
        {
            text = AedenthornUtils.GetTransformPath(t.parent) + "/" + t.name;
        }
        return text;
    }

    // Token: 0x06000008 RID: 8 RVA: 0x00002238 File Offset: 0x00000438
    public static byte[] EncodeToPNG(Texture2D texture)
    {
        RenderTexture temporary = RenderTexture.GetTemporary(texture.width, texture.height, 0, 7, 0);
        Graphics.Blit(texture, temporary);
        RenderTexture active = RenderTexture.active;
        RenderTexture.active = temporary;
        Texture2D texture2D = new Texture2D(texture.width, texture.height, 4, true, false);
        texture2D.ReadPixels(new Rect(0f, 0f, (float)temporary.width, (float)temporary.height), 0, 0);
        texture2D.Apply();
        RenderTexture.active = active;
        RenderTexture.ReleaseTemporary(temporary);
        Texture2D texture2D2 = new Texture2D(texture.width, texture.height);
        texture2D2.SetPixels(texture2D.GetPixels());
        texture2D2.Apply();
        return ImageConversion.EncodeToPNG(texture2D2);
    }
}
