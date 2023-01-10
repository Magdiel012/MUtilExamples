class GyrojetHUD : HUDExtension
{
	const JITTER_MAX_MAGNITUDE = 0.0115;
	const JITTER_SMOOTH_TIME = 0.3;

	const FONT_SCALE = 2.25;

	const JOBLFONT_BASE_HEIGHT = 11;
	const JOBLFONT_TOP_OFFSET = 7;
	const JOBLFONT_BASELINE_OFFSET = 5;

	const JENOBIG_BASE_HEIGHT = 14;
	const JENOBIG_BASELINE_OFFSET = 4;

	const WHOA_TIME = 0.375;

	Gyrojet m_Gyrojet;

	transient ui HUDFont m_AmmoFont;
	ui vector2 m_HUDOrigin;

	double m_WhoaTimer;

	vector2 m_BaseRoundsJitter;

	double m_NextJitterScale;
	double m_JitterScale;
	double m_JitterScaleSpeed;

	private ui double m_UIScale;

	override SMHUDMachine CreateHUDStateMachine()
	{
		return new("SMHUDGyrojetMachine");
	}

	override void Setup()
	{
		m_Gyrojet = Gyrojet(m_Context);
	}

	override void UISetup()
	{
		m_HUDOrigin = (0.865, 0.77);
		Font roundsFont = "JENOBIG";
		m_AmmoFont = HUDFont.Create(roundsFont);
	}

	override void Tick()
	{
		m_BaseRoundsJitter = (
			FRandom(-JITTER_MAX_MAGNITUDE, JITTER_MAX_MAGNITUDE),
			FRandom(-JITTER_MAX_MAGNITUDE, JITTER_MAX_MAGNITUDE));

		if (m_WhoaTimer > 0) m_WhoaTimer -= 1.0 / TICRATE;

		m_JitterScale = m_NextJitterScale;
		m_NextJitterScale = Math.SmoothDamp(
			m_NextJitterScale,
			0.0,
			m_JitterScaleSpeed,
			JITTER_SMOOTH_TIME,
			double.Infinity,
			1.0 / TICRATE);
	}

	override void Draw(RenderEvent event)
	{
		// The HUD font needs to be transient, so it'll be cleared when
		// loading a save and if that happens there's no way to create it
		// before the first draw call.
		if (!m_AmmoFont)
		{
			Font roundsFont = "JENOBIG";
			m_AmmoFont = HUDFont.Create(roundsFont);
		}

		if (uiscale == 0)
		{
			int vscale = Screen.GetHeight() / 400;
			int hscale = Screen.GetWidth() / 640;
			m_UIScale = max(1, min(vscale, hscale));
		}
		else
		{
			m_UIScale = uiscale;
		}

		Super.Draw(event);
	}

	ui double GetUIScale() const
	{
		return m_UIScale;
	}
}

class SMHUDGyrojetState : SMHUDState
{
	GyrojetHUD m_GyrojetHUD;

	int m_OriginalRelTop;
	int m_OriginalHorizontalResolution;
	int m_OriginalVerticalResolution;

	override void EnterState()
	{
		if (!m_GyrojetHUD) m_GyrojetHUD = GyrojetHUD(GetData());
	}

	override void PreDraw(RenderEvent event)
	{
		if (automapactive) return;

		// Store these to clean up after drawing.
		m_OriginalRelTop = StatusBar.RelTop;
		m_OriginalHorizontalResolution = StatusBar.HorizontalResolution;
		m_OriginalVerticalResolution = StatusBar.VerticalResolution;

		StatusBar.SetSize(0, 1280, 720);
		StatusBar.BeginHUD(forcescaled: true);
	}

