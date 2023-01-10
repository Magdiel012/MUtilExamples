class ExamplePlayer : DoomPlayer
{
	Default
	{
		Player.StartItem "Fist";
		Player.StartItem "Gyrojet";
		Player.StartItem "Clip", 50;
		Player.WeaponSlot 2, "Pistol", "Gyrojet";
	}
}