//  Distant Lands 2024
//  COZY: Stylized Weather 3
//  All code included in this file is protected under the Unity Asset Store Eula

using UnityEngine;
#if THE_VISUAL_ENGINE
using TheVisualEngine;
#elif THE_VEGETATION_ENGINE
using TheVegetationEngine;
#endif

namespace DistantLands.Cozy
{

    [ExecuteAlways]
    public class CozyTVEModule : CozyModule
    {

        public enum UpdateFrequency { everyFrame, onAwake, viaScripting }
        public UpdateFrequency updateFrequency;

#if THE_VISUAL_ENGINE
        public TVEManager visualManager;
#elif THE_VEGETATION_ENGINE
        public TVEGlobalControl globalControl;
        public TVEGlobalMotion globalMotion;
#endif

        // Start is called before the first frame update
        void Awake()
        {

            InitializeModule();

#if THE_VEGETATION_ENGINE || THE_VISUAL_ENGINE
            if (updateFrequency == UpdateFrequency.onAwake)
                UpdateTVE();
#endif


        }

        public override void InitializeModule()
        {
            if (!enabled)
                return;

            base.InitializeModule();

            if (!weatherSphere)
            {
                enabled = false;
                return;
            }

#if THE_VISUAL_ENGINE
            if (!visualManager)
                visualManager = FindObjectOfType<TVEManager>();

            if (!visualManager)
            {
                enabled = false;
                return;
            }

            visualManager.mainLight = weatherSphere.sunLight;
#elif THE_VEGETATION_ENGINE
            if (!globalControl)
                globalControl = FindObjectOfType<TVEGlobalControl>();

            if (!globalControl)
            {
                enabled = false;
                return;
            }

            if (!globalMotion)
                globalMotion = FindObjectOfType<TVEGlobalMotion>();

            if (!globalMotion)
            {
                enabled = false;
                return;
            }

            globalControl.mainLight = weatherSphere.sunLight;
#endif

        }


        // Update is called once per frame
        void Update()
        {
            if (CozyWeather.FreezeUpdateInEditMode && !Application.isPlaying)
                return;

            if (updateFrequency == UpdateFrequency.everyFrame)
                UpdateTVE();
        }

        public void UpdateTVE()
        {

#if THE_VEGETATION_ENGINE
            if (weatherSphere.climateModule)
            {
                globalControl.globalWetness = weatherSphere.climateModule.groundwaterAmount;
                globalControl.globalOverlay = weatherSphere.climateModule.snowAmount;
            }

            globalControl.seasonControl = weatherSphere.timeModule.yearPercentage * 4;

            if (weatherSphere.windModule)
            {
                globalMotion.windPower = weatherSphere.windModule.windAmount;
                globalMotion.transform.LookAt(globalMotion.transform.position + weatherSphere.windModule.WindDirection, Vector3.up);
            }
#elif THE_VISUAL_ENGINE
            if (weatherSphere.climateModule)
            {
                visualManager.globalAtmoData.wetnessIntensity = weatherSphere.climateModule.groundwaterAmount;
                visualManager.globalAtmoData.overlayIntensity = weatherSphere.climateModule.snowAmount;
            }

            visualManager.seasonControl = weatherSphere.timeModule.yearPercentage * 4;

            if (weatherSphere.windModule)
            {
                visualManager.motionControl = weatherSphere.windModule.windAmount;
                visualManager.transform.LookAt(visualManager.transform.position + weatherSphere.windModule.WindDirection, Vector3.up);
            }
#endif

        }
    }
}