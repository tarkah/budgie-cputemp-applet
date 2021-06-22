public class CpuTempPlugin : Budgie.Plugin, Peas.ExtensionBase {
	public Budgie.Applet get_panel_widget(string uuid) {
		return new CpuTempApplet(uuid);
	}
}

public class CpuTempApplet : Budgie.Applet {
	public string uuid { public set; public get; }

	protected Gtk.EventBox widget;
	protected Gtk.Box layout;
	protected Gtk.Label temp_label;
	protected Gtk.Image? applet_icon;
	protected ThemedIcon? cpu_chip_icon;

	private Settings? settings;

	private double temp;
	private Sensors.Sensor[] sensors;
	private Sensors.Sensor? sensor;

	private Budgie.PanelPosition panel_position = Budgie.PanelPosition.BOTTOM;

	Budgie.Popover? popover = null;
	private unowned Budgie.PopoverManager? manager = null;

	protected Gtk.ComboBoxText sensor_combobox;
	protected Gtk.Entry sensor_entry;

	public override bool supports_settings() {
		return false;
	}

	public CpuTempApplet(string uuid) {
		Object(uuid: uuid);
		
		// Setup settings
		settings_schema = "com.github.tarkah.budgie-cputemp-applet";
		settings_prefix = "/com/github/tarkah/budgie-cputemp-applet";

		settings = this.get_applet_settings(uuid);
		settings.changed.connect(on_settings_change);

		// Get sensors
		get_sensors();
		on_settings_change("sensor");

		widget = new Gtk.EventBox();

		layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 4);
		layout.margin_start = 8;
		layout.margin_end = 8;

		widget.add(layout);

		cpu_chip_icon = new ThemedIcon.from_names( {"chip-cpu-symbolic"} );
		applet_icon = new Gtk.Image.from_gicon(cpu_chip_icon, Gtk.IconSize.MENU);
		layout.pack_start(applet_icon, false, false, 0);

		temp_label = new Gtk.Label("0.0°");
		temp_label.valign = Gtk.Align.CENTER;

		layout.pack_start(temp_label, false, false, 0);

		popover = new Budgie.Popover(widget);
		popover.add(create_menu());

		widget.button_press_event.connect((e) => {
			if (e.button != 1) {
				return Gdk.EVENT_PROPAGATE;
			}
			if (popover.get_visible()) {
				popover.hide();
			} else {
				this.manager.show_popover(widget);
			}
			return Gdk.EVENT_STOP;
		});

		temp = 0.0;
		update_temp();

		Timeout.add_seconds_full(Priority.LOW, 1, update_temp);

		add(widget);
		popover.get_child().show_all();

