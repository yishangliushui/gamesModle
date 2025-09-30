using HarmonyLib;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Linq.Expressions;
using System.Reflection;
using System.Runtime.InteropServices.ComTypes;
using System.Text;
using System.Threading.Tasks;
using UnityEngine;
using static ModEvents;


//namespace MeleeToolSickleT0IronSickle
//{

//}

/// <summary>
/// 镰刀收割范围增强Mod主类
/// </summary>
public class MeleeToolSickleT0IronSickle : IModApi
{

    // 模组初始化方法，游戏加载模组时会自动调用
    public void InitMod(Mod _modInstance)
    {
        try
        {
            UnityEngine.Debug.Log("[镰刀收割] 初始化镰刀收割范围增强系统...");

            // 创建Harmony实例
            var harmony = new Harmony(GetType().ToString());

            // 应用所有补丁
            harmony.PatchAll();
            MeleeToolSickleT0IronSickle.context = this;
            MeleeToolSickleT0IronSickle.mod = _modInstance;
            MeleeToolSickleT0IronSickle.LoadConfig(); // 加载配置文件
            UnityEngine.Debug.Log("[镰刀收割] 镰刀收割范围增强系统已就绪");
        }
        catch (Exception ex)
        {
            UnityEngine.Debug.LogError("[镰刀收割] 系统初始化失败: " + ex.Message);
        }
    }

