using System;
using UnityEngine;


namespace DistantLands.Cozy
{
    [Serializable]
    public class MeridiemTime
    {

        public int hours
        {
            get
            {
                return Mathf.FloorToInt(timeAsPercentage * 24f);
            }
            set
            {
                float newHourOffset = value / 24f;
                float oldHourOffset = Mathf.FloorToInt(timeAsPercentage * 24f) / 24f;
                timeAsPercentage = timeAsPercentage - oldHourOffset + newHourOffset;
            }
        }
        public int minutes
        {
            get
            {
                return Mathf.FloorToInt(timeAsPercentage * 1440f % 60);
            }
            set
            {
                float newMinuteOffset = value / 1440f;
                float oldMinuteOffset = Mathf.FloorToInt(timeAsPercentage * 1440f) % 60f / 1440f;
                timeAsPercentage = timeAsPercentage - oldMinuteOffset + newMinuteOffset;
            }
        }
        public int seconds
        {
            get
            {
                return Mathf.FloorToInt(timeAsPercentage * 86400f % 3600);
            }
            set
            {
                float newSecondOffset = value / 86400f;
                float oldSecondOffset = Mathf.FloorToInt(timeAsPercentage * 86400f) % 3600 / 86400f;
                timeAsPercentage = timeAsPercentage - oldSecondOffset + newSecondOffset;
            }
        }
        public int milliseconds
        {
            get
            {
                return Mathf.FloorToInt(timeAsPercentage * 86400000f % 3600000f);
            }
            set
            {
                float newMillisecondOffset = value / 86400000f;
                float oldMillisecondOffset = Mathf.FloorToInt(timeAsPercentage * 86400000f) % 36000000f / 86400000f;
                timeAsPercentage = timeAsPercentage - oldMillisecondOffset + newMillisecondOffset;
            }
        }

        public float timeAsPercentage;

        public MeridiemTime() { }

        public MeridiemTime(int hour, int minute)
        {
            timeAsPercentage = (hour * 3600000f + minute * 60000f) / 86400000f;
        }
        public MeridiemTime(int hour, int minute, int second, int millisecond)
        {
            timeAsPercentage = (hour * 3600000f + minute * 60000f + second * 1000f + millisecond) / 86400000f;
        }
        public static implicit operator MeridiemTime(float floatValue)
        {
            MeridiemTime time = new MeridiemTime();
            time.timeAsPercentage = floatValue;
            return time;
        }
        public static implicit operator float(MeridiemTime time) => time.timeAsPercentage;
        public static implicit operator DateTime(MeridiemTime time) => new DateTime(1, 1, 1, time.hours, time.minutes, time.seconds, time.milliseconds);
        public static implicit operator string(MeridiemTime time) => $"{time.hours:D2}:{time.minutes:D2}";
        public new string ToString() => $"{hours:D2}:{minutes:D2}";
        public string FullString() => $"{hours:D2}:{minutes:D2}:{seconds:D2}:{milliseconds:D4}";
    }
}