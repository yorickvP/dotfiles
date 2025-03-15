#include <iostream>
#include <fstream>
#include <endian.h>

#include <simdjson.h>
#include <lz4.h>
using namespace simdjson;
// /home/yorick/.mozilla/firefox/sdgle03g.default/sessionstore-backups/recovery.jsonlz4
// jq '.windows | map(.tabs | length) | add'

padded_string read_mozlz4a_file(const std::string& file) {
  std::ifstream is(file, std::ifstream::binary);
  if (!is) {
    std::cerr << "error opening file" << std::endl;
    exit(1);
  }
  is.seekg(0, is.end);
  size_t insz = is.tellg();
  is.seekg(0, is.beg);
  char * buffer = new char[insz];
  is.read(buffer, insz);
  if (!is) {
    std::cerr << "error reading file" << std::endl;
    exit(1);
  }
  is.close();
  if (memcmp(buffer, "mozLz40", 8)) {
    std::cerr << "not a mozLZa file" << std::endl;
    exit(1);
  }
  size_t outsz = le32toh(*(uint32_t *) (buffer + 8));
  padded_string out(outsz);
  if (LZ4_decompress_safe_partial(buffer + 12, out.data(), insz - 12, outsz, outsz) < 0) {
    std::cerr << "decompression error" << std::endl;
    exit(1);
  }
  return out;
}

std::string get_default_firefox_profile_path() {
    std::string path = std::string(std::getenv("HOME")) + "/.mozilla/firefox/profiles.ini";
    std::ifstream file(path);
    if (file.is_open()) {
        std::string line;
        std::string profile_path;
        bool is_relative = true;
        bool in_profile_section = false;
        bool found_default = false;

        while (std::getline(file, line)) {
            // Start of a Profile section
            if (line.find("[Profile") == 0) {
                // If we already found the default profile in a previous section, we're done
                if (found_default) {
                    break;
                }

                // Reset for new profile section
                in_profile_section = true;
                profile_path = "";
                is_relative = true;
            }
            // Start of a non-Profile section
            else if (line[0] == '[' && line.find("[Profile") != 0) {
                in_profile_section = false;
            }

            // Only process these lines if we're in a Profile section
            if (in_profile_section) {
                // Path line
                if (line.find("Path=") == 0) {
                    profile_path = line.substr(5);
                }
                // IsRelative line
                else if (line.find("IsRelative=") == 0) {
                    is_relative = (line.substr(11) == "1");
                }
                // Default line - if this is the default profile, we've found what we need
                else if (line.find("Default=1") == 0) {
                    found_default = true;
                }
            }
        }

        file.close();

        // If we found the default profile, return its path
        if (found_default && !profile_path.empty()) {
            if (!is_relative) {
                return profile_path;
            }
            return std::string(std::getenv("HOME")) + "/.mozilla/firefox/" + profile_path;
        }
    }
    return "";
}

int main(int ac, char **av) {
    ondemand::parser parser;
    std::string path = get_default_firefox_profile_path();
    bool print_json = false;
    std::string json_file;

    // Check for --json flag
    for (int i = 1; i < ac; i++) {
        if (std::string(av[i]) == "--json") {
            print_json = true;
            if (i + 1 < ac) {
                json_file = av[i + 1];
            }
            break;
        }
    }

    if (ac < 2 && path.empty() && !print_json) {
        std::cerr << "Could not find default Firefox profile" << std::endl;
        std::cerr << "usage: " << av[0] << " .mozilla/firefox/*.default/sessionstore-backups/recovery.jsonlz4" << std::endl;
        exit(1);
    }

    if (print_json) {
        padded_string json = read_mozlz4a_file(json_file.empty() ? (ac > 2 ? av[2] : path + "/sessionstore-backups/recovery.jsonlz4") : json_file);
        std::cout << json << std::endl;
        exit(0);
    }

    padded_string json = read_mozlz4a_file(ac > 1 ? av[1] : path + "/sessionstore-backups/recovery.jsonlz4");
    ondemand::document session = parser.iterate(json);
    ondemand::array windows = session["windows"];
    size_t n = 0;
    for (auto i : windows) {
        ondemand::array tabs = i["tabs"];
        n += tabs.count_elements();
    }
    std::cout << n << std::endl;
}