    public static void LoadConfig()
    {
        string text = Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), "config.json");
        // 如果配置文件不存在，创建默认配置
        if (!File.Exists(text))
        {
            MeleeToolSickleT0IronSickle.config = new ModConfig();
        }
        else
        {
            // 从JSON文件加载配置
            MeleeToolSickleT0IronSickle.config = JsonConvert.DeserializeObject<ModConfig>(File.ReadAllText(text));
        }
        // 将配置写回文件（确保格式正确）
        File.WriteAllText(text, JsonConvert.SerializeObject(MeleeToolSickleT0IronSickle.config, Formatting.Indented));
    }


    public static void Dbgl(object str, bool prefix = true)
    {
        // 调试日志输出，仅在调试模式启用时显示
        if (MeleeToolSickleT0IronSickle.config.isDebug)
        {
            UnityEngine.Debug.Log((prefix ? (MeleeToolSickleT0IronSickle.mod.Name + "[快速采集作物] ") : "") + (str?.ToString()));
        }
    }


    private static void HarvestCrops(EntityPlayerLocal player)
    {
        MeleeToolSickleT0IronSickle.Dbgl("Harvesting crops", true);
        MeleeToolSickleT0IronSickle.LoadConfig(); // 重新加载配置（确保使用最新设置）
        int num = 0; // 收割的作物计数器
        Vector3i blockPosition = player.GetBlockPosition(); // 获取玩家所在方块位置
        int blockRadius = MeleeToolSickleT0IronSickle.config.blockRadius; // 获取配置中的收割半径

        // 初始化随机数生成器
        GameUtils.random = GameRandomManager.Instance.CreateGameRandom();
        GameUtils.random.SetSeed((int)Stopwatch.GetTimestamp());

        Vector3i playerBlockPos = player.GetBlockPosition();
        Vector3 playerPos = player.GetPosition();
        Vector3 playerForward = player.GetLookVector().normalized;

        // 三层循环遍历3D区域内的所有方块
        int a = 1;
        if (a == 1)
        {
            for (int i = -blockRadius; i <= blockRadius; i++)
            {
                for (int j = -Math.Min(blockRadius, 1); j <= Math.Min(blockRadius, 1); j++) // Y轴限制在1格以内
                {
                    for (int k = -blockRadius; k <= blockRadius; k++)
                    {
                        num = getDropNum(player, num, blockPosition, i, j, k);
                    }
                }
            }
        }
        else {

            // 锥形区域收割
            for (int i = 1; i <= blockRadius; i++)
            {
                // 随着距离增加，横向范围也增加（锥形效果）
                int maxWidth = Mathf.Min(i, blockRadius);

                for (int j = -maxWidth; j <= maxWidth; j++)
                {
                    for (int k = -1; k <= 1; k++)
                    {
                        num = getDropNum(player, num, blockPosition, i, j, k);
                    }
                }
            }
        }

        MeleeToolSickleT0IronSickle.Dbgl(string.Format("Harvested {0} crops", num), true);
        bool isDebug = MeleeToolSickleT0IronSickle.config.isDebug;
        // 在调试模式下显示收割结果提示
        if (num > 0 && isDebug)
        {
            GameManager.ShowTooltip(player, string.Format("快速采集: 收获 {0} 个农作物方块", num), false, false, 0f);
        }
    }

    private static int getDropNum(EntityPlayerLocal player, int num, Vector3i blockPosition, int i, int j, int k)
    {
        Vector3i vector3i = blockPosition + new Vector3i(i, j, k); // 计算当前检查的方块位置
        BlockValue block = player.world.GetBlock(vector3i); // 获取方块值

        // 跳过空气方块和子方块
        if (!block.isair && !block.ischild)
        {
            Chunk chunk = (Chunk)player.world.GetChunkFromWorldPos(vector3i);
            int num2 = (GameStats.GetInt(EnumGameStats.LandClaimDecayMode) - 1) / 2; // 获取土地保护范围

            // 检查方块是否在受保护的土地上且可收割
            if (!player.world.IsLandProtectedBlock(chunk, vector3i, player.persistentPlayerData, num2, num2, false) && MeleeToolSickleT0IronSickle.IsHarvestableBlock(block.Block.blockName.ToLower()))
            {
                try
                {
                    //BlockValue blockValue = BlockValue.Air; // 用于存储替换的方块（如种子）
                    ItemValue itemValue = null; // 物品值

                    // 处理掉落组0（主要掉落物，如作物果实）
                    if (block.Block.itemsToDrop.TryGetValue(0, out List<Block.SItemDropProb> list))
                    {
                        for (int l = 0; l < list.Count; l++)
                        {
                            UnityEngine.Debug.Log("[镰刀收割] list=i" + JsonUtility.ToJson(list[l]));
                            Block.SItemDropProb sitemDropProb = list[l];
                            // 计算掉落数量加成（基于技能、工具等）141
                            float value = EffectManager.GetValue(PassiveEffects.HarvestCount, player.inventory.holdingItemItemValue, 1f, player, null, FastTags<TagGroup.Global>.Parse(sitemDropProb.tag), true, true, true, true, true, 1, true, false);
                            MeleeToolSickleT0IronSickle.Dbgl("value=" + value, true);

                            int num3 = (int)((float)GameUtils.random.RandomRange(sitemDropProb.minCount, sitemDropProb.maxCount + 1) * value);
                            //int num3 = (int)value;
                            UnityEngine.Debug.Log("[镰刀收割] num3=" + num3);
                            if (num3 > 0)
                            {
                                MeleeToolSickleT0IronSickle.CollectHarvestedItem(player, block, itemValue, num3);
                            }
                        }
                    }
                    UnityEngine.Debug.Log("[镰刀收割] 111111111111");
                    // 处理掉落组2（额外掉落物，如资源）  2
                    if (block.Block.itemsToDrop.TryGetValue(EnumDropEvent.Harvest, out List<Block.SItemDropProb> list2))
                    {
                        for (int m = 0; m < list2.Count; m++)
                        {
                            int num4 = 0; // 最终掉落数量
                            Block.SItemDropProb sitemDropProb2 = list2[m];
                            float num5 = 0f;
                            ItemValue itemValue2 = (sitemDropProb2.name.Equals("*") ? block.ToItemValue() : new ItemValue(ItemClass.GetItem(sitemDropProb2.name, false).type, false));

                            if (itemValue2.type != 0 && ItemClass.list[itemValue2.type] != null)
                            {
                                // 计算掉落加成 PassiveEffects 141
                                num5 = EffectManager.GetValue(PassiveEffects.HarvestCount, player.inventory.holdingItemItemValue, num5, player, null, FastTags<TagGroup.Global>.Parse(sitemDropProb2.tag), true, true, true, true, true, 1, true, false);
                                MeleeToolSickleT0IronSickle.Dbgl("num5=" + num5, true);
                                int num6 = (int)((float)GameUtils.random.RandomRange(sitemDropProb2.minCount, sitemDropProb2.maxCount + 1) * num5);

                                // 概率计算：分为主要部分和资源缩放部分
                                int num7 = num6 - num6 / 3;
                                if (num7 > 0 && GameUtils.random.RandomFloat <= sitemDropProb2.prob)
                                {
                                    num4 += num7;
                                }

                                num7 = num6 / 3;
                                float num8 = sitemDropProb2.prob;
                                float resourceScale = sitemDropProb2.resourceScale;

                                // 应用资源缩放
                                if (resourceScale > 0f && resourceScale < 1f)
                                {
                                    num8 /= resourceScale;
                                    num7 = (int)((float)num7 * resourceScale);
                                    if (num7 < 1)
                                    {
                                        num7++;
                                    }
                                }

                                if (num7 > 0 && GameUtils.random.RandomFloat <= num8)
                                {
                                    num4 += num7;
                                }

                                UnityEngine.Debug.Log("[镰刀收割] num4=" + num4);
                                // 添加掉落物到背包
                                if (num4 > 0)
                                {
                                    MeleeToolSickleT0IronSickle.CollectHarvestedItem(player, block, itemValue2, num4);
                                }
                            }
                        }
                    }

                    //blockValue.rotation = block.rotation; // 保持方块旋转方向
                    // 直接破坏方块
                    block.Block.DamageBlock(player.world, 0, vector3i, block, 1, player.entityId, null, false, false);

                    num++; // 增加收割计数器
                }
                catch (Exception ex)
                {
                    // 忽略单个方块的错误，继续处理其他方块
                    UnityEngine.Debug.LogError("[镰刀收割] 收割物品报错: " + ex);
                }
            }
        }

        return num;
    }

    public static bool IsHarvestableBlock(string name)
    {
        bool flag;
        // 检查是否是草（如果配置允许）
        if (MeleeToolSickleT0IronSickle.config.collectGrass && name.StartsWith("tree") && name.Contains("grass"))
        {
            flag = true;
        }
        else if (!name.StartsWith("planted")) // 只处理种植类方块
        {
            flag = false;
        }
        else
        {
            // 检查是否是成熟作物或可收割状态
            if (!name.EndsWith("harvestplayer") && !name.EndsWith("harvest"))
            {
                // 检查自定义收割类型列表
                foreach (string text in MeleeToolSickleT0IronSickle.config.harvestTypes)
                {
                    string text2 = text.ToLower();
                    // 支持精确匹配和通配符匹配
                    if (name.Equals(text2) || (text2.EndsWith("*") && name.StartsWith(text2.Substring(0, text2.Length - 1))))
                    {
                        return true;
                    }
                }
                return false;
            }
            flag = true;
        }
        return flag;
    }


    private static void CollectHarvestedItem(EntityPlayerLocal player, BlockValue bv, ItemValue _iv, int _count)
    {
        if (_count > 0)
        {
            ItemStack itemStack = new ItemStack(_iv, _count);
            //XUiM_PlayerInventory playerInventory = LocalPlayerUI.GetUIForPlayer(player).xui.PlayerInventory;

            // 尝试多种方式获取玩家物品栏
            XUiM_PlayerInventory playerInventory = null;
            EntityPlayerLocal localPlayer = GameManager.Instance.World.GetPrimaryPlayer();

            if (player is EntityPlayerLocal localPl && localPl.PlayerUI != null)
            {
                playerInventory = localPl.PlayerUI.xui.PlayerInventory;
                UnityEngine.Debug.Log("[镰刀收割] playerInventory = 1, " + playerInventory);
            }
            else if (localPlayer != null && localPlayer.PlayerUI != null)
            {
                playerInventory = localPlayer.PlayerUI.xui.PlayerInventory;
                UnityEngine.Debug.Log("[镰刀收割] playerInventory = 2, " + playerInventory);
            }

            // 触发任务事件（收割物品）
            QuestEventManager.Current.HarvestedItem(player.inventory.holdingItemItemValue, itemStack, bv);
            UnityEngine.Debug.Log("[镰刀收割] itemStack=" + JsonUtility.ToJson(itemStack));
            // 尝试添加到背包，失败则掉落在地上
            try {
                if (!playerInventory.AddItem(itemStack))
                {
                    GameManager.Instance.ItemDropServer(new ItemStack(_iv, itemStack.count), GameManager.Instance.World.GetPrimaryPlayer().GetDropPosition(), new Vector3(0.5f, 0.5f, 0.5f), GameManager.Instance.World.GetPrimaryPlayerId(), 60f, false);
                }
            }
            catch (Exception ex) {
                UnityEngine.Debug.LogError("[镰刀收割] 报错1：" + ex.StackTrace);
                UnityEngine.Debug.LogError("[镰刀收割] 报错2：" + ex);
            }
        }
    }


    public static ModConfig config; // 模组配置


    public static MeleeToolSickleT0IronSickle context; // 模组上下文实例


    public static Mod mod; // 模组实例


    //[HarmonyPatch(typeof(EntityPlayerLocal))]
    //[HarmonyPatch(typeof(GameManager))]
    public static class GameManager_Update_Patch
    {
        //[HarmonyPatch("ProcessDamageResponseLocal")]
        //[HarmonyPatch("Update")]
        //[HarmonyPostfix]
        public static void Postfix(GameManager __instance, World ___m_World, GUIWindowManager ___windowManager)
        {
            UnityEngine.Debug.Log("[镰刀收割] 到处理请求");
            if (!MeleeToolSickleT0IronSickle.config.modEnabled || ___m_World == null || __instance == null)
            {
                UnityEngine.Debug.Log("[镰刀收割] 到处理请求1");
                return;
            }

            EntityPlayerLocal player = ___m_World.GetPrimaryPlayer();
            if (player == null) {
                return;
            }


            // 检查玩家是否存活
            if (player.IsDead())
            {
                UnityEngine.Debug.Log("[镰刀收割] 到处理请求2");
                return;
            }

            if (!player.IsAttackValid()) {
                UnityEngine.Debug.Log("[镰刀收割] 到处理请求攻击无效");
                return;
            }

            // 获取当前装备的物品
            ItemValue heldItem = player.inventory.holdingItemItemValue;
            if (heldItem.IsEmpty())
            {
                UnityEngine.Debug.Log("[镰刀收割] 到处理请求3");
                return;
            }
            // 检查是否为镰刀工具
            if (heldItem.ItemClass.GetItemName().EndsWith("Sickle"))
            {
                UnityEngine.Debug.Log("[镰刀收割] 到处理请求4");
                MeleeToolSickleT0IronSickle.Dbgl($"Sickle attack with {heldItem.ItemClass.GetItemName()}", true);
                MeleeToolSickleT0IronSickle.HarvestCrops(player);
            }
            UnityEngine.Debug.Log("[镰刀收割] 到处理请求5");
        }
    }


    [HarmonyPatch(typeof(ItemActionMelee))]
    public static class EntityPlayerLocal_Attack_Patch
    {
        // 方法1：拦截攻击命中后的处理
        [HarmonyPatch("hitTheTarget")]
        [HarmonyPostfix]
        public static void HitTheTarget_Postfix(ItemActionMelee __instance, ItemActionMelee.InventoryDataMelee _actionData, WorldRayHitInfo hitInfo, float damageScale)
        {
            try
            {
                UnityEngine.Debug.Log($"[镰刀收割] hitTheTarget 方法被调用，命中目标: {hitInfo.bHitValid}");
                if (!MeleeToolSickleT0IronSickle.config.modEnabled)
                    return;

                // 获取持有武器的实体
                EntityAlive holdingEntity = _actionData.invData.holdingEntity;
                UnityEngine.Debug.Log($"[镰刀收割] holdingEntity : {JsonUtility.ToJson(holdingEntity)}");
                if (holdingEntity == null || !(holdingEntity is EntityPlayerLocal))
                    return;

                EntityPlayerLocal player = holdingEntity as EntityPlayerLocal;
                UnityEngine.Debug.Log($"[镰刀收割] player : {JsonUtility.ToJson(player)}");
                if (player == null) return;

                // 检查玩家装备的是否为镰刀
                ItemValue heldItem = player.inventory.holdingItemItemValue;
                if (heldItem.IsEmpty() || !heldItem.ItemClass.GetItemName().EndsWith("Sickle"))
                    return;

                if (hitInfo.bHitValid)
                {
                    CheckSickleAndHarvest(player);
                }
                UnityEngine.Debug.LogError($"[镰刀收割] hitInfo.bHitValid:" + hitInfo.bHitValid); 
            }
            catch (Exception ex)
            {
                UnityEngine.Debug.LogError($"[镰刀收割] 命中目标:" + ex);
            }
        }

        //// 方法2：拦截攻击触发
        //[HarmonyPatch("OnFired")]
        //[HarmonyPostfix]
        //public static void OnFired_Postfix(EntityPlayerLocal __instance)
        //{
        //    if (!MeleeToolSickleT0IronSickle.config.modEnabled)
        //        return;

        //    UnityEngine.Debug.Log("[镰刀收割] 攻击动作触发");

        //    // 检查是否为镰刀
        //    ItemValue heldItem = __instance.inventory.holdingItemItemValue;
        //    if (!heldItem.IsEmpty() && heldItem.ItemClass.GetItemName().EndsWith("Sickle"))
        //    {
        //        UnityEngine.Debug.Log($"[镰刀收割] 使用镰刀攻击: {heldItem.ItemClass.GetItemName()}");
        //        // 可以在这里处理攻击前的逻辑
        //    }
        //}

        private static void CheckSickleAndHarvest(EntityPlayerLocal player)
        {
            // 检查玩家装备的是否为镰刀
            ItemValue heldItem = player.inventory.holdingItemItemValue;
            if (heldItem.IsEmpty() || !heldItem.ItemClass.GetItemName().EndsWith("Sickle"))
                return;

            UnityEngine.Debug.Log($"[镰刀收割] 镰刀命中目标，开始收割逻辑");

            // 调用你的收割方法
            MeleeToolSickleT0IronSickle.Dbgl($"Sickle hit with {heldItem.ItemClass.GetItemName()}", true);
            MeleeToolSickleT0IronSickle.HarvestCrops(player);
        }
    } 
}

public class ModConfig
{
    public bool modEnabled = true;

    public bool isDebug = true;

    public int blockRadius = 3;

    public List<string> harvestTypes = new List<string>();

    public bool collectGrass = true;
}
