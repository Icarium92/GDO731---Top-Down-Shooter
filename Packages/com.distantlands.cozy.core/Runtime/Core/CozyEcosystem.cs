//  Distant Lands 2024
//  COZY: Stylized Weather 3
//  All code included in this file is protected under the Unity Asset Store Eula

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using DistantLands.Cozy.Data;
using System.Linq;
#if UNITY_EDITOR
using UnityEditor;
#endif

namespace DistantLands.Cozy
{
    [System.Serializable]
    public class CozyEcosystem
    {
        public ForecastProfile forecastProfile;
        public enum EcosystemStyle { manual, forecast, dailyForecast, automatic }
        [Tooltip("How should this ecosystem manage weather selection? \n\n" +
        "[Manual] allows you to manually select the weather profiles and weights for this ecosystem,\n\n" +
        "[Automatic] allows you to manually select a weather profile and COZY will determine the weights automatically,\n\n" +
        "[Forecast] allows for dynamically changing weather based on a predetermined forecast that runs entirely on it's own,\n\n" +
        "[Daily Forecast] allows for a forecast that only changes at midnight every day for a more predictable playstyle.")]
        public EcosystemStyle weatherSelectionMode = EcosystemStyle.forecast;

        public List<WeatherPattern> currentForecast = new List<WeatherPattern>();

        [System.Serializable]
        public class WeatherPattern
        {
            public WeatherProfile profile;
            public MeridiemTime startTime;
            public MeridiemTime endTime;
            public float duration { get { return startTime < endTime ? (endTime - startTime) : (endTime + 1 - startTime); } }

        }
        public float weatherTransitionTime = 15;

        public float weatherTimer { get; set; }
        public CozyWeather weatherSphere;
        public CozySystem system;


        public WeatherProfile currentWeather;
        public WeatherProfile weatherChangeCheck;
        [WeatherRelation]
        public List<WeatherRelation> weightedWeatherProfiles = new List<WeatherRelation>();

        public WeatherRelation GetWeatherRelation(WeatherProfile profile, List<WeatherRelation> list)
        {


            WeatherRelation i = null;

            foreach (WeatherRelation j in list) { if (j.profile == profile) { i = j; return i; } }

            WeatherRelation k = new WeatherRelation();
            k.profile = profile;
            list.Add(k);
            i = list.Last();

            return i;

        }

        public void SetupEcosystem()
        {

            if (currentWeather == null)
                currentWeather = (WeatherProfile)Resources.Load("Profiles/Weather Profiles/Partly Cloudy");
            if (forecastProfile == null)
                forecastProfile = (ForecastProfile)Resources.Load("Profiles/Forecast Profiles/Complex Forecast Profile");

            weatherTimer = 0;

            if (Application.isPlaying)
            {
                if (weatherSelectionMode == EcosystemStyle.forecast || weatherSelectionMode == EcosystemStyle.dailyForecast)
                {
                    switch (forecastProfile.startWeatherWith)
                    {
                        case ForecastProfile.StartWeatherWith.InitialProfile:
                            {
                                if (forecastProfile.initialProfile == null)
                                {
                                    for (int i = 0; i < forecastProfile.forecastLength; i++)
                                        ForecastNewWeather();
                                    break;
                                }

                                ForecastNewWeather(forecastProfile.initialProfile);

                                for (int i = 1; i < forecastProfile.forecastLength; i++)
                                    ForecastNewWeather();

                                break;
                            }
                        case ForecastProfile.StartWeatherWith.InitialForecast:
                            {
                                for (int i = 0; i < forecastProfile.initialForecast.Count; i++)
                                    ForecastNewWeather(forecastProfile.initialForecast[i].profile, forecastProfile.initialForecast[i].duration);

                                for (int i = forecastProfile.initialForecast.Count; i < forecastProfile.forecastLength; i++)
                                    ForecastNewWeather();

                                break;
                            }
                        case ForecastProfile.StartWeatherWith.Random:
                            {
                                for (int i = 0; i < forecastProfile.forecastLength; i++)
                                    ForecastNewWeather();

                                break;
                            }
                    }

                    SetupWeather();
                }
                else if (weatherSelectionMode == EcosystemStyle.manual)
                {

                    if (weightedWeatherProfiles.Count > 0)
                        return;

                    weightedWeatherProfiles = new List<WeatherRelation>() { new WeatherRelation() };
                    weightedWeatherProfiles[0].profile = currentWeather;
                    weightedWeatherProfiles[0].weight = 1;

                    weatherChangeCheck = currentWeather;


                }
            }
        }