	override void Draw(RenderEvent event)
	{
		if (automapactive) return;

		vector2 ammoLabelOrigin = (m_GyrojetHUD.m_HUDOrigin.x, m_GyrojetHUD.m_HUDOrigin.y - 0.05);
		vector2 ammoLabelScale = ScreenUtil.ScaleRelativeToBaselineRes(
			GyrojetHUD.FONT_SCALE * max(1.0, uiscale),
			GyrojetHUD.FONT_SCALE * max(1.0, uiscale),
			StatusBar.HorizontalResolution,
			StatusBar.VerticalResolution);

		StatusBar.DrawImage(
			"M_AMMO",
			ScreenUtil.NormalizedPositionToView(ammoLabelOrigin),
			scale: ammoLabelScale);

		vector2 fireModeOrigin = (1.0, m_GyrojetHUD.m_HUDOrigin.y + 0.02);
		vector2 fireModeScale = ScreenUtil.ScaleRelativeToBaselineRes(
			2.0 * max(1.0, uiscale),
			2.0 * max(1.0, uiscale),
			StatusBar.HorizontalResolution,
			StatusBar.VerticalResolution);

		string fireModeTexture;

		switch (m_GyrojetHUD.m_Gyrojet.GetFireMode())
		{
			case Gyrojet.SemiAuto:
				fireModeTexture = "M_PISL1";
				break;
			case Gyrojet.Burst:
				fireModeTexture = "M_PISL2";
				break;
			// Missing M_PISL3.
			// case Gyrojet.FullAuto:
			// 	fireModeTexture = "M_PISL3";
			// 	break;
			default:
				break;
		}
		StatusBar.DrawImage(
			fireModeTexture,
			ScreenUtil.NormalizedPositionToView(fireModeOrigin),
			StatusBarCore.DI_ITEM_RIGHT,
			scale: fireModeScale);
	}

	override void PostDraw(RenderEvent event)
	{
		if (automapactive) return;

		// Cleanup.
		StatusBar.SetSize(m_OriginalRelTop, m_OriginalHorizontalResolution, m_OriginalVerticalResolution);

		// No clue why this is needed along with BeginStatusBar, but status bar
		// frames break without it.
		StatusBar.BeginHUD(forcescaled: false);
		StatusBar.BeginStatusBar();
	}
}

class SMHUDGyrojetActive : SMHUDGyrojetState
{
	override bool TryHandleEvent(name eventId)
	{
		switch (eventId)
		{
			case 'WeaponFired':
				m_GyrojetHUD.m_NextJitterScale = 1.0;
				return true;

			default:
				return false;
		}
	}

	override void Draw(RenderEvent event)
	{
		Super.Draw(event);

		if (automapactive) return;

		double jitterScale = Math.Lerp(m_GyrojetHUD.m_JitterScale, m_GyrojetHUD.m_NextJitterScale, event.FracTic);

		vector2 roundsJitter = (m_GyrojetHUD.m_BaseRoundsJitter.x * jitterScale, m_GyrojetHUD.m_BaseRoundsJitter.y * jitterScale);

		vector2 ammoFontScale = ScreenUtil.ScaleRelativeToBaselineRes(
			GyrojetHUD.FONT_SCALE * max(1.0, uiscale),
			GyrojetHUD.FONT_SCALE * max(1.0, uiscale),
			StatusBar.HorizontalResolution,
			StatusBar.VerticalResolution);

		vector2 ammoCountOrigin = (
			m_GyrojetHUD.m_HUDOrigin.x - 0.01,
			m_GyrojetHUD.m_HUDOrigin.y + 0.05);

		vector2 ammoCountArea = ScreenUtil.ScaleRelativeToBaselineRes(
			0.2 * log(max(1.0, uiscale) * 1.5),
			0.2 * log(max(1.0, uiscale) * 1.5),
			StatusBar.HorizontalResolution,
			StatusBar.VerticalResolution);

		vector2 ammoCountTextArea = ammoCountArea * 0.35;

		vector2 ammoCountTopLeft, ammoCountTopRight, ammoCountBottomLeft, ammoCountBottomRight;
		[
			ammoCountTopLeft,
			ammoCountTopRight,
			ammoCountBottomLeft,
			ammoCountBottomRight
		] = ScreenUtil.RectFromCenter(ammoCountOrigin, ammoCountArea.x, ammoCountArea.y);

		vector2 ammoCountTextTopLeft, ammoCountTextTopRight, ammoCountTextBottomLeft, ammoCountTextBottomRight;
		[
			ammoCountTextTopLeft,
			ammoCountTextTopRight,
			ammoCountTextBottomLeft,
			ammoCountTextBottomRight
		] = ScreenUtil.RectFromCenter(ammoCountOrigin, ammoCountTextArea.x, ammoCountTextArea.y);

		vector2 roundsOrigin = ammoCountTextTopLeft + roundsJitter;
		vector2 roundsPosition = ScreenUtil.NormalizedPositionToView(roundsOrigin);

		// DrawString ignores item align flags, manually move text up.
		roundsPosition.y -= GyrojetHUD.JENOBIG_BASE_HEIGHT * ammoFontScale.y;

		string roundsText = m_GyrojetHUD.m_WhoaTimer > 0.0
			? "WHOA!!"
			: StatusBarCore.FormatNumber(m_GyrojetHUD.m_Gyrojet.m_Rounds);

		StatusBar.DrawString(
			m_GyrojetHUD.m_AmmoFont,
			roundsText,
			roundsPosition,
			StatusBarCore.DI_TEXT_ALIGN_RIGHT,
			scale: ammoFontScale);

		vector2 dividerStart = ScreenUtil.NormalizedPositionToView(ammoCountTopRight);
		vector2 dividerEnd = ScreenUtil.NormalizedPositionToView(ammoCountBottomLeft);

		Screen.DrawThickLine(
			dividerStart.x,
			dividerStart.y,
			dividerEnd.x,
			dividerEnd.y,
			3, 0xc70000);

		vector2 capacityPosition = ScreenUtil.NormalizedPositionToView(ammoCountTextBottomRight);

		StatusBar.DrawString(
			m_GyrojetHUD.m_AmmoFont,
			StatusBarCore.FormatNumber(m_GyrojetHUD.m_Gyrojet.m_Capacity),
			capacityPosition,
			StatusBarCore.DI_TEXT_ALIGN_LEFT,
			scale: ammoFontScale);
	}
}