		show_all();
	}

	void on_settings_change(string key) {
		if (key != "sensor") {
			return;
		}

		string sensor_name = settings.get_string(key);

		foreach (var sensor in this.sensors) {
			if (sensor.display_name() == sensor_name) {
				this.sensor = sensor;
			}
		}

		update_temp();
	}

	protected Gtk.Grid create_menu() {
		// Create a submenu system
		var menu = new Gtk.Grid();
		menu.row_spacing = 6;
		menu.border_width = 12;

		// Sensors
		var sensor_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 4);
		sensor_box.spacing = 12;

		var sensor_label = new Gtk.Label(_ ("Sensor"));
		sensor_label.halign = Gtk.Align.START;
		sensor_label.valign = Gtk.Align.CENTER;
		sensor_box.pack_start(sensor_label);

		sensor_combobox = new Gtk.ComboBoxText.with_entry();
		sensor_combobox.halign = Gtk.Align.END;
		sensor_combobox.valign = Gtk.Align.CENTER;
		foreach (var sensor in this.sensors) {
			sensor_combobox.append_text(sensor.display_name());
		}

		sensor_entry = (Gtk.Entry)sensor_combobox.get_child();
		sensor_entry.placeholder_text = _ ("Choose...");
		sensor_entry.can_focus = false;
		sensor_box.pack_start(sensor_combobox);
		menu.attach(sensor_box, 0, 0);

		settings.bind("sensor", sensor_entry, "text", SettingsBindFlags.DEFAULT);

		// Fahrenheit Scale
		var scale_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 4);
		sensor_box.spacing = 12;

		var scale_label = new Gtk.Label(_ ("Fahrenheit Scale"));
		scale_label.halign = Gtk.Align.START;
		scale_label.valign = Gtk.Align.CENTER;
		scale_box.pack_start(scale_label);

		var scale_switch = new Gtk.Switch();
		scale_switch.can_focus = false;
		scale_switch.halign = Gtk.Align.END;
		scale_switch.valign = Gtk.Align.CENTER;
		scale_box.pack_start(scale_switch);
		menu.attach(scale_box, 0, 1);

		settings.bind("fahrenheit", scale_switch, "active", SettingsBindFlags.DEFAULT);

		// Show C/F Sign
		var sign_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 4);
		sign_box.spacing = 12;

		var sign_label = new Gtk.Label(_ ("Show C/F Sign"));
		sign_label.halign = Gtk.Align.START;
		sign_label.valign = Gtk.Align.CENTER;
		sign_box.pack_start(sign_label);

		var sign_switch = new Gtk.Switch();
		sign_switch.can_focus = false;
		sign_switch.halign = Gtk.Align.END;
		sign_switch.valign = Gtk.Align.CENTER;
		sign_box.pack_start(sign_switch);
		menu.attach(sign_box, 0, 2);

		settings.bind("show-sign", sign_switch, "active", SettingsBindFlags.DEFAULT);

		// Show Fraction
		var fraction_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 4);
		fraction_box.spacing = 12;

		var fraction_label = new Gtk.Label(_ ("Show Fraction"));
		fraction_label.halign = Gtk.Align.START;
		fraction_label.valign = Gtk.Align.CENTER;
		fraction_box.pack_start(fraction_label);

		var fraction_switch = new Gtk.Switch();
		fraction_switch.can_focus = false;
		fraction_switch.halign = Gtk.Align.END;
		fraction_switch.valign = Gtk.Align.CENTER;
		fraction_box.pack_start(fraction_switch);
		menu.attach(fraction_box, 0, 3);

		settings.bind("show-fraction", fraction_switch, "active", SettingsBindFlags.DEFAULT);

		return menu;
	}

	protected void get_sensors() {
		this.sensors = Sensors.list_sensors();
	}

	protected void fetch_temp() {
		if (sensor != null) {
			double temp = Sensors.fetch_temp(sensor.input_path);

			if (temp > 0.0) {
				this.temp = temp;
			}
		}
	}

	protected bool update_temp() {
		fetch_temp();

		var old_format = temp_label.get_label();
		var format = format_temp();

		if (old_format == format) {
			return true;
		}

		temp_label.set_markup(format);

		queue_draw();

		return true;
	}

	protected string format_temp() {
		var temp = this.temp;
		var fahrenheit = settings.get_boolean("fahrenheit");
		if (fahrenheit) {
			temp = temp * 1.8 + 32;
		}

		var show_sign = settings.get_boolean("show-sign");
		var sign = "";
		if (show_sign) {
			sign = fahrenheit ? "F" : "C";
		}

		var show_fraction = settings.get_boolean("show-fraction");

		string format;
		if (show_fraction) {
			format = "%.1f°%s".printf(temp, sign);
		}
		else {
			format = "%.0f°%s".printf(temp, sign);
		}

		if ( this.layout.orientation == Gtk.Orientation.VERTICAL ) {
			format = "<small>" + format + "</small>";
		}

		return format;
	}

	public override void panel_position_changed(
		Budgie.PanelPosition position
	) {
		if ( position == Budgie.PanelPosition.LEFT ||
			 position == Budgie.PanelPosition.RIGHT ) {
			layout.set_orientation(Gtk.Orientation.VERTICAL);
			layout.margin_start = 0;
			layout.margin_end = 0;
			layout.margin_top = 8;
			layout.margin_bottom = 8;
		}
		else {
			layout.set_orientation(Gtk.Orientation.HORIZONTAL);
			layout.margin_start = 8;
			layout.margin_end = 8;
			layout.margin_top = 0;
			layout.margin_bottom = 0;
		}

		this.panel_position = position;

		update_temp();
	}

	public override void update_popovers(Budgie.PopoverManager? manager) {
		this.manager = manager;
		manager.register_popover(widget, popover);
	}
}

[ModuleInit]
public void peas_register_types(TypeModule module) {
	// boilerplate - all modules need this
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(CpuTempPlugin));
}