        public void SetupWeather()
        {

            weightedWeatherProfiles = new List<WeatherRelation>();

            WeatherProfile i = currentForecast[0].profile;

            currentWeather = i;
            if (weatherSelectionMode == EcosystemStyle.forecast)
                weatherTimer += currentForecast[0].duration;
            else if (weatherSelectionMode == EcosystemStyle.dailyForecast)
                weatherTimer += 1 - weatherSphere.dayPercentage;

            GetWeatherRelation(i, weightedWeatherProfiles).weight = 1;

            currentForecast.RemoveAt(0);
            ForecastNewWeather();

        }

        public void SkipTicks(float ticksToSkip)
        {

            weatherTimer -= ticksToSkip;

        }

        public void UpdateEcosystem()
        {
            if (weatherSphere == null)
            {
                Debug.LogWarning("No weather sphere found. Ecosystem is not running!");
                return;
            }

            if (Application.isPlaying)
            {
                if (weatherSelectionMode == EcosystemStyle.forecast || weatherSelectionMode == EcosystemStyle.dailyForecast)
                {

                    if (weatherSphere.timeModule)
                        weatherTimer -= Time.deltaTime * weatherSphere.timeModule.modifiedTimeSpeed;
                    else
                        weatherTimer -= Time.deltaTime;

                    while (weatherTimer <= 0)
                        SetNextWeather();

                }

                if (weatherChangeCheck != currentWeather)
                {
                    SetWeather(currentWeather, weatherTransitionTime);
                }

                weightedWeatherProfiles.RemoveAll(x => x.weight == 0 && x.transitioning == false);
            }
            else
            {
                if (weatherSelectionMode != EcosystemStyle.manual)
                    weightedWeatherProfiles = new List<WeatherRelation>() { new WeatherRelation() { profile = currentWeather, weight = 1 } };

                if (weatherChangeCheck != currentWeather)
                {
                    if (weatherChangeCheck)
                        weatherChangeCheck.SetWeatherWeight(0);

                    weatherChangeCheck = currentWeather;
                }
            }

            if (weatherSelectionMode == EcosystemStyle.manual)
                return;

            ClampEcosystem();
        }

        public void ClampEcosystem()
        {

            float j = 0;

            foreach (WeatherRelation i in weightedWeatherProfiles) j += i.weight;

            if (j == 0)
                j = 1;

            foreach (WeatherRelation i in weightedWeatherProfiles) i.weight /= j;

        }

        public void SetupWeatherForecast()
        {
            while (currentForecast.Count < forecastProfile.forecastLength)
            {
                ForecastNewWeather();
            }
        }

        public void SetNextWeather()
        {

            SetupWeatherForecast();
            if (currentForecast.Count == 0)
                ForecastNewWeather();

            SetWeather(currentForecast[0].profile);
            weatherTimer += currentForecast[0].duration;

            currentForecast.RemoveAt(0);
            ForecastNewWeather();

        }

        /// <summary>
        /// Transitions the weather profile over the the course of the weather transition time and all of the impacted settings. 
        /// </summary>  
        public void SetWeather(WeatherProfile prof, float transitionTime)
        {

            currentWeather = prof;
            weatherChangeCheck = currentWeather;

            if (weightedWeatherProfiles.Find(x => x.profile == prof) == null)
                weightedWeatherProfiles.Add(new WeatherRelation() { profile = prof, weight = 0, transitioning = true });

            foreach (WeatherRelation j in weightedWeatherProfiles)
            {
                if (j.profile == prof)
                    weatherSphere.StartCoroutine(j.Transition(1, transitionTime));
                else
                    weatherSphere.StartCoroutine(j.Transition(0, transitionTime));
            }
        }

