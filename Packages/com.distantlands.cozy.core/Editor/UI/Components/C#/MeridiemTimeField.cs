using UnityEditor;
using UnityEngine.UIElements;
using UnityEditor.UIElements;
using DistantLands.Cozy.Data;
using System.Collections.Generic;
using UnityEngine;

namespace DistantLands.Cozy.EditorScripts
{

    [CustomPropertyDrawer(typeof(MeridiemTime))]
    public class MeridiemTimeDrawer : PropertyDrawer
    {
        public override void OnGUI(Rect position, SerializedProperty property, GUIContent label)
        {

            EditorGUI.BeginProperty(position, label, property);

            position = EditorGUI.PrefixLabel(position, GUIUtility.GetControlID(FocusType.Keyboard), label);

            var indent = EditorGUI.indentLevel;
            EditorGUI.indentLevel = 0;
            float div = position.width - 50;

            var hoursRect = new Rect(position.x + div, position.y, 22, position.height);
            var colonRect = new Rect(position.x + div + 22, position.y, 5, position.height);
            var minutesRect = new Rect(position.x + div + 28, position.y, 22, position.height);
            var sliderRect = new Rect(position.x, position.y, div - 5, position.height);

            MeridiemTime time = property.FindPropertyRelative("timeAsPercentage").floatValue;

            EditorGUI.LabelField(colonRect, ":");
            EditorGUI.BeginChangeCheck();
            int hours = Mathf.Clamp(EditorGUI.IntField(hoursRect, GUIContent.none, Mathf.FloorToInt(time.hours)), 0, 24);
            int minutes = Mathf.Clamp(EditorGUI.IntField(minutesRect, GUIContent.none, Mathf.FloorToInt(time.minutes)), 0, 60);
            if (EditorGUI.EndChangeCheck())
                property.FindPropertyRelative("timeAsPercentage").floatValue = new MeridiemTime(hours, minutes);
            if (div > 55)
                property.FindPropertyRelative("timeAsPercentage").floatValue = GUI.HorizontalSlider(sliderRect, property.FindPropertyRelative("timeAsPercentage").floatValue, 0, 1);

            EditorGUI.indentLevel = indent;

            EditorGUI.EndProperty();
        }
    }


}