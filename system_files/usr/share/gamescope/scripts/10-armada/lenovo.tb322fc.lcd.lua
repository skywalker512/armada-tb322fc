-- Lenovo Legion Y700 Gen 4 (TB322FC, "elden") internal LCD: CSOT PP8807HB1.
-- Panel exposes no EDID; gamescope synthesizes one (gamescope patch 0002)
-- and this profile supplies the identity it lacks.
-- HDR values and gamut are taken from h0cheung/tb322fc-linux
-- packages/gamescope-armada/csot.pp8807hb1-1.lua, whose comments attribute
-- them to the Android vendor DT's qcom,mdss-dsi-panel-hdr-* properties.
-- The mainline elden.dts does not carry those properties; this repo has not
-- independently verified them.
gamescope.config.known_displays.armada_lenovo_tb322fc_lcd = {
	pretty_name = "CSOT PP8807HB1 (Lenovo Y700 Gen 4)",
	hdr = {
		supported = true,
		force_enabled = false,
		eotf = gamescope.eotf.gamma22,
		-- Peak 1000 nits, from qcom,mdss-dsi-panel-peak-brightness.
		max_content_light_level = 1000,
		max_frame_average_luminance = 600,
		min_content_light_level = 0.5,
	},
	-- sRGB/Rec.709 primaries, from qcom,mdss-dsi-panel-hdr-color-primaries.
	colorimetry = {
		r = { x = 0.640, y = 0.340 },
		g = { x = 0.310, y = 0.600 },
		b = { x = 0.160, y = 0.060 },
		w = { x = 0.290, y = 0.310 },
	},
	matches = function(display)
		return display.device_id == "lenovo-tb322fc"
			and display.internal
			and display.connector == "DSI-1"
			and 6000 or -1
	end,
}
debug("Registered CSOT PP8807HB1 (Lenovo Y700 Gen 4) as a known display")
