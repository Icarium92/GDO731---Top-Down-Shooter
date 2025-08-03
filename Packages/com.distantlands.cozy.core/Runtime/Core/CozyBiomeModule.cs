//  Distant Lands 2024
//  COZY: Stylized Weather 3
//  All code included in this file is protected under the Unity Asset Store Eula

using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using DistantLands.Cozy.Data;
#if UNITY_EDITOR
using UnityEditor;
#endif

namespace DistantLands.Cozy
{
    public interface ICozyBiomeModule
    {

        public void AddBiome();
        public void RemoveBiome();
        public void UpdateBiomeModule();
        public bool CheckBiome();
        public void ComputeBiomeWeights();
        public bool isBiomeModule { get; set; }

    }

    
    public class CozyBiomeModuleBase<TCozyBiomeModule>
        : CozyModule, ICozyBiomeModule
        where TCozyBiomeModule : CozyModule, ICozyBiomeModule
    {
        public List<CozyBiomeModuleBase<TCozyBiomeModule>> biomes = new();

        public float weight;
        
        public string moduleName => typeof(TCozyBiomeModule).Name;

        protected CozyBiomeModuleBase<TCozyBiomeModule> parentModule;
        
        public CozyBiomeModuleBase<TCozyBiomeModule> ParentModule
        {
            get
            {
                if (!parentModule)
                {
                    if (this.weatherSphere)
                    {
                        parentModule = weatherSphere.GetModule<CozyBiomeModuleBase<TCozyBiomeModule>>();
                    }
                }

                return parentModule;
            }
        }
        public bool isBiomeModule { get; set; }
        
        public override void InitializeModule()
        {
            if (this.weatherSphere == null)
            {
                Debug.LogError("The Cozy Weather Sphere instance is not found, please add it to your scene.");
            }
            
            isBiomeModule = GetComponent<CozyBiome>();

            if (isBiomeModule)
            {
                AddBiome();
                return;
            }
            
            base.InitializeModule();
            parentModule = this;
            AddBiome();
        }
        
        public virtual void AddBiome()
        {
            if (ParentModule)
            {
                ParentModule.biomes = FindObjectsByType<CozyBiomeModuleBase<TCozyBiomeModule>>(FindObjectsSortMode.None)
                    .Where(x => x != ParentModule)
                    .ToList();
            }
        }

        public virtual void RemoveBiome()
        {
            if (ParentModule)
            {
                ParentModule.biomes.Remove(this);
            }
        }

        public virtual void UpdateBiomeModule()
        {
        }

        public virtual bool CheckBiome()
        {
            if (!ParentModule)
            {
                Debug.LogError($"The {moduleName} biome module requires the {moduleName} module to be enabled on your weather sphere. Please add the the {moduleName} module before setting up your biome.");
                return false;
            }
            return true;
        }

        public virtual void ComputeBiomeWeights()
        {
            biomes.RemoveAll(x => !x);
            biomes.Sort(SortBySystemPriority);
            var totalSystemWeight = biomes.Sum(biome => biome.system.targetWeight);
            weight = Mathf.Clamp01(1 - totalSystemWeight);
            
            var biomeGroups = biomes
                .Where(biome => biome != this)
                .GroupBy(biome => biome.system.priority);

            foreach (var biomeGroup in biomeGroups)
            {
                NormalizeWeights(biomeGroup.ToList());
            }
        }

        public virtual void NormalizeWeights(List<CozyBiomeModuleBase<TCozyBiomeModule>> biomeGroup)
        {
            var totalSystemWeight = biomeGroup.Sum(biome => biome.system.targetWeight);
            totalSystemWeight += weight;
            totalSystemWeight = totalSystemWeight == 0 ? 1 : totalSystemWeight;
            
            foreach (var biome in biomeGroup)
            {
                biome.weight = biome.system.targetWeight / totalSystemWeight;
            }
        }
        
        protected static int SortBySystemPriority(CozyModule first, CozyModule second)
        {
            return first.system.priority.CompareTo(second.system.priority);
        }
    }
    
#if UNITY_EDITOR
    public interface E_BiomeModule
    {

        public abstract void DrawBiomeReports();

        public abstract void DrawInlineBiomeUI();

    }
#endif
}