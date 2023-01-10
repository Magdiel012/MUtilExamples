class Gyrojet : WeaponBase
{
	enum EFireMode
	{
		SemiAuto,
		Burst,
		FullAuto,
		EFireModeEnd
	}

	int m_Rounds;

	int m_Capacity;
	property Capacity: m_Capacity;

	int m_BurstLength;
	property BurstLength: m_BurstLength;

	uint m_SemiTicsPerAttack;
	property SemiTicsPerAttack: m_SemiTicsPerAttack;
	uint m_BurstTicsPerAttack;
	property BurstTicsPerAttack: m_BurstTicsPerAttack;
	uint m_FullTicsPerAttack;
	property FullTicsPerAttack: m_FullTicsPerAttack;

	private EFireMode m_FireMode;

	Default
	{
		+WEAPON.NOAUTOFIRE;
		+WEAPON.AMMO_OPTIONAL;
		Inventory.PickupMessage "Mmmm, a gyro!(2)";
		Weapon.AmmoUse 1;
		Weapon.AmmoGive1 30;
		Weapon.AmmoType1 "Clip";
		DamageType "Normal";
		Weapon.SlotNumber 2;

		WeaponBase.MachineType "SMGyrojetMachine";
		WeaponBase.HUDExtensionType "";
		WeaponBase.BobAnimation 'GyrojetBob';

		WeaponBase.MaxRecoilTranslationX 20.0;
		WeaponBase.MaxRecoilTranslationY 10.0;
		WeaponBase.MaxRecoilScaleX 1.4;
		WeaponBase.MaxRecoilScaleY 1.4;
		WeaponBase.RecoilResponse 40.0;
		WeaponBase.RecoilRigidity 26.0;

		WeaponBase.BobIntensityResponseTime 1.5 / TICRATE;

		Gyrojet.Capacity 18;
		Gyrojet.BurstLength 3;
		Gyrojet.SemiTicsPerAttack 1;
		Gyrojet.BurstTicsPerAttack 8;
		Gyrojet.FullTicsPerAttack 4;
	}

	States
	{
	SwitchingIn:
		GYRI A 1 A_SetBaseOffset(67, 100);
		GYRI A 1 A_SetBaseOffset(54, 81);
		GYRI A 1 A_SetBaseOffset(32, 69);
		GYRI A 1 A_SetBaseOffset(22, 58);
		GYRI A 1 A_SetBaseOffset(2, 34);
		GYRI A 1 A_RaiseSMNotify(16);
		Wait;

	SwitchingOut:
		GYRI A 1 A_LowerSMNotify(16);
		Loop;

	Idle:
		GYRI A 1 A_WeaponReady(WRF_NOFIRE);
		Loop;

	Firing:
		GYRF A 1 {
			A_WeaponRecoil((3, 5), 0.0, (1.15, 1.15));
			// A_QuakeEx(2, 3, 2, 3, 0, 40, flags: QF_SCALEDOWN);
			A_SendEventToSM('WeaponFired');
			A_SpawnEffect("SmokeSpawner", (12.5, 8.0, 38.0), 0.0, 0.0, 0.0);
			A_StartSound("gyrojet/fire", CHAN_AUTO);
		}
		GYRF B 1;
		GYRI A 1;
		---- A 0 A_SendEventToSM('FireComplete');
		---- A 0 A_SendEventToSM('AnimComplete');
		Stop;

	ReloadStart:
		TNT1 A 0 A_StartSound("gyrojet/magout", 0);
		GYRR ABCDEFGH 1;
		GYRR H 1 A_StartSound("gyrojet/boltback", 0);
		GYRR IJK 1;
		GYRR L 3;
		GYRR MNOP 2;
		---- A 0 A_SendEventToSM('AnimComplete');
	ReloadMid:
		GYRR QRST 2;
		GYRR U 1 {
			A_StartSound("gyrojet/magins", CHAN_AUTO);
			A_SendEventToSM("MagLoaded");
		}
		GYRR VWXYZ 1;
		GRRR ABCDE 2;
		TNT1 A 0 A_StartSound("gyrojet/boltrel", CHAN_AUTO);
		GRRR FGHIJKLMNOPQRST 1;
		---- T 0 A_SendEventToSM('AnimComplete');
		Stop;
	}

	override void TryHandleButtonEvent(int event, int eventType)
	{
		if (eventType != BTEVENT_Pressed) return;

		switch (event)
		{
			case BT_ATTACK:
				if (m_FireMode == FullAuto) break;

				if (m_Rounds > 0)
				{
					m_StateMachine.SendEvent('AttackAttempted');
				}
				else if (Ammo1.Amount > 0)
				{
					m_StateMachine.SendEvent('ReloadStarted');
				}
				break;

			case BT_ALTATTACK:
				S_StartSound("weapon/click2", CHAN_AUTO);
				CycleFireMode();
				break;

			case BT_RELOAD:
				if (m_Rounds < m_Capacity && Ammo1.Amount > 0)
				{
					m_StateMachine.SendEvent('ReloadStarted');
				}
				break;

			default:
				break;
		}
	}

	override void BeginPlay()
	{
		Super.BeginPlay();
		m_Rounds = m_Capacity;
		SetTicsPerAttackForFireMode();
	}

	override void DoEffect()
	{
		Super.DoEffect();

		if (!IsSelected()) return;

		if (m_FireMode == FullAuto && AreButtonsHeld(BT_ATTACK))
		{
			if (m_Rounds > 0)
			{
				m_StateMachine.SendEvent('AttackAttempted');
			}
			else if (Ammo1.Amount > 0)
			{
				m_StateMachine.SendEvent('ReloadStarted');
			}
		}
	}

	EFireMode GetFireMode() const
	{
		return m_FireMode;
	}

	private void SetTicsPerAttackForFireMode()
	{
		switch (m_FireMode)
		{
			case SemiAuto:
				m_TicsPerAttack = m_SemiTicsPerAttack;
				break;
			case Burst:
				m_TicsPerAttack = m_BurstTicsPerAttack;
				break;
			case FullAuto:
				m_TicsPerAttack = m_FullTicsPerAttack;
				break;
		}
	}

	private void CycleFireMode()
	{
		++m_FireMode;
		// Disabled full-auto because no HUD for it :(
		// m_FireMode %= EFireModeEnd;
		m_FireMode %= FullAuto;
		SetTicsPerAttackForFireMode();
	}

	private void PrintFireMode()
	{
		string mode;
		switch (m_FireMode)
		{
			case SemiAuto:
				mode = "Semi-auto";
				break;
			case Burst:
				mode = "Burst";
				break;
			case FullAuto:
				mode = "Full-auto";
				break;
		}
		Console.Printf("Fire mode: %s", mode);
	}
}