class SMHUDGyrojetReloading : SMHUDGyrojetState
{
	double m_FadePlayback;

	override void EnterState()
	{
		Super.EnterState();
		m_FadePlayback = 0.0;
	}

	override bool TryHandleEvent(name eventId)
	{
		switch (eventId)
		{
			case 'WeaponFired':
				GyrojetHUD(GetHUDExtension()).m_NextJitterScale = 1.0;
				return true;

			default:
				return false;
		}
	}

	override void UpdateState()
	{
		m_FadePlayback++;
	}

	override void Draw(RenderEvent event)
	{
		Super.Draw(event);

		if (automapactive) return;

		vector2 ammoFontScale = ScreenUtil.ScaleRelativeToBaselineRes(
			GyrojetHUD.FONT_SCALE * max(1.0, uiscale),
			GyrojetHUD.FONT_SCALE * max(1.0, uiscale),
			StatusBar.HorizontalResolution,
			StatusBar.VerticalResolution);

		vector2 reloadTextOrigin = ScreenUtil.NormalizedPositionToView((
			m_GyrojetHUD.m_HUDOrigin.x - 0.01,
			m_GyrojetHUD.m_HUDOrigin.y + 0.05));
		reloadTextOrigin.y -= GyrojetHUD.JENOBIG_BASE_HEIGHT / 2.0 * ammoFontScale.y;

		double alphaPlayback = (m_FadePlayback + event.FracTic) / TICRATE * 180.0;
		double textAlpha = sin(alphaPlayback * 2.0) / 4.0 + 0.75;

		StatusBar.DrawString(
			m_GyrojetHUD.m_AmmoFont,
			"Reloading...",
			reloadTextOrigin,
			StatusBarCore.DI_TEXT_ALIGN_CENTER,
			Alpha: textAlpha,
			scale: ammoFontScale);
	}
}

class SMHUDGyrojetReloadInterruptTransition : SMTransition
{
	override void OnTransitionPerformed(SMState inState)
	{
		let hud = GyrojetHUD(inState.GetData());

		hud.m_WhoaTimer = GyrojetHUD.WHOA_TIME;
	}
}

class SMHUDGyrojetMachine : SMHUDMachine
{
	override void Build()
	{
		Super.Build();

		GetHUDActiveState()
			.AddChild(new("SMHUDGyrojetActive"))
			.AddChild(new("SMHUDGyrojetReloading"))

			.AddTransition(new("SMTransition")
				.From("SMHUDGyrojetActive")
				.To("SMHUDGyrojetReloading")
				.On('WeaponReloading')
			)
			.AddTransition(new("SMTransition")
				.From("SMHUDGyrojetReloading")
				.To("SMHUDGyrojetActive")
				.On('ReloadComplete')
			)
			.AddTransition(new("SMHUDGyrojetReloadInterruptTransition")
				.From("SMHUDGyrojetReloading")
				.To("SMHUDGyrojetActive")
				.On('ReloadInterrupted')
			)
		;
	}
}