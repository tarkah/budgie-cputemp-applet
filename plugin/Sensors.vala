namespace Sensors {

    public class Sensor {
        private string name;
        private string label;
        public string input_path;

        public Sensor(string name, string label, string input_path) {
            this.name = name;
            this.label = label;
            this.input_path = input_path;
        }

        public string display_name() {
            if (this.label != "") {
                return this.name + " - " + this.label;
            }
            else {
                return this.name;
            }
        }
    }

    public double fetch_temp(string path) {
        FileStream stream = FileStream.open(path, "r");

        double temp = 0.0;
            
        if (stream != null) {
            uint8[] buf = new uint8[6];
            size_t read = stream.read(buf, 1);

            if (read == 6) {
                int parse = int.parse((string) buf);

                if (parse > 0) {
                    temp = (double) parse / 1000.0;
                }
            }
        }

        return temp;
    }


    public Sensor[] list_sensors() {
        Sensor[] sensors = {};

        string directory = "/sys/class/hwmon/";

        try {
            Dir dir = Dir.open (directory, 0);
            string? name = null;

            while ((name = dir.read_name ()) != null) {
                string path = Path.build_filename (directory, name);

                if (FileUtils.test (path, FileTest.IS_DIR)) {
                    var parsed_sensors = parse_sensors_from_directory(path);
                    
                    foreach (var sensor in parsed_sensors) {
                        sensors += sensor;
                    }
                }
            }
        } catch (FileError error) {
            
        }

        return sensors;
    }

    private Sensor[] parse_sensors_from_directory(string directory) {
        Sensor[] sensors = {};

        try {
            Dir dir = Dir.open(directory, 0);
            string? name = null;

            string sensor_name = get_file_contents(Path.build_filename(directory, "name"));

            if (sensor_name != "") {
                while ((name = dir.read_name ()) != null) {
                    if (name.has_prefix("temp") && name.has_suffix("input")) {
                        string label_path = Path.build_filename(directory, name.replace("input", "label") );
                        string input_path = Path.build_filename(directory, name);

                        string label = "";
                        if (FileUtils.test (label_path, FileTest.IS_REGULAR)) {
                            label = get_file_contents(label_path);
                        }

                        if (FileUtils.test (input_path, FileTest.IS_REGULAR)) {
                            Sensor sensor = new Sensor(sensor_name, label, input_path);
                            sensors += sensor;
                        }
                    }
                }
            }
        } catch (FileError error) {
            
        }

        return sensors;
    }

    private string get_file_contents(string path) {
        FileStream stream = FileStream.open(path, "r");

        string name = "";
            
        if (stream != null) {
            char buf[100];

            while (stream.gets(buf) != null) {
                name = name + (string) buf;
            }
        }

        name = name.replace("\n","");

        return name;
    }

}