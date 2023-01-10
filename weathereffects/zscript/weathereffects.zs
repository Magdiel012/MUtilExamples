class WeatherActor : Actor
{
	Default
	{
		Mass 8;
		Radius 2;
		Height 4;
		Gravity 1.5;
		+NOBLOCKMAP;
		+NOSPRITESHADOW;
		+NOTELEPORT;
		+THRUSPECIES;
		+DONTGIB;
		+DONTSPLASH;
		+FORCEYBILLBOARD;
		+MISSILE;
	}

	States
	{
	Spawn:
		TNT1 A 0;
		Loop;
	Death:
		TNT1 A 0;
		Stop;
	}
}

class WaterRipple : WeatherActor
{
	Default
	{
		Alpha 0.9;
		RenderStyle "Add";
		+NOINTERACTION;
		+FLATSPRITE;
		+NOGRAVITY;
	}

	States
	{
	Spawn:
		TNT1 A 0 { Angle = FRandom[Weather](0.0, 360.0); }
		RIPL AABBCCDDEEFFGG 1 Bright {
			A_SetTranslucent(max(0.0, invoker.Alpha - 0.9 / 14.0), 1);
			Scale += (0.075, 0.075);
		}
		Stop;
	}
}