        /// <summary>
        /// Transitions the weather profile using the default transition time. 
        /// </summary>  
        public void SetWeather(WeatherProfile prof)
        {

            SetWeather(prof, weatherTransitionTime);

        }

        public void ForecastNewWeather()
        {

            WeatherProfile weatherProfile;

            if (currentForecast.Count > 0)
                weatherProfile = PickRandomWeather(GetNextWeatherArray(forecastProfile.profilesToForecast.ToArray(), currentForecast.Last().profile.forecastNext, currentForecast.Last().profile.forecastModifierMethod));
            else
                weatherProfile = PickRandomWeather(forecastProfile.profilesToForecast.ToArray());

            ForecastNewWeather(weatherProfile, Random.Range(weatherProfile.minWeatherTime, weatherProfile.maxWeatherTime));

        }

        public void ForecastNewWeather(WeatherProfile weatherProfile)
        {

            ForecastNewWeather(weatherProfile, Random.Range(weatherProfile.minWeatherTime, weatherProfile.maxWeatherTime));

        }

        public void ForecastNewWeather(WeatherProfile weatherProfile, float duration)
        {

            WeatherPattern i = new WeatherPattern
            {
                profile = weatherProfile
            };
            if (weatherSelectionMode == EcosystemStyle.forecast)
            {
                i.startTime = weatherSphere.timeModule.currentTime + weatherTimer;

                foreach (WeatherPattern j in currentForecast)
                    i.startTime += j.duration;

                i.endTime = (i.startTime + duration) % 1;
                i.startTime %= 1;
            }
            else
            {
                i.startTime = 0;
                i.endTime = 1;
            }

            currentForecast.Add(i);

        }

        WeatherProfile PickRandomWeather(WeatherProfile[] profiles)
        {

            if (profiles.Count() == 0)
                profiles = forecastProfile.profilesToForecast.ToArray();

            WeatherProfile i = null;
            List<float> floats = new List<float>();
            float totalChance = 0;
            float weatherStartTime = 0;

            foreach (WeatherPattern k in currentForecast)
                weatherStartTime += k.endTime - k.startTime;


            foreach (WeatherProfile k in profiles)
            {
                float chance = k.GetChance(weatherSphere, weatherStartTime);
                floats.Add(chance);
                totalChance += chance;
            }

            float selection = Random.Range(0, totalChance);

            int m = 0;
            float l = 0;

            while (l <= selection)
            {
                if (m >= floats.Count)
                {
                    i = profiles[profiles.Length - 1];
                    break;
                }

                if (selection >= l && selection < l + floats[m])
                {
                    i = profiles[m];
                    break;
                }
                l += floats[m];
                m++;

            }

            if (!i)
            {
                i = profiles[0];
            }

            return i;
        }

        WeatherProfile[] SubtractiveArray(WeatherProfile[] total, WeatherProfile[] subtraction)
        {

            return total.ToList().Except(subtraction.ToList()).ToArray();

        }

        WeatherProfile[] IntersectionArray(WeatherProfile[] total, WeatherProfile[] intersection)
        {

            return intersection.ToList().Except(intersection.ToList().Except(total.ToList())).ToArray();

        }

