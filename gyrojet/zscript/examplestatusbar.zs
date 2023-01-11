class ExampleStatusBar : DoomStatusBar
{
	override void Draw(int state, double TicFrac)
	{
		Super.Draw(state, TicFrac);

		if (state == HUD_None) return;

		WeaponBase weap = WeaponBase(CPlayer.ReadyWeapon);

		if (weap)
		{
			Console.Printf("Here.");
			HUDExtension extension = weap.GetHUDExtension();

			if (extension)
			{
				extension.CallDraw(state, TicFrac);
			}
		}
	}
}