class SMGyrojetMachine : SMWeaponMachine
{
	override void Build()
	{
		Super.Build();

		GetEquippedState()
			.AddChild(new("SMGyrojetIdle"))
			.AddChild(new("SMGyrojetFiring"))
			.AddChild(new("SMGyrojetReloadStart"))
			.AddChild(new("SMGyrojetReloadMid"))

			.AddTransition(new("SMGyrojetRefireTransition")
				.From("SMGyrojetIdle")
				.To("SMGyrojetFiring")
				.On('AttackAttempted')
			)
			.AddTransition(new("SMGyrojetRefireTransition")
				.From("SMGyrojetFiring")
				.To("SMGyrojetFiring")
				.On('AttackAttempted')
			)
			.AddTransition(new("SMGyrojetReloadInterruptTransition")
				.From("SMGyrojetReloadStart")
				.To("SMGyrojetFiring")
				.On('AttackAttempted')
			)
			.AddTransition(new("SMTransitionPlay")
				.From("SMGyrojetFiring")
				.To("SMGyrojetIdle")
				.On('AnimComplete')
			)
			.AddTransition(new("SMTransitionPlay")
				.From("SMGyrojetIdle")
				.To("SMGyrojetReloadStart")
				.On('ReloadStarted')
			)
			.AddTransition(new("SMTransitionPlay")
				.From("SMGyrojetReloadStart")
				.To("SMGyrojetReloadMid")
				.On('AnimComplete')
			)
			.AddTransition(new("SMTransitionPlay")
				.From("SMGyrojetReloadMid")
				.To("SMGyrojetIdle")
				.On('AnimComplete')
			)
		;
	}
}

class SMGyrojetIdle : SMWeaponState
{
	override void EnterState()
	{
		let gyro = Gyrojet(GetWeapon());
		// gyro.GetHUDExtension().SendEventToSM('WeaponActive');
		SetWeaponSprite("Idle");
	}
}

class SMGyrojetFiring : SMWeaponState
{
	int shotCount;

	override void EnterState()
	{
		shotCount = 0;
		let gyro = Gyrojet(GetWeapon());
		// gyro.GetHUDExtension().SendEventToSM('WeaponActive');
		SetWeaponSprite("Firing");
	}

	override bool TryHandleEvent(name eventId)
	{
		let gyro = Gyrojet(GetWeapon());
		switch (eventId)
		{
			case 'WeaponFired':
				gyro.FireProjectile(
					"GyroRocket",
					(1.0, 1.0),
					(10.0, 8.0, 4.0),
					ammoCost: 0);
				gyro.m_Rounds -= gyro.AmmoUse1;
				// gyro.GetHUDExtension().SendEventToSM(eventID);
				return true;

			case 'FireComplete':
				if (gyro.GetFireMode() == Gyrojet.Burst
					&& shotCount < gyro.m_BurstLength - 1
					&& gyro.m_Rounds > 0)
				{
					SetWeaponSprite("Firing");
					++shotCount;
					return true;
				}
				return false;

			default:
				return false;
		}
	}
}

class SMGyrojetReloadStart : SMWeaponState
{
	override void EnterState()
	{
		SetWeaponSprite('ReloadStart');
		let gyro = Gyrojet(GetWeapon());
		// gyro.GetHUDExtension().SendEventToSM('WeaponReloading');
	}
}

class SMGyrojetReloadMid : SMWeaponState
{
	override bool TryHandleEvent(name eventId)
	{
		switch (eventId)
		{
			case 'MagLoaded':
				let gyro = Gyrojet(GetWeapon());
				int loadAmount = gyro.m_Capacity - gyro.m_Rounds;
				gyro.Ammo1.Amount -= loadAmount;
				gyro.m_Rounds += loadAmount + min(0, gyro.Ammo1.Amount);
				gyro.Ammo1.Amount = clamp(gyro.Ammo1.Amount, 0, gyro.Ammo1.BackpackMaxAmount);
				return true;

			default:
				return false;
		}
	}

	override void ExitState()
	{
		let gyro = Gyrojet(GetWeapon());
		// gyro.GetHUDExtension().SendEventToSM('ReloadComplete');
	}
}

class SMGyrojetRefireTransition : SMTransitionPlay
{
	override bool CanPerform(Object data)
	{
		let gyro = Gyrojet(data);
		return gyro.m_Rounds >= gyro.AmmoUse1
			&& gyro.GetTicsSinceLastAttack() >= gyro.m_TicsPerAttack;
	}
}

class SMGyrojetReloadInterruptTransition : SMGyrojetRefireTransition
{
	override void OnTransitionPerformed(SMStatePlay inState)
	{
		let gyro = Gyrojet(inState.GetData());
		// gyro.GetHUDExtension().SendEventToSM('ReloadInterrupted');
	}
}

class GyroRocket : ProjectileBase
{
	Default
	{
		+RANDOMIZE;
		-NOGRAVITY;
		Gravity 0.10;
		Radius 2;
		Height 4;
		Scale 0.3;
		+BLOODSPLATTER;
		+NOEXTREMEDEATH;
		//Decal "Scorch";
		Damage (8);
		+ROCKETTRAIL;
		//+Ripper;
		Speed 40;
	}

	States
	{
	Spawn:
		RKLP A 1 Bright;
		Loop;

	Death:
		TNT1 A 0 Bright {
			array<Actor> exclusions;
			exclusions.Push(self);
			exclusions.Push(target);
			ActorUtil.Explode3D(self, 12, 64.0, 96.0, exclusions: exclusions);
			A_StartSound("gyrojet/pop", CHAN_AUTO);
		}
		TNT1 AA 0 {
			A_SpawnProjectile("RocketDebris", 0.0);
			A_SpawnProjectile("SmokeSpawner", 0.0);
		}
		EXPL ABCD 1 Bright A_SetTranslucent(0.8, 1);
		EXPL EFGH 1 Bright A_SetTranslucent(0.5, 1);
		EXPL IJKLMNO 1 Bright A_SetTranslucent(0.3, 1);
		Stop;
	}
}