        WeatherProfile[] GetNextWeatherArray(WeatherProfile[] total, WeatherProfile[] exception, WeatherProfile.ForecastModifierMethod modifierMethod)
        {

            switch (modifierMethod)
            {

                case (WeatherProfile.ForecastModifierMethod.DontForecastNext):
                    return SubtractiveArray(total, exception);
                case (WeatherProfile.ForecastModifierMethod.forecastNext):
                    return IntersectionArray(total, exception);
                default:
                    return total;

            }

        }

    }

// #if UNITY_EDITOR
//     public static class EcosystemEditor
//     {

//         public static bool selectionWindowIsOpen;
//         public static bool forecastWindowIsOpen;
//         public static bool currentWeatherWindowIsOpen;

//         public static void DrawEditor(SerializedProperty ecosystem)
//         {

//             selectionWindowIsOpen = EditorGUILayout.BeginFoldoutHeaderGroup(selectionWindowIsOpen, new GUIContent("    Selection Settings"), EditorUtilities.FoldoutStyle);

//             EditorGUILayout.EndFoldoutHeaderGroup();

//             bool useSingle = (CozyEcosystem.EcosystemStyle)ecosystem.FindPropertyRelative("weatherSelectionMode").enumValueIndex == CozyEcosystem.EcosystemStyle.automatic;

//             if (selectionWindowIsOpen)
//             {
//                 EditorGUI.BeginChangeCheck();
//                 EditorGUI.indentLevel++;
//                 EditorGUILayout.PropertyField(ecosystem.FindPropertyRelative("weatherSelectionMode"));
//                 if ((CozyEcosystem.EcosystemStyle)ecosystem.FindPropertyRelative("weatherSelectionMode").enumValueIndex != CozyEcosystem.EcosystemStyle.manual)
//                 {
//                     if ((CozyEcosystem.EcosystemStyle)ecosystem.FindPropertyRelative("weatherSelectionMode").enumValueIndex == CozyEcosystem.EcosystemStyle.automatic)
//                         EditorGUILayout.PropertyField(ecosystem.FindPropertyRelative("currentWeather"), new GUIContent("Current Weather"));
//                     else
//                         EditorGUILayout.PropertyField(ecosystem.FindPropertyRelative("currentWeather"), new GUIContent("Preview Weather"));
//                 }
//                 else
//                     EditorGUILayout.PropertyField(ecosystem.FindPropertyRelative("weightedWeatherProfiles"), new GUIContent("Weather Ratios"));

//                 EditorGUI.indentLevel--;

//             }
//             if ((CozyEcosystem.EcosystemStyle)ecosystem.FindPropertyRelative("weatherSelectionMode").enumValueIndex == CozyEcosystem.EcosystemStyle.automatic)
//             {
//                 currentWeatherWindowIsOpen = EditorGUILayout.BeginFoldoutHeaderGroup(currentWeatherWindowIsOpen, new GUIContent("    Profile Settings"), EditorUtilities.FoldoutStyle);

//                 EditorGUILayout.EndFoldoutHeaderGroup();

//                 if (currentWeatherWindowIsOpen)
//                 {
//                     EditorGUI.indentLevel++;
//                     (Editor.CreateEditor(ecosystem.FindPropertyRelative("currentWeather").objectReferenceValue) as E_WeatherProfile).DisplayInCozyWindow();
//                     EditorGUI.indentLevel--;
//                 }
//             }
//             else if ((CozyEcosystem.EcosystemStyle)ecosystem.FindPropertyRelative("weatherSelectionMode").enumValueIndex != CozyEcosystem.EcosystemStyle.manual)
//             {

//                 forecastWindowIsOpen = EditorGUILayout.BeginFoldoutHeaderGroup(forecastWindowIsOpen,
//                     new GUIContent("    Forecasting Behaviors"), EditorUtilities.FoldoutStyle);

//                 EditorGUILayout.EndFoldoutHeaderGroup();

//                 if (forecastWindowIsOpen)
//                 {

//                     EditorGUI.indentLevel++;
//                     EditorGUILayout.PropertyField(ecosystem.FindPropertyRelative("forecastProfile"));
//                     EditorGUILayout.Space();
//                     EditorGUI.indentLevel++;
//                     if (ecosystem.FindPropertyRelative("forecastProfile").objectReferenceValue)
//                         Editor.CreateEditor(ecosystem.FindPropertyRelative("forecastProfile").objectReferenceValue).OnInspectorGUI();
//                     EditorGUI.indentLevel--;
//                     EditorGUILayout.Space();
//                     EditorGUILayout.PropertyField(ecosystem.FindPropertyRelative("weatherTransitionTime"));
//                     EditorGUI.indentLevel--;

//                 }
//             }
//         }

//     }
// #endif